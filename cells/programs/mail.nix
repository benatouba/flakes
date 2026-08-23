{
  config,
  inputs,
  lib,
  ...
}:
let
  theme = config.my.theme;
  c = theme.colors;
  secretsRoot = toString inputs.nix-secrets;
  mailAccountsPath = "${secretsRoot}/mail-accounts.nix";
  sopsFile = "${secretsRoot}/secrets.yaml";
  outlookClientIdSecret = "mail_outlook_client_id";

  # Same probe as cells/shell/railway.nix: sops leaves mapping keys in plaintext,
  # so the key can be checked without decrypting. Outlook cannot authenticate at
  # all without OAuth2, so the whole account is gated on the client id being
  # present rather than hard-failing activation until it is added.
  hasOutlookClientId =
    builtins.pathExists sopsFile
    && lib.hasInfix "${outlookClientIdSecret}:" (builtins.readFile sopsFile);
in
{

  config.my.branches.personal.hmModules = [
    (
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        hasMailAccounts = builtins.pathExists mailAccountsPath;
        accts = if hasMailAccounts then import mailAccountsPath else { };
        a = accts;
        tuBerlinMaildir = "tu-berlin-new";
        outlookMaildir = "outlook";

        # Outlook.com reports *localized* IMAP folder names. These are the German
        # names a live.de mailbox uses, consistent with the alganize account below.
        # mbsync syncs with `Patterns *`, so the sync works whatever they are named
        # — after the first sync, check `ls ~/mail/outlook` and correct these here
        # if the server returned English names (Sent/Drafts/Deleted/Junk/Archive).
        outlookFolders = {
          sent = "Gesendete Elemente";
          drafts = "Entwürfe";
          trash = "Gelöschte Elemente";
          junk = "Junk-E-Mail";
          archive = "Archiv";
        };
        outlookMailboxes = [
          outlookFolders.sent
          outlookFolders.drafts
          outlookFolders.trash
          outlookFolders.junk
          outlookFolders.archive
        ];

        urlEncode = builtins.replaceStrings [ "@" "\\" ] [ "%40" "%5C" ];
        secret = name: config.sops.secrets."mail_${name}".path;
        catSecret = name: "${pkgs.coreutils}/bin/cat ${secret name}";

        # Google presents app passwords as "xxxx xxxx xxxx xxxx", but the IMAP and
        # SMTP servers expect the 16 characters with no spaces — pasted verbatim, the
        # login just fails. This strips whitespace so the secret works either way.
        #
        # It has to be a script rather than a `cat ... | tr` pipeline: a string
        # passwordCommand is split on spaces, and home-manager shell-escapes every
        # element when generating imapnotify's config, which would turn the pipe into
        # a literal argument. A single store path survives that intact.
        catSecretUnspaced =
          name:
          pkgs.writeShellScript "mail-secret-${name}" ''
            exec ${pkgs.coreutils}/bin/tr -d '[:space:]' < ${secret name}
          '';

        # nixpkgs builds isync without the XOAUTH2 SASL plugin by default, which
        # makes OAuth2 IMAP impossible. The override wraps mbsync with a SASL_PATH
        # that includes cyrus-sasl-xoauth2. Required for Outlook.
        isyncPackage = pkgs.isync.override { withCyrusSaslXoauth2 = true; };

        # Microsoft issues a *new* refresh token on every refresh, so the token
        # cannot live in sops: a git-tracked, build-time-encrypted file is not
        # something a background sync can rewrite. oama keeps the rotating refresh
        # token in gnome-keyring and mints short-lived access tokens on demand.
        # Only the non-rotating client id comes from sops.
        oamaAccess = email: "${pkgs.oama}/bin/oama access ${lib.escapeShellArg email}";

        mbsyncLockFile = "${config.xdg.cacheHome}/mbsync.lock";
        mbsyncPackage = pkgs.writeShellScriptBin "mbsync" ''
          exec ${pkgs.util-linux}/bin/flock -w 180 ${lib.escapeShellArg mbsyncLockFile} ${isyncPackage}/bin/mbsync "$@"
        '';
        notifyCmd =
          account:
          "${pkgs.libnotify}/bin/notify-send -a 'Mail' -i mail-unread '${account}' 'New mail received'";
        syncAndNotifyCmd =
          channel: account:
          "${mbsyncPackage}/bin/mbsync --pull-new --quiet ${lib.escapeShellArg "${channel}:INBOX"} && ${notifyCmd account}";
        queryAddresses = pkgs.writeShellScript "query-addresses" ''
          query="$1"
          [ -z "$query" ] && exit 1

          tsv="''${XDG_CACHE_HOME:-$HOME/.cache}/maildir-rank-addr/addressbook.tsv"

          # Search local history across all accounts (TSV is pre-sorted by rank)
          all=""
          if [ -f "$tsv" ]; then
            all=$(${pkgs.gawk}/bin/awk -F'\t' -v q="''${query}" '
              tolower($1) ~ tolower(q) || tolower($2) ~ tolower(q) { print $1 "\t" $2 }
            ' "$tsv")
          fi

          count=$(echo "$all" | ${pkgs.gawk}/bin/awk 'NF' | wc -l)
          echo "$count addresses found for ''${query}"
          echo "$all" | ${pkgs.gawk}/bin/awk 'NF'
        '';
      in
      {
        assertions = [
          {
            assertion = hasMailAccounts;
            message = "The personal branch requires ${mailAccountsPath} to exist.";
          }
        ];

        warnings = lib.optional (hasMailAccounts && !hasOutlookClientId) ''
          Mail: `${outlookClientIdSecret}` is missing from ${sopsFile}, so the
          outlook (${a.outlook.address}) account is disabled. Outlook.com retired
          basic auth for personal accounts on 2024-09-16, so it needs an OAuth2
          client id from an Azure app registration. Add it with:
            sops ~/.local/secrets/secrets.yaml   # ${outlookClientIdSecret}: <client-id>
            just update-secrets
          then rebuild and run:
            oama authorize microsoft ${a.outlook.address} --device
        '';
      }
      // lib.optionalAttrs hasMailAccounts {
        services.imapnotify.enable = true;
        sops = {
          secrets = {
            mail_tu_berlin = { };
            mail_gmail = { };
            mail_alganize = { };
          }
          // lib.optionalAttrs hasOutlookClientId {
            ${outlookClientIdSecret} = { };
          };
        };

        xdg.configFile."oama/config.yaml" = lib.mkIf hasOutlookClientId {
          text = ''
            # Generated by Home Manager. Rotating tokens live in gnome-keyring,
            # which PAM unlocks at login so the mbsync timer refreshes unattended.
            encryption:
                tag: KEYRING

            services:
              microsoft:
                client_id_cmd: |
                  ${pkgs.coreutils}/bin/cat ${config.sops.secrets.${outlookClientIdSecret}.path}
                auth_endpoint: https://login.microsoftonline.com/common/oauth2/v2.0/devicecode
                auth_scope: https://outlook.office.com/IMAP.AccessAsUser.All https://outlook.office.com/SMTP.Send offline_access
                tenant: common
          '';
        };

        programs = {
          neomutt = {
            enable = true;
            package = pkgs.symlinkJoin {
              name = "neomutt-truecolor";
              paths = [ pkgs.neomutt ];
              nativeBuildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                wrapProgram $out/bin/neomutt --set TERM xterm-direct
              '';
            };
            vimKeys = true;
            sort = "reverse-date";
            sidebar = {
              enable = true;
              width = 30;
            };
            settings = {
              mail_check_stats = "yes";
              mailcap_path = "${config.xdg.configHome}/neomutt/mailcap";
              color_directcolor = "yes";
              attach_save_dir = "~/downloads";
              query_command = "\"${queryAddresses} '%s'\"";
              use_threads = "threads";
            };
            extraConfig = ''
              # Theme: ${theme.slug}
              color normal        #${c.text}     #${c.base}
              color error         #${c.red}      #${c.base}
              color indicator     #${c.text}     #${c.surface0}
              color status        #${c.text}     #${c.mantle}
              color tree          #${c.blue}     #${c.base}
              color signature     #${c.overlay0} #${c.base}
              color message       #${c.text}     #${c.base}
              color attachment    #${c.peach}    #${c.base}
              color search        #${c.base}     #${c.mauve}
              color tilde         #${c.overlay0} #${c.base}
              color markers       #${c.overlay0} #${c.base}

              # Index
              color index         #${c.subtext0} #${c.base}  "~R"
              color index         #${c.text}     #${c.base}  "~U"
              color index         #${c.peach}    #${c.base}  "~F"
              color index         #${c.red}      #${c.base}  "~D"
              color index         #${c.mauve}    #${c.base}  "~T"

              # Header
              color hdrdefault    #${c.blue}     #${c.base}
              color header        #${c.mauve}    #${c.base}  "^(From|To|Cc|Bcc):"
              color header        #${c.blue}     #${c.base}  "^Subject:"
              color header        #${c.overlay0} #${c.base}  "^Date:"

              # Body
              color quoted        #${c.blue}     #${c.base}
              color quoted1       #${c.teal}     #${c.base}
              color quoted2       #${c.green}    #${c.base}
              color quoted3       #${c.peach}    #${c.base}
              color bold          #${c.text}     #${c.base}
              color underline     #${c.text}     #${c.base}

              # URL and email
              color body          #${c.blue}     #${c.base}  "(https?|ftp)://[^ ]+"
              color body          #${c.mauve}    #${c.base}  "[-a-z_0-9.]+@[-a-z_0-9.]+"

              # Sidebar
              color sidebar_new       #${c.blue}     #${c.base}
              color sidebar_highlight #${c.text}     #${c.surface0}
              color sidebar_indicator #${c.mauve}    #${c.base}
              color sidebar_ordinary  #${c.subtext0} #${c.base}
              color sidebar_divider   #${c.surface1} #${c.base}

              # Compose
              color compose header            #${c.text}  #${c.base}
              color compose security_encrypt  #${c.green} #${c.base}
              color compose security_sign     #${c.blue}  #${c.base}
              color compose security_both     #${c.green} #${c.base}
              color compose security_none     #${c.red}   #${c.base}
            '';
            binds = [
              {
                map = [
                  "index"
                  "pager"
                ];
                key = "\\Ck";
                action = "sidebar-prev";
              }
              {
                map = [
                  "index"
                  "pager"
                ];
                key = "\\Cj";
                action = "sidebar-next";
              }
              {
                map = [
                  "index"
                  "pager"
                ];
                key = "\\Co";
                action = "sidebar-open";
              }
              {
                map = [
                  "index"
                  "pager"
                ];
                key = "B";
                action = "sidebar-toggle-visible";
              }
              {
                map = [ "index" ];
                key = "l";
                action = "display-message";
              }
              {
                map = [ "index" ];
                key = "u";
                action = "undelete-message";
              }
              {
                map = [ "index" ];
                key = "r";
                action = "reply";
              }
              {
                map = [ "index" ];
                key = "R";
                action = "group-reply";
              }
              {
                map = [ "index" ];
                key = "f";
                action = "forward-message";
              }
              {
                map = [ "index" ];
                key = "c";
                action = "mail";
              }
              {
                map = [ "index" ];
                key = "/";
                action = "search";
              }
              {
                map = [ "index" ];
                key = "x";
                action = "sync-mailbox";
              }
              {
                map = [ "index" ];
                key = "s";
                action = "save-message";
              }
              {
                map = [ "index" ];
                key = "t";
                action = "tag-entry";
              }
              {
                map = [ "pager" ];
                key = "h";
                action = "exit";
              }
              {
                map = [ "pager" ];
                key = "l";
                action = "view-attachments";
              }
              {
                map = [ "pager" ];
                key = "r";
                action = "reply";
              }
              {
                map = [ "pager" ];
                key = "R";
                action = "group-reply";
              }
              {
                map = [ "pager" ];
                key = "f";
                action = "forward-message";
              }
              {
                map = [ "pager" ];
                key = "u";
                action = "undelete-message";
              }
              {
                map = [ "pager" ];
                key = "/";
                action = "search";
              }
              {
                map = [ "attach" ];
                key = "l";
                action = "view-mailcap";
              }
              {
                map = [ "attach" ];
                key = "h";
                action = "exit";
              }
              {
                map = [ "compose" ];
                key = "l";
                action = "view-attach";
              }
              {
                map = [ "compose" ];
                key = "h";
                action = "exit";
              }
              {
                map = [ "editor" ];
                key = "\\t";
                action = "complete-query";
              }
            ];
            macros = [
              {
                map = [ "index" ];
                key = "O";
                action = "<shell-escape>mbsync -a<enter>";
              }
              {
                map = [ "index" ];
                key = "gi";
                action = "<change-folder>~/mail/${tuBerlinMaildir}/Inbox<enter>";
              }
              {
                map = [ "index" ];
                key = "gm";
                action = "<change-folder>~/mail/gmail/Inbox<enter>";
              }
              {
                map = [ "index" ];
                key = "ga";
                action = "<change-folder>~/mail/alganize/Inbox<enter>";
              }
              {
                map = [
                  "pager"
                  "index"
                ];
                key = "U";
                action = "<pipe-message>${pkgs.urlscan}/bin/urlscan<enter>";
              }
              {
                map = [ "index" ];
                key = "M";
                action = "<tag-pattern>~U<enter><tag-prefix-cond><clear-flag>N<untag-pattern>.<enter>";
              }
            ]
            ++ lib.optional hasOutlookClientId {
              map = [ "index" ];
              key = "go";
              action = "<change-folder>~/mail/${outlookMaildir}/Inbox<enter>";
            };
          };

          mbsync = {
            enable = true;
            package = mbsyncPackage;
          };
          msmtp.enable = true;

          aerc = {
            enable = true;
            extraConfig = {
              general = {
                unsafe-accounts-conf = true;
                default-save-path = "~/downloads";
              };
              ui = {
                index-columns = "date<20,name<25,flags>4,subject<*";
                column-date = "2006-01-02 15:04";
                sidebar-width = 25;
                mouse-enabled = true;
                threading-enabled = true;
                styleset-name = theme.slug;
                fuzzy-complete = true;
                this-day-time-format = "15:04";
                this-year-time-format = "Jan 02";
                timestamp-format = "2006-01-02";
              };
              viewer = {
                pager = "less -R";
                alternatives = "text/plain,text/html";
              };
              compose = {
                editor = "nvim";
                header-layout = "To|From,Subject";
                reply-to-self = false;
                address-book-cmd = "${queryAddresses} '%s'";
              };
              filters = {
                "text/plain" = "colorize";
                "text/html" = "html | colorize";
                "text/calendar" = "calendar";
                "message/delivery-status" = "colorize";
                "message/rfc822" = "colorize";
              };
            };
            extraBinds = {
              global = {
                "<C-p>" = ":prev-tab<Enter>";
                "<C-n>" = ":next-tab<Enter>";
                "<C-t>" = ":term<Enter>";
                "?" = ":help keys<Enter>";
              };
              messages = {
                q = ":quit<Enter>";
                j = ":next<Enter>";
                k = ":prev<Enter>";
                "<C-d>" = ":next 50%<Enter>";
                "<C-u>" = ":prev 50%<Enter>";
                "<C-f>" = ":next 100%<Enter>";
                "<C-b>" = ":prev 100%<Enter>";
                g = ":select 0<Enter>";
                G = ":select -1<Enter>";
                l = ":view<Enter>";
                h = ":cf ..<Enter>";
                "<Enter>" = ":view<Enter>";
                d = ":move Trash<Enter>";
                D = ":delete<Enter>";
                A = ":archive flat<Enter>";
                c = ":compose<Enter>";
                m = ":mark -t<Enter>";
                M = ":unmark -a<Enter>";
                r = ":reply<Enter>";
                R = ":reply -a<Enter>";
                f = ":forward<Enter>";
                "/" = ":search<Enter>";
                n = ":next-result<Enter>";
                N = ":prev-result<Enter>";
                u = ":unread<Enter>";
                s = ":sort<space>";
                t = ":toggle-threads<Enter>";
                O = ":check-mail<Enter>";
                v = ":mark -v<Enter>";
                gi = ":cf ${tuBerlinMaildir}/INBOX<Enter>";
                gm = ":cf gmail/INBOX<Enter>";
                ga = ":cf alganize/INBOX<Enter>";
              }
              // lib.optionalAttrs hasOutlookClientId {
                go = ":cf ${outlookMaildir}/INBOX<Enter>";
              };
              "messages:folder=Trash" = {
                d = ":delete<Enter>";
              };
              view = {
                q = ":close<Enter>";
                h = ":close<Enter>";
                l = ":open<Enter>";
                j = ":next<Enter>";
                k = ":prev<Enter>";
                "<C-d>" = ":next 50%<Enter>";
                "<C-u>" = ":prev 50%<Enter>";
                "<C-f>" = ":next 100%<Enter>";
                "<C-b>" = ":prev 100%<Enter>";
                g = ":toggle-key-passthrough<Enter>";
                J = ":next-part<Enter>";
                K = ":prev-part<Enter>";
                r = ":reply<Enter>";
                R = ":reply -a<Enter>";
                f = ":forward<Enter>";
                d = ":move Trash<Enter>";
                D = ":delete<Enter>";
                A = ":archive flat<Enter>";
                "|" = ":pipe<space>";
                S = ":save<space>";
                o = ":open<Enter>";
              };
              "view::passthrough" = {
                g = ":toggle-key-passthrough<Enter>";
              };
              compose = {
                "<C-q>" = ":abort<Enter>";
                "<C-s>" = ":send<Enter>";
                "<C-a>" = ":attach<space>";
                "<C-j>" = ":next-field<Enter>";
                "<C-k>" = ":prev-field<Enter>";
                "<C-l>" = ":switch-account<space>";
                "<Tab>" = ":next-field<Enter>";
                "<S-Tab>" = ":prev-field<Enter>";
              };
              "compose::editor" = {
                "<C-q>" = ":abort<Enter>";
                "<C-s>" = ":send<Enter>";
                "<C-a>" = ":attach<space>";
              };
              "compose::review" = {
                q = ":abort<Enter>";
                y = ":send<Enter>";
                a = ":attach<space>";
                d = ":detach<space>";
                e = ":edit<Enter>";
                j = ":next-field<Enter>";
                k = ":prev-field<Enter>";
                l = ":open<Enter>";
                h = ":prev-tab<Enter>";
              };
              terminal = {
                "<C-q>" = ":close<Enter>";
              };
            };
          };
        };

        services.mbsync = {
          enable = true;
          package = mbsyncPackage;
          frequency = "*:0/5";
          postExec = "${pkgs.maildir-rank-addr}/bin/maildir-rank-addr";
        };

        xdg.configFile."maildir-rank-addr/config.toml".text =
          let
            home = config.home.homeDirectory;
            toTomlList = xs: "[${lib.concatMapStringsSep ", " (x: ''"${x}"'') xs}]";
            addresses = [
              a.tu-berlin.address
            ]
            ++ a.tu-berlin.aliases
            ++ [
              a.gmail.address
              a.alganize.address
            ]
            ++ lib.optional hasOutlookClientId a.outlook.address;
            maildirs = [
              "${home}/mail/${tuBerlinMaildir}"
              "${home}/mail/gmail"
              "${home}/mail/alganize"
            ]
            ++ lib.optional hasOutlookClientId "${home}/mail/${outlookMaildir}";
          in
          ''
            maildir = ${toTomlList maildirs}
            addresses = ${toTomlList addresses}
          '';

        xdg.configFile."aerc/stylesets/${theme.slug}".text = ''
          *.default=true
          *.normal=true
          default.fg=#${c.text}
          default.bg=#${c.base}
          error.fg=#${c.red}
          error.bold=true
          warning.fg=#${c.peach}
          success.fg=#${c.green}
          title.fg=#${c.mauve}
          title.bold=true
          header.fg=#${c.blue}
          header.bold=true
          statusline_default.fg=#${c.text}
          statusline_default.bg=#${c.mantle}
          statusline_error.fg=#${c.red}
          statusline_error.bg=#${c.mantle}
          statusline_success.fg=#${c.green}
          statusline_success.bg=#${c.mantle}
          msglist_default.fg=#${c.subtext0}
          msglist_unread.fg=#${c.text}
          msglist_unread.bold=true
          msglist_read.fg=#${c.subtext0}
          msglist_flagged.fg=#${c.peach}
          msglist_deleted.fg=#${c.overlay0}
          msglist_marked.fg=#${c.mauve}
          msglist_marked.reverse=true
          dirlist_default.fg=#${c.subtext1}
          dirlist_recent.fg=#${c.blue}
          dirlist_recent.bold=true
          completion_default.fg=#${c.text}
          completion_default.bg=#${c.surface0}
          completion_pill.fg=#${c.base}
          completion_pill.bg=#${c.mauve}
          tab.fg=#${c.subtext0}
          tab.bg=#${c.mantle}
          tab.selected.fg=#${c.text}
          tab.selected.bg=#${c.surface0}
          tab.selected.bold=true
          selector_default.fg=#${c.text}
          selector_focused.fg=#${c.mauve}
          selector_focused.bold=true
          selector_chooser.fg=#${c.blue}
          border.fg=#${c.surface1}
        '';

        xdg.configFile."neomutt/mailcap".text = ''
          text/html; xdg-open %s ; nametemplate=%s.html
          text/html; lynx -assume_charset=%{charset} -display_charset=utf-8 -dump %s; nametemplate=%s.html; copiousoutput
          application/pdf; xdg-open %s
          image/*; xdg-open %s
          application/msword; xdg-open %s
          application/vnd.openxmlformats-officedocument.*; xdg-open %s
          application/vnd.ms-excel; xdg-open %s
          application/vnd.oasis.opendocument.*; xdg-open %s
        '';

        home.packages =
          with pkgs;
          [
            lynx
            maildir-rank-addr
            urlscan
          ]
          # Needed interactively for the one-time `oama authorize` device-code flow
          # and for `oama show`/`renew` when debugging Outlook auth.
          ++ lib.optional hasOutlookClientId oama;

        accounts.email = {
          maildirBasePath = "mail";

          accounts = {
            tu-berlin = {
              primary = true;
              inherit (a.tu-berlin) address;
              inherit (a.tu-berlin) aliases;
              inherit (a.tu-berlin) realName;
              inherit (a.tu-berlin) userName;
              maildir.path = tuBerlinMaildir;
              folders = {
                inbox = "Inbox";
                sent = "Sent Items";
                drafts = "Drafts";
                trash = "Deleted Items";
              };
              passwordCommand = catSecret "tu_berlin";
              signature = {
                text = a.tu-berlin.signature;
                showSignature = "append";
              };
              imap = {
                host = a.tu-berlin.imapHost;
                port = 993;
                tls.enable = true;
              };
              smtp = {
                host = a.tu-berlin.smtpHost;
                port = 587;
                tls.useStartTls = true;
              };
              mbsync = {
                enable = true;
                create = "maildir";
                extraConfig.account.AuthMechs = "LOGIN";
                patterns = [
                  "INBOX"
                  "Sent Items"
                  "Drafts"
                  "Deleted Items"
                  "Junk Email"
                ];
              };
              msmtp.enable = true;
              neomutt = {
                enable = true;
                extraMailboxes = [
                  "Sent Items"
                  "Drafts"
                  "Deleted Items"
                  "Junk Email"
                ];
              };
              aerc = {
                enable = true;
                extraAccounts = {
                  source = "maildir://~/mail/${tuBerlinMaildir}";
                  outgoing = "smtp+starttls://${urlEncode a.tu-berlin.userName}@${a.tu-berlin.smtpHost}:587";
                  default = "INBOX";
                  aliases = builtins.head a.tu-berlin.aliases;
                  outgoing-cred-cmd = catSecret "tu_berlin";
                  copy-to = "Sent Items";
                  folders-sort = "INBOX,Sent Items,Drafts,Deleted Items,Junk Email";
                };
              };
              imapnotify = {
                enable = true;
                boxes = [ "INBOX" ];
                onNotify = syncAndNotifyCmd "tu-berlin" "TU Berlin";
              };
            };

            gmail = {
              inherit (a.gmail) address;
              inherit (a.gmail) realName;
              inherit (a.gmail) userName;
              passwordCommand = "${catSecretUnspaced "gmail"}";
              imap = {
                host = a.gmail.imapHost;
                port = 993;
                tls.enable = true;
              };
              smtp = {
                host = a.gmail.smtpHost;
                port = 465;
                tls.enable = true;
              };
              mbsync = {
                enable = true;
                create = "maildir";
                patterns = [
                  "*"
                  "![Gmail]*"
                  "!Drafts"
                  "[Gmail]/Sent Mail"
                  "[Gmail]/Drafts"
                  "[Gmail]/Trash"
                  "[Gmail]/All Mail"
                ];
              };
              msmtp.enable = true;
              neomutt = {
                enable = true;
                extraMailboxes = [
                  "[Gmail]/Sent Mail"
                  "[Gmail]/Drafts"
                  "[Gmail]/Trash"
                  "[Gmail]/All Mail"
                ];
              };
              aerc = {
                enable = true;
                extraAccounts = {
                  source = "maildir://~/mail/gmail";
                  outgoing = "smtps://${urlEncode a.gmail.userName}@${a.gmail.smtpHost}:465";
                  default = "INBOX";
                  outgoing-cred-cmd = "${catSecretUnspaced "gmail"}";
                  copy-to = "Sent";
                  folders-sort = "INBOX,Sent,[Gmail]/Sent Mail,[Gmail]/Drafts,[Gmail]/Trash,[Gmail]/All Mail";
                };
              };
              imapnotify = {
                enable = true;
                boxes = [ "INBOX" ];
                onNotify = syncAndNotifyCmd "gmail" "Gmail";
              };
            };

            alganize = {
              inherit (a.alganize) address;
              inherit (a.alganize) realName;
              inherit (a.alganize) userName;
              passwordCommand = catSecret "alganize";
              imap = {
                host = a.alganize.imapHost;
                port = 993;
                tls.enable = true;
              };
              smtp = {
                host = a.alganize.smtpHost;
                port = 465;
                tls.enable = true;
              };
              mbsync = {
                enable = true;
                create = "maildir";
                patterns = [
                  "*"
                  "!Sent"
                  "!Trash"
                ];
              };
              msmtp.enable = true;
              neomutt = {
                enable = true;
                extraMailboxes = [
                  "Gesendet"
                  "Entwürfe"
                  "Papierkorb"
                  "Archiv"
                ];
              };
              aerc = {
                enable = true;
                extraAccounts = {
                  source = "maildir://~/mail/alganize";
                  outgoing = "smtps://${a.alganize.userName}@${a.alganize.smtpHost}:465";
                  default = "INBOX";
                  outgoing-cred-cmd = catSecret "alganize";
                  copy-to = "Gesendet";
                  folders-sort = "INBOX,Gesendet,Entwürfe,Papierkorb,Archiv";
                };
              };
              imapnotify = {
                enable = true;
                boxes = [ "INBOX" ];
                onNotify = syncAndNotifyCmd "alganize" "Alganize";
              };
            };
          }
          // lib.optionalAttrs hasOutlookClientId {
            # Outlook.com personal accounts lost basic auth (and app passwords) on
            # 2024-09-16, so every leg here authenticates with an OAuth2 access
            # token from oama instead of a password: mbsync via SASL XOAUTH2, msmtp
            # via `auth xoauth2`, aerc via the smtp+xoauth2 scheme. neomutt needs no
            # OAuth config of its own — it reads the maildir and sends via msmtp.
            outlook = {
              inherit (a.outlook) address;
              inherit (a.outlook) realName;
              inherit (a.outlook) userName;
              maildir.path = outlookMaildir;
              passwordCommand = oamaAccess a.outlook.address;
              # inbox is left at the default "Inbox" so the local maildir matches
              # the other three accounts.
              folders = { inherit (outlookFolders) sent drafts trash; };
              imap = {
                host = a.outlook.imapHost;
                port = 993;
                tls.enable = true;
              };
              smtp = {
                host = a.outlook.smtpHost;
                port = 587;
                tls.useStartTls = true;
              };
              mbsync = {
                enable = true;
                create = "maildir";
                extraConfig.account.AuthMechs = "XOAUTH2";
                # Left broad so the sync succeeds regardless of how Microsoft
                # localizes the folder names for this mailbox.
                patterns = [ "*" ];
              };
              msmtp = {
                enable = true;
                extraConfig.auth = "xoauth2";
              };
              neomutt = {
                enable = true;
                extraMailboxes = outlookMailboxes;
              };
              aerc = {
                enable = true;
                extraAccounts = {
                  source = "maildir://~/mail/${outlookMaildir}";
                  # No token_endpoint: aerc then treats the cred-cmd output as an
                  # access token rather than a refresh token, which is what oama
                  # hands out. oama owns the refresh, so aerc must not duplicate it.
                  outgoing = "smtp+xoauth2://${urlEncode a.outlook.userName}@${a.outlook.smtpHost}:587";
                  default = "INBOX";
                  outgoing-cred-cmd = oamaAccess a.outlook.address;
                  copy-to = outlookFolders.sent;
                  folders-sort = lib.concatStringsSep "," ([ "INBOX" ] ++ outlookMailboxes);
                };
              };
              imapnotify = {
                enable = true;
                boxes = [ "INBOX" ];
                onNotify = syncAndNotifyCmd "outlook" "Outlook";
                extraConfig.xoAuth2 = true;
              };
            };
          };
        };
      }
    )
  ];
}
