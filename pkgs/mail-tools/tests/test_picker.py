"""Behavior at the attachment picker's selected-file output boundary."""

import json
import mailbox
import os
from pathlib import Path
import fcntl
import pty
import select
import shutil
import struct
import subprocess
import sys
import tempfile
import termios
import time
import unittest


class AttachmentPickerTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.chooser = self.root / "chooser"
        self.chooser.write_text(
            f"#!{sys.executable}\n"
            "import json, os, pathlib, sys\n"
            "target = os.environ['MAIL_PICKER_OUTPUT']\n"
            "files = json.loads(os.environ['TEST_PICKER_FILES'])\n"
            "if files:\n"
            "    pathlib.Path(target).write_bytes(b'\\0'.join(os.fsencode(f) for f in files) + b'\\0')\n"
        )
        self.chooser.chmod(0o700)

    def pick(self, files, *arguments):
        result = subprocess.run(
            ["mail-attach-picker", "--chooser", str(self.chooser), *arguments],
            env=dict(os.environ, TEST_PICKER_FILES=json.dumps([str(f) for f in files])),
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def test_multiple_files_preserve_spaces_and_order(self):
        files = [self.root / "first document.pdf", self.root / "second.csv"]
        for path in files:
            path.touch()
        self.assertEqual(self.pick(files).splitlines(), [str(f) for f in files])

    def test_cancellation_does_not_emit_attachment_commands(self):
        self.assertEqual(self.pick([], "--neomutt"), "")

    def test_control_character_filename_is_rejected_before_splitting(self):
        path = self.root / "unexpected\nattachment.txt"
        path.touch()
        result = subprocess.run(
            ["mail-attach-picker", "--chooser", str(self.chooser), "--neomutt"],
            env=dict(os.environ, TEST_PICKER_FILES=json.dumps([str(path)])),
            capture_output=True, text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")

    def test_neomutt_output_quotes_literal_filename_characters(self):
        path = self.root / 'a "quote" $value `command` <enter>.txt'
        path.touch()
        output = self.pick([path], "--neomutt")
        self.assertTrue(output.startswith('push "<attach-file>'), output)
        self.assertIn("<quote-char>", output)
        self.assertNotIn("`command`", output)
        self.assertNotIn("<enter>.txt", output)
        self.assertTrue(output.endswith('<enter>"\n'), output)

    def test_real_yazi_confirms_selection_through_nul_transport(self):
        directory = self.root / "selection"
        directory.mkdir()
        selected = directory / "selected document.txt"
        selected.write_text("Synthetic attachment")
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 140, 0, 0))

        def session():
            os.setsid()
            fcntl.ioctl(0, termios.TIOCSCTTY, 0)

        process = subprocess.Popen(
            ["mail-attach-picker", str(directory)], stdin=slave, stdout=subprocess.PIPE,
            stderr=slave, preexec_fn=session,
            env=dict(os.environ, TERM="xterm-256color", YAZI_CONFIG_HOME=str(self.root / "yazi")),
        )
        os.close(slave)
        screen = bytearray()
        try:
            for keys in (b"", b"\r"):
                os.write(master, keys)
                end = time.monotonic() + 1
                while time.monotonic() < end:
                    if not select.select([master], [], [], max(0, end - time.monotonic()))[0]:
                        break
                    try:
                        screen.extend(os.read(master, 65536))
                    except OSError:
                        break
            try:
                output, _ = process.communicate(timeout=5)
            except subprocess.TimeoutExpired:
                self.fail(repr(screen.decode(errors="replace")))
            self.assertEqual(process.returncode, 0, repr(screen.decode(errors="replace")))
            self.assertEqual(output.decode(), str(selected) + "\n")
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
            os.close(master)

    def test_selected_files_become_real_neomutt_attachments(self):
        files = [self.root / 'first document.pdf', self.root / 'a "quote" $value `command` <enter>.txt']
        for path in files:
            path.write_text("Synthetic attachment")
        draft = self.root / "draft.eml"
        draft.write_text("From: sender@example.invalid\nTo: recipient@example.invalid\n"
                         "Subject: Attachment fixture\n\nSynthetic body\n")
        postponed = self.root / "postponed"
        config = self.root / "neomuttrc"
        config.write_text(
            f'set folder="{self.root}"\nset postponed="{postponed}"\n'
            f'set editor="{shutil.which("true")}"\nset postpone=yes\nset wait_key=no\n'
            'set autoedit=yes\nset edit_headers=yes\n'
            'bind compose P postpone-message\n'
            f'macro compose A "<enter-command>source \\"{shutil.which("mail-attach-picker")} '
            f'--chooser {self.chooser} --neomutt |\\"<enter><refresh>"\n'
        )
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 140, 0, 0))

        def session():
            os.setsid()
            fcntl.ioctl(0, termios.TIOCSCTTY, 0)

        process = subprocess.Popen(
            ["neomutt", "-n", "-F", str(config), "-H", str(draft)],
            stdin=slave, stdout=slave, stderr=slave, preexec_fn=session,
            env=dict(os.environ, TERM="xterm-256color", TEST_PICKER_FILES=json.dumps([str(f) for f in files])),
        )
        os.close(slave)
        screen = bytearray()

        def drain(seconds):
            end = time.monotonic() + seconds
            while time.monotonic() < end:
                if not select.select([master], [], [], max(0, end - time.monotonic()))[0]:
                    break
                try:
                    screen.extend(os.read(master, 65536))
                except OSError:
                    break

        try:
            drain(0.5)
            os.write(master, b"A")
            drain(0.7)
            os.write(master, b"P")
            drain(0.5)
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.fail(screen.decode(errors="replace"))
            self.assertTrue(postponed.exists(), screen.decode(errors="replace"))
            messages = mailbox.mbox(postponed)
            self.addCleanup(messages.close)
            message = next(iter(messages))
            names = [part.get_filename() for part in message.walk() if part.get_filename()]
            self.assertEqual(names, [p.name for p in files], repr(screen.decode(errors="replace")))
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
            os.close(master)


if __name__ == "__main__":
    unittest.main()
