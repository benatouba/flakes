"""Search real synthetic Maildirs through the installed index command."""

from email.message import EmailMessage
import json
import fcntl
import mailbox
import os
from pathlib import Path
import pty
import select
import shutil
import struct
import subprocess
import tempfile
import termios
import time
import unittest


class MailSearchTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.mail = self.root / "mail"
        config = self.root / "notmuch.conf"
        config.write_text(
            f"[database]\npath={self.mail}\n[user]\nname=Fixture\n"
            "primary_email=fixture@example.invalid\n[new]\ntags=\n"
            "[maildir]\nsynchronize_flags=true\n"
            "[search]\nexclude_tags=deleted;spam\n"
        )
        self.env = dict(os.environ, HOME=str(self.root), XDG_STATE_HOME=str(self.root / "state"),
                        NOTMUCH_CONFIG=str(config))
        self.write_message("account-one/Inbox", "1", "", "quasar")
        self.write_message("account-two/Archive", "2", "S", "quasar")
        self.write_message("account-two/Inbox", "3", "FS", "Follow up")
        self.write_message("account-one/Sent", "4", "S", "Document", attachment=True)

    def write_message(self, folder, identifier, flags, subject, attachment=False,
                      recipient="fixture@example.invalid"):
        directory = self.mail / folder
        for sub in ("new", "cur", "tmp"):
            (directory / sub).mkdir(parents=True, exist_ok=True)
        message = EmailMessage()
        message["From"] = "sender@example.invalid"
        message["To"] = recipient
        message["Message-ID"] = f"<{identifier}@example.invalid>"
        message["Subject"] = subject
        message.set_content("Synthetic mail body")
        if attachment:
            message.add_attachment(b"Synthetic PDF", maintype="application", subtype="pdf", filename="sample.pdf")
        (directory / "cur" / f"{identifier}:2,{flags}").write_bytes(message.as_bytes())

    def command(self, *args):
        result = subprocess.run(args, env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.strip()

    def test_saved_searches_and_cross_account_search(self):
        self.command("mail-index")
        searches = json.loads(Path(os.environ["MAIL_SAVED_SEARCHES"]).read_text())
        expected = {"Unread": 1, "Flagged": 1, "Attachments": 1, "All mail": 4}
        for name, count in expected.items():
            with self.subTest(search=name):
                self.assertEqual(int(self.command("notmuch", "count", searches[name])), count)
        self.assertEqual(self.command("notmuch", "count", "subject:quasar"), "2")

    def test_neomutt_hex_colors_from_256color_terminal(self):
        rc = self.root / "colors.rc"
        rc.write_text(
            f'set folder="{self.mail}"\n'
            'set quit=yes\n'
            'set color_directcolor=yes\n'
            'color normal #cdd6f4 #1e1e2e\n'
            'push <quit>\n'
        )
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))

        def session():
            os.setsid()
            fcntl.ioctl(0, termios.TIOCSCTTY, 0)

        process = subprocess.Popen(
            ["neomutt", "-n", "-F", str(rc), "-f", str(self.mail / "account-one/Inbox")],
            stdin=slave, stdout=slave, stderr=slave, preexec_fn=session,
            env=dict(self.env, TERM="xterm-256color", COLORTERM="truecolor"),
        )
        os.close(slave)
        screen = bytearray()
        try:
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                if not select.select([master], [], [], 0.1)[0]:
                    continue
                try:
                    data = os.read(master, 65536)
                except OSError:
                    break
                if not data:
                    break
                screen.extend(data)
            self.assertNotIn(b"color not supported by term", screen)
            self.assertNotIn(b"source: errors", screen)
            self.assertEqual(process.wait(timeout=1), 0)
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
            os.close(master)

    def test_reply_from_search_selects_the_recipient_account(self):
        self.write_message("account-two/Inbox", "5", "S", "Cross-account reply",
                           recipient="alias+b@example.invalid")
        self.command("mail-index")
        configs = self.root / ".config/neomutt"
        configs.mkdir(parents=True)
        (configs / "account-b").write_text(
            'set from="Sender B <account-b@example.invalid>"\n'
            f'set record="{self.root}/Sent-B"\n'
        )
        postponed = self.root / "postponed"
        rc = self.root / "neomuttrc"
        rc.write_text(
            f'set folder="{self.root}"\nset postponed="{postponed}"\n'
            f'set editor="{shutil.which("true")}"\nset postpone=yes\nset wait_key=no\n'
            'set autoedit=yes\nset edit_headers=yes\nset reverse_name=yes\nset include=yes\nset abort_unmodified=no\n'
            'set from="account-a@example.invalid"\n'
            f'set record="{self.root}/Sent-A"\n'
            f'source "{os.environ["MAIL_ROUTING_CONFIG"]}"\n'
            'bind compose P postpone-message\n'
        )
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 140, 0, 0))

        def session():
            os.setsid()
            fcntl.ioctl(0, termios.TIOCSCTTY, 0)

        process = subprocess.Popen(
            ["neomutt", "-n", "-F", str(rc), "-f", f"notmuch://{self.mail}?query=id%3A5%40example.invalid"],
            stdin=slave, stdout=slave, stderr=slave, preexec_fn=session,
            env=dict(self.env, TERM="xterm-256color"),
        )
        os.close(slave)
        screen = bytearray()

        def drain():
            end = time.monotonic() + 0.5
            while time.monotonic() < end:
                if not select.select([master], [], [], max(0, end - time.monotonic()))[0]:
                    break
                try:
                    screen.extend(os.read(master, 65536))
                except OSError:
                    break

        try:
            for keys in (b"", b"r", b"P"):
                os.write(master, keys)
                drain()
            self.assertTrue(postponed.exists(), repr(screen.decode(errors="replace")))
            messages = mailbox.mbox(postponed)
            self.addCleanup(messages.close)
            message = next(iter(messages))
            self.assertIn("alias+b@example.invalid", message["From"])
            self.assertEqual(message["Mutt-Fcc"], "=Sent-B")
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
            os.close(master)


if __name__ == "__main__":
    unittest.main()
