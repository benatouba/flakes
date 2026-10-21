"""Select files for mail clients with Yazi."""

import argparse
import contextlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def neomutt_commands(paths: list[str]) -> str:
    # Quote each input character so filenames cannot become NeoMutt functions
    # (e.g. a literal <enter>). The filename prompt accepts spaces literally.
    keys = "".join(
        "<attach-file>"
        + "".join("<quote-char>" + char for char in path)
        + "<enter>"
        for path in paths
    )
    for char in ("\\", '"', "$", "`"):
        keys = keys.replace(char, "\\" + char)
    return f'push "{keys}"\n' if paths else ""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--chooser", default="yazi", help="Yazi executable")
    parser.add_argument("--neomutt", action="store_true", help="Emit commands for NeoMutt source")
    parser.add_argument("directory", nargs="?", default=str(Path.home() / "documents"))
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="mail-attach-") as temporary, contextlib.ExitStack() as stack:
        chosen = Path(temporary) / "selected"
        config = Path(temporary) / "config"
        plugin = config / "plugins/mail-picker.yazi"
        plugin.mkdir(parents=True)
        (plugin / "main.lua").symlink_to(os.environ["MAIL_PICKER_PLUGIN"])
        # Keep appearance/settings, but use a dedicated picker keymap. NUL
        # transport avoids the ambiguity of Yazi's newline-based chooser file.
        original = Path(os.environ.get("YAZI_CONFIG_HOME", str(Path(os.environ.get(
            "XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "yazi")))
        for name in ("yazi.toml", "theme.toml"):
            if (original / name).is_file():
                shutil.copyfile(original / name, config / name)
        (config / "keymap.toml").write_text(
            '[mgr]\nprepend_keymap = [{ on = "<Enter>", run = "plugin mail-picker", desc = "Attach selected files" }]\n'
        )
        try:
            terminal = stack.enter_context(open("/dev/tty", "r+b", buffering=0))
        except OSError:
            terminal = None
        result = subprocess.run(
            [args.chooser, args.directory],
            stdin=terminal, stdout=terminal or sys.stderr, stderr=terminal,
            env=dict(os.environ, YAZI_CONFIG_HOME=str(config), MAIL_PICKER_OUTPUT=str(chosen)),
            check=False,
        )
        if result.returncode:
            return result.returncode
        if not chosen.exists():
            return 0
        paths = []
        for selection in chosen.read_bytes().rstrip(b"\0").split(b"\0"):
            path = Path(os.fsdecode(selection)).resolve()
            if not path.is_file() or any(ord(char) < 32 for char in str(path)):
                print("Selection must be a regular file with a single-line filename", file=sys.stderr)
                return 1
            paths.append(str(path))
        sys.stdout.write(neomutt_commands(paths) if args.neomutt else "".join(p + "\n" for p in paths))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
