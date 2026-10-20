"""Render HTML mail locally, with a comparison mode for choosing a renderer."""

import argparse
import os
from pathlib import Path
import subprocess
import sys


def render(data: bytes, renderer: str, charset: str) -> bytes:
    env = dict(os.environ, PATH=os.environ["MAIL_HTML_PATH"])
    if renderer == "lynx":
        command = [os.environ["MAIL_HTML_LYNX"], "-stdin", "-dump", "-force_html",
                   "-localhost", "-noredir", "-nolist", "-nonumbers", "-nomargins",
                   "-width=100", f"-assume_charset={charset}", "-display_charset=UTF-8"]
    else:
        # Both variants use aerc's network-blocking wrapper around w3m.
        command = [os.environ["MAIL_HTML_FILTER"], "-I", charset]
        if renderer == "w3m":
            command += ["-o", "display_link=false", "-o", "display_borders=true"]
    result = subprocess.run(command, input=data, capture_output=True, env=env, check=True)
    return result.stdout


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--renderer", choices=("lynx", "w3m", "aerc"), default="w3m")
    parser.add_argument("--compare", action="store_true", help="Show all three local text renderings")
    parser.add_argument("--charset", default="UTF-8")
    parser.add_argument("file", nargs="?", help="Local HTML file; otherwise read stdin")
    args = parser.parse_args()
    data = Path(args.file).read_bytes() if args.file else sys.stdin.buffer.read()
    try:
        if args.compare:
            for renderer in ("lynx", "w3m", "aerc"):
                sys.stdout.buffer.write(f"=== {renderer} ===\n".encode())
                sys.stdout.buffer.write(render(data, renderer, args.charset or "UTF-8") + b"\n")
        else:
            sys.stdout.buffer.write(render(data, args.renderer, args.charset or "UTF-8"))
    except subprocess.CalledProcessError as error:
        sys.stderr.buffer.write(error.stderr)
        return error.returncode
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
