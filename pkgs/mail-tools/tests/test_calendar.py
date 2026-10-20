"""Import synthetic invitations into a real temporary khal calendar."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


INVITATION = """BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Synthetic fixture//EN
METHOD:REQUEST
BEGIN:VEVENT
UID:fixture-meeting@example.invalid
DTSTAMP:20261020T120000Z
DTSTART:20261021T120000Z
DTEND:20261021T130000Z
SUMMARY:Synthetic meeting
END:VEVENT
END:VCALENDAR
"""


class CalendarImportTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.calendar = self.root / "state/calendars/local"
        config = self.root / "config/khal"
        config.mkdir(parents=True)
        (config / "config").write_text(
            f"[calendars]\n[[local]]\npath={self.calendar}\n"
            "[default]\ndefault_calendar=local\n"
            "[locale]\ntimeformat=%H:%M\ndateformat=%Y-%m-%d\n"
            "longdateformat=%Y-%m-%d\ndatetimeformat=%Y-%m-%d %H:%M\n"
            "longdatetimeformat=%Y-%m-%d %H:%M\n"
            "local_timezone=UTC\ndefault_timezone=UTC\n"
        )
        self.env = dict(os.environ, HOME=str(self.root), XDG_CONFIG_HOME=str(self.root / "config"),
                        XDG_STATE_HOME=str(self.root / "state"), XDG_DATA_HOME=str(self.root / "data"))

    def test_import_from_stdin_creates_a_local_event(self):
        result = subprocess.run(["mail-calendar-import", "--batch"], input=INVITATION,
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        files = list(self.calendar.glob("*.ics"))
        self.assertEqual(len(files), 1, result.stdout)
        self.assertIn("SUMMARY:Synthetic meeting", files[0].read_text())
        self.assertEqual(files[0].stat().st_mode & 0o077, 0)


if __name__ == "__main__":
    unittest.main()
