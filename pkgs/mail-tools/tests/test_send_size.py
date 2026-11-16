"""Reject oversized wire messages before invoking the real queue command."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = os.environ.get(
    "MAIL_SIZE_CHECK_SCRIPT", str(Path(__file__).resolve().parents[1] / "send-size.py")
)
SINK = """
import json, pathlib, sys
pathlib.Path(sys.argv[1]).write_bytes(sys.stdin.buffer.read())
pathlib.Path(sys.argv[1] + '.args').write_text(json.dumps(sys.argv[3:]))
sys.exit(int(sys.argv[2]))
"""


class SendSizeTest(unittest.TestCase):
    def run_guard(self, message, limit, status=0):
        with tempfile.TemporaryDirectory() as work:
            target = Path(work) / "queued"
            arguments = ["--account=example", "--", "recipient@example.invalid"]
            result = subprocess.run(
                [
                    sys.executable, SCRIPT, "--max-bytes", str(limit), "--",
                    sys.executable, "-c", SINK, str(target), str(status), *arguments,
                ],
                input=message, capture_output=True,
            )
            if target.exists():
                self.assertEqual(target.read_bytes(), message)
                self.assertEqual(json.loads(Path(str(target) + ".args").read_text()), arguments)
            return result, target.exists()

    def test_lf_expansion_blocks_message_smaller_than_limit_on_disk(self):
        result, queued = self.run_guard(b"private\n" * 10, 85)
        self.assertEqual(result.returncode, 65)
        self.assertFalse(queued)
        self.assertIn(b"90 bytes", result.stderr)
        self.assertIn(b"5 bytes", result.stderr)
        self.assertNotIn(b"private", result.stderr)

    def test_exact_limit_allowed_and_payload_and_arguments_unchanged(self):
        result, queued = self.run_guard(b"header\n\nbody\n", 16)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(queued)

    def test_crlf_not_counted_twice(self):
        result, queued = self.run_guard(b"a\r\nb\n", 6)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(queued)

    def test_missing_final_newline_counts_smtp_crlf(self):
        result, queued = self.run_guard(b"abc", 4)
        self.assertEqual(result.returncode, 65)
        self.assertFalse(queued)

    def test_crlf_across_read_boundary(self):
        message = b"x" * (64 * 1024 - 1) + b"\r\n"
        result, queued = self.run_guard(message, len(message))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(queued)

    def test_queue_failure_propagates(self):
        result, queued = self.run_guard(b"a\n", 100, status=75)
        self.assertEqual(result.returncode, 75)
        self.assertTrue(queued)

    def test_invalid_limit_never_invokes_queue(self):
        result, queued = self.run_guard(b"a\n", 0)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(queued)

    def test_neomutt_reports_rejection_without_invoking_queue(self):
        with tempfile.TemporaryDirectory() as work:
            root = Path(work)
            target = root / "queued"
            sink = root / "sink.py"
            sink.write_text(
                "import pathlib, sys\n"
                "pathlib.Path(sys.argv[1]).write_bytes(sys.stdin.buffer.read())\n"
            )
            command = (
                f"{sys.executable} {SCRIPT} --max-bytes 20 -- "
                f"{sys.executable} {sink} {target}"
            )
            rc = root / "neomuttrc"
            rc.write_text(
                f'set sendmail="{command}"\nset sendmail_wait=0\n'
                'set copy=no\nset from=sender@example.invalid\n'
            )
            result = subprocess.run(
                ["neomutt", "-n", "-F", str(rc), "-s", "Size test",
                 "recipient@example.invalid"],
                input=b"Synthetic mail body\n", capture_output=True,
                env=dict(os.environ, HOME=work),
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(b"Message not sent: SMTP size", result.stderr)
            self.assertIn(b"Nothing was queued", result.stderr)
            self.assertFalse(target.exists())


if __name__ == "__main__":
    unittest.main()
