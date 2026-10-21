{ pkgs, ... }:
let
  routingFixture = pkgs.writeText "neomutt-routing-fixture.rc" (
    (import ./neomutt-routing.nix { inherit (pkgs) lib; }) {
      configDirectory = "$HOME/.config/neomutt";
      accounts = {
        account-a = {
          address = "account-a@example.invalid";
          aliases = [ ];
        };
        account-b = {
          address = "account-b@example.invalid";
          aliases = [ "alias+b@example.invalid" ];
        };
      };
    }
  );
  # The pinned Sphinx hook reads a scalar, so a list builds only HTML and
  # leaves khal's declared man output missing. Preserve both documentation outputs.
  calendarPackage = pkgs.khal.overrideAttrs { sphinxBuilders = "html man"; };
  # Share the wrapper with the dev shell so its PATH cannot shadow the
  # Home Manager package with a binary that rejects the hex-color theme.
  neomuttPackage = pkgs.symlinkJoin {
    name = "neomutt-truecolor";
    paths = [ pkgs.neomutt ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/neomutt --set TERM xterm-direct
    '';
  };
  picker = pkgs.writeShellApplication {
    name = "mail-attach-picker";
    runtimeInputs = [ pkgs.yazi ];
    text = ''
      export MAIL_PICKER_PLUGIN=${./attachment-picker.lua}
      exec ${pkgs.python3}/bin/python3 ${./attachment-picker.py} "$@"
    '';
  };
  index = pkgs.writeShellApplication {
    name = "mail-index";
    runtimeInputs = [
      pkgs.notmuch
      pkgs.coreutils
      pkgs.util-linux
    ];
    text = ''
      umask 077
      export NOTMUCH_CONFIG="''${NOTMUCH_CONFIG:-''${XDG_CONFIG_HOME:-$HOME/.config}/notmuch/default/config}"
      database=$(notmuch config get database.path)
      [ -d "$database" ] || exit 0
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/mail-index"
      mkdir -p "$state"
      exec flock -w 120 "$state/index.lock" notmuch new --quiet
    '';
  };
  calendarImport = pkgs.writeShellApplication {
    name = "mail-calendar-import";
    runtimeInputs = [ calendarPackage ];
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./calendar-import.py} "$@"
    '';
  };
  html = pkgs.writeShellApplication {
    name = "mail-html";
    text = ''
      export MAIL_HTML_FILTER=${pkgs.aerc}/libexec/aerc/filters/html
      export MAIL_HTML_LYNX=${pkgs.lynx}/bin/lynx
      # The aerc filter supplies w3m and socksify. Keep unshare out of PATH
      # so rendering also works in sandboxes without nested user namespaces.
      export MAIL_HTML_PATH=${pkgs.coreutils}/bin
      exec ${pkgs.python3}/bin/python3 ${./html.py} "$@"
    '';
  };
  check = pkgs.writeShellApplication {
    name = "check-mail-tools";
    runtimeInputs = [
      pkgs.python3
      pkgs.python3Packages.mypy
      tools
      neomuttPackage
      pkgs.notmuch
    ];
    text = ''
      work=$(mktemp -d)
      trap 'rm -rf "$work"' EXIT
      export HOME="$work/home"
      export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
      export XDG_STATE_HOME="$HOME/.local/state" XDG_CACHE_HOME="$HOME/.cache"
      mkdir -p "$HOME"
      export MAIL_SAVED_SEARCHES=${./searches.json}
      export MAIL_ROUTING_CONFIG=${routingFixture}
      mypy --cache-dir "$work/mypy" ${./attachment-picker.py}
      mypy --cache-dir "$work/mypy" ${./calendar-import.py}
      mypy --cache-dir "$work/mypy" ${./html.py}
      python3 -m unittest discover -s ${./tests} -v
    '';
  };
  tools = pkgs.symlinkJoin {
    name = "mail-tools";
    paths = [
      picker
      index
      calendarImport
      html
    ];
    passthru.calendar = calendarPackage;
    passthru.neomutt = neomuttPackage;
    passthru.check = check;
  };
in
tools
