"""Import an explicitly selected invitation into the local khal calendar."""

import argparse
import contextlib
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--batch", action="store_true", help="Import without prompts, including updates")
    parser.add_argument("file", nargs="?", help="ICS file; otherwise read the selected attachment from stdin")
    args = parser.parse_args()
    data = Path(args.file).read_bytes() if args.file else sys.stdin.buffer.read()
    if b"BEGIN:VCALENDAR" not in data or b"BEGIN:VEVENT" not in data:
        print("Select an ICS event attachment before importing", file=sys.stderr)
        return 1
    os.umask(0o077)
    state = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state")))
    (state / "calendars/local").mkdir(mode=0o700, parents=True, exist_ok=True)
    config = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "khal/config"
    with tempfile.TemporaryDirectory(prefix="mail-invitation-") as temporary, contextlib.ExitStack() as stack:
        invitation = Path(temporary) / "invitation.ics"
        invitation.write_bytes(data)
        terminal = None
        if not args.file and not args.batch:
            try:
                terminal = stack.enter_context(open("/dev/tty", "r+b", buffering=0))
            except OSError:
                print("Interactive import needs a terminal; use --batch only for intentional unattended updates", file=sys.stderr)
                return 1
        command = ["khal", "-c", str(config), "import", "-a", "local"]
        if args.batch:
            command.append("--batch")
        return subprocess.run(command + [str(invitation)], stdin=terminal, check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
