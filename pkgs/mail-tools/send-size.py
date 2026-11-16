"""Check SMTP message size before handing an unchanged message to a queue."""

import argparse
import subprocess
import sys
import tempfile
from typing import BinaryIO


def spool_message(source: BinaryIO, target: BinaryIO) -> int:
    """Count CRLF-normalized octets, excluding SMTP dot stuffing (RFC 1870)."""
    size = 0
    previous = b""
    while chunk := source.read(64 * 1024):
        target.write(chunk)
        size += len(chunk) + chunk.count(b"\n") - chunk.count(b"\r\n")
        if previous == b"\r" and chunk.startswith(b"\n"):
            size -= 1
        previous = chunk[-1:]
    if previous and previous != b"\n":
        size += 2
    target.seek(0)
    return size


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--max-bytes", type=int, required=True)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command
    if command and command[0] == "--":
        command = command[1:]
    if args.max_bytes <= 0 or not command:
        parser.error("a positive --max-bytes and a command after -- are required")

    try:
        # Unlinked, owner-only spool; never persist message contents or log headers.
        with tempfile.TemporaryFile() as message:
            size = spool_message(sys.stdin.buffer, message)
            if size > args.max_bytes:
                print(
                    f"Message not sent: SMTP size {size:,} bytes exceeds the "
                    f"server limit of {args.max_bytes:,} bytes "
                    f"by {size - args.max_bytes:,} bytes. "
                    "Reduce attachments or use an approved file-sharing link. "
                    "Nothing was queued.",
                    file=sys.stderr,
                )
                return 65
            return subprocess.run(command, stdin=message, check=False).returncode
    except OSError:
        print("Send-size check or queue command failed; check the queue before retrying.", file=sys.stderr)
        return 74


if __name__ == "__main__":
    sys.exit(main())
