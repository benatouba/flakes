{ config, pkgs, inputs, theme, ... }:

let
  accts = import "${inputs.nix-secrets}/mail-accounts.nix";
  a = accts;  # shorthand
  c = theme.colors;

  # URL-encode a string for IMAP/SMTP URIs
  urlEncode = builtins.replaceStrings
    [ "@"  "\\" ]
    [ "%40" "%5C" ];

  # sops secret path helper
  secret = name: config.sops.secrets."mail_${name}".path;
  catSecret = name: "cat ${secret name}";

  # Notification command for new mail
  notifyCmd = account: "${pkgs.libnotify}/bin/notify-send -a 'Mail' -i mail-unread '${account}' 'New mail received'";
in
{
  services.imapnotify.enable = true;
  sops = {
    defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
    age.keyFile = "/persist/sops/age/keys.txt";
    secrets = {
      mail_tu_berlin = { };
      mail_gmail = { };
      mail_alganize = { };
    };
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
      # Sidebar navigation
      { map = [ "index" "pager" ]; key = "\\Ck"; action = "sidebar-prev"; }
      { map = [ "index" "pager" ]; key = "\\Cj"; action = "sidebar-next"; }
      { map = [ "index" "pager" ]; key = "\\Co"; action = "sidebar-open"; }
      { map = [ "index" "pager" ]; key = "B";    action = "sidebar-toggle-visible"; }

      # Index: additions beyond vim-keys.rc
      { map = [ "index" ]; key = "l";  action = "display-message"; }
      { map = [ "index" ]; key = "u";  action = "undelete-message"; }
      { map = [ "index" ]; key = "r";  action = "reply"; }
      { map = [ "index" ]; key = "R";  action = "group-reply"; }
      { map = [ "index" ]; key = "f";  action = "forward-message"; }
      { map = [ "index" ]; key = "c";  action = "mail"; }
      { map = [ "index" ]; key = "/";  action = "search"; }
      { map = [ "index" ]; key = "x";  action = "sync-mailbox"; }
      { map = [ "index" ]; key = "s";  action = "save-message"; }
      { map = [ "index" ]; key = "t";  action = "tag-entry"; }

      # Pager: additions beyond vim-keys.rc
      { map = [ "pager" ]; key = "h";  action = "exit"; }
      { map = [ "pager" ]; key = "l";  action = "view-attachments"; }
      { map = [ "pager" ]; key = "r";  action = "reply"; }
      { map = [ "pager" ]; key = "R";  action = "group-reply"; }
      { map = [ "pager" ]; key = "f";  action = "forward-message"; }
      { map = [ "pager" ]; key = "u";  action = "undelete-message"; }
      { map = [ "pager" ]; key = "/";  action = "search"; }

      # Attach: vim motions
      { map = [ "attach" ]; key = "l"; action = "view-mailcap"; }
      { map = [ "attach" ]; key = "h"; action = "exit"; }

      # Compose
      { map = [ "compose" ]; key = "l"; action = "view-attach"; }
      { map = [ "compose" ]; key = "h"; action = "exit"; }
    ];
    macros = [
      { map = [ "index" ]; key = "O"; action = "<shell-escape>mbsync -a<enter>"; }
      # Quick account switching
      { map = [ "index" ]; key = "gi"; action = "<change-folder>~/mail/tu-berlin/Inbox<enter>"; }
      { map = [ "index" ]; key = "gm"; action = "<change-folder>~/mail/gmail/Inbox<enter>"; }
      # { map = [ "index" ]; key = "gk"; action = "<change-folder>~/mail/klima-it/Inbox<enter>"; }
      { map = [ "index" ]; key = "ga"; action = "<change-folder>~/mail/alganize/Inbox<enter>"; }
    ];
    };

    mbsync.enable = true;
    msmtp.enable = true;

  # --- aerc (alternative client, connects to IMAP directly) ---
  aerc = {
    enable = true;
    stylesets.${theme.slug} = {
      "*.default" = "true";
      "*.normal" = "true";
      "default.fg" = "#${c.text}";
      "default.bg" = "#${c.base}";
      "error.fg" = "#${c.red}";
      "error.bold" = "true";
      "warning.fg" = "#${c.peach}";
      "success.fg" = "#${c.green}";
      "title.fg" = "#${c.mauve}";
      "title.bold" = "true";
      "header.fg" = "#${c.blue}";
      "header.bold" = "true";
      "statusline_default.fg" = "#${c.text}";
      "statusline_default.bg" = "#${c.mantle}";
      "statusline_error.fg" = "#${c.red}";
      "statusline_error.bg" = "#${c.mantle}";
      "statusline_success.fg" = "#${c.green}";
      "statusline_success.bg" = "#${c.mantle}";
      "msglist_default.fg" = "#${c.subtext0}";
      "msglist_unread.fg" = "#${c.text}";
      "msglist_unread.bold" = "true";
      "msglist_read.fg" = "#${c.subtext0}";
      "msglist_flagged.fg" = "#${c.peach}";
      "msglist_deleted.fg" = "#${c.overlay0}";
      "msglist_marked.fg" = "#${c.mauve}";
      "msglist_marked.reverse" = "true";
      "dirlist_default.fg" = "#${c.subtext1}";
      "dirlist_recent.fg" = "#${c.blue}";
      "dirlist_recent.bold" = "true";
      "completion_default.fg" = "#${c.text}";
      "completion_default.bg" = "#${c.surface0}";
      "completion_pill.fg" = "#${c.base}";
      "completion_pill.bg" = "#${c.mauve}";
      "tab.fg" = "#${c.subtext0}";
      "tab.bg" = "#${c.mantle}";
      "tab.selected.fg" = "#${c.text}";
      "tab.selected.bg" = "#${c.surface0}";
      "tab.selected.bold" = "true";
      "selector_default.fg" = "#${c.text}";
      "selector_focused.fg" = "#${c.mauve}";
      "selector_focused.bold" = "true";
      "selector_chooser.fg" = "#${c.blue}";
      "border.fg" = "#${c.surface1}";
    };
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
        address-book-cmd = "${pkgs.maildir-rank-addr}/bin/maildir-rank-addr '%s'";
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
        ":" = "::";
        v = ":mark -v<Enter>";

        # Account switching
        gi = ":cf tu-berlin/INBOX<Enter>";
        gm = ":cf gmail/INBOX<Enter>";
        # gk = ":cf klima-it/INBOX<Enter>";
        ga = ":cf alganize/INBOX<Enter>";
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
        ":" = "::";
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
        ":" = "::";
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
        ":" = "::";
      };
      terminal = {
        "<C-q>" = ":close<Enter>";
      };
    };
  }; # close aerc
  }; # close programs

  services.mbsync = {
    enable = true;
    frequency = "*:0/5";
    postExec = "${pkgs.maildir-rank-addr}/bin/maildir-rank-addr";
  };

  # Mailcap for viewing HTML emails
  xdg.configFile."neomutt/mailcap".text = ''
    text/html; xdg-open %s ; nametemplate=%s.html
    text/html; lynx -assume_charset=%{charset} -display_charset=utf-8 -dump %s; nametemplate=%s.html; copiousoutput
  '';

  home.packages = with pkgs; [
    isync              # provides mbsync (for neomutt)
    lynx               # HTML email rendering
    maildir-rank-addr  # address completion from maildir history
  ];

  # --- neomutt account definitions (via home-manager email module) ---
  accounts.email = {
    maildirBasePath = "mail";

    accounts = {
      tu-berlin = {
        primary = true;
        inherit (a.tu-berlin) address;
        inherit (a.tu-berlin) aliases;
        inherit (a.tu-berlin) realName;
        inherit (a.tu-berlin) userName;
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
          patterns = [ "INBOX" "Sent" "Drafts" "Trash" "Junk-E-Mail" "Archives" "Archives/*" ];
        };
        msmtp.enable = true;
        neomutt = {
          enable = true;
          extraMailboxes = [ "Sent" "Drafts" "Trash" "Junk-E-Mail" "Archives" ];
        };
        aerc = {
          enable = true;
          extraAccounts = {
            source = "maildir://~/mail/tu-berlin";
            outgoing = "smtp+starttls://${urlEncode a.tu-berlin.userName}@${a.tu-berlin.smtpHost}:587";
            default = "INBOX";
            aliases = builtins.head a.tu-berlin.aliases;
            outgoing-cred-cmd = catSecret "tu_berlin";
            copy-to = "Sent";
            folders-sort = "INBOX,Sent,Drafts,Trash,Junk-E-Mail,Archives";
          };
        };
        imapnotify = {
          enable = true;
          boxes = [ "INBOX" ];
          onNotify = notifyCmd "TU Berlin";
        };
      };

      gmail = {
        inherit (a.gmail) address;
        inherit (a.gmail) realName;
        inherit (a.gmail) userName;
        passwordCommand = catSecret "gmail";
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
          patterns = [ "*" "![Gmail]*" "[Gmail]/Sent Mail" "[Gmail]/Drafts" "[Gmail]/Trash" "[Gmail]/All Mail" ];
        };
        msmtp.enable = true;
        neomutt = {
          enable = true;
          extraMailboxes = [ "[Gmail]/Sent Mail" "[Gmail]/Drafts" "[Gmail]/Trash" "[Gmail]/All Mail" ];
        };
        aerc = {
          enable = true;
          extraAccounts = {
            source = "maildir://~/mail/gmail";
            outgoing = "smtps://${urlEncode a.gmail.userName}@${a.gmail.smtpHost}:465";
            default = "INBOX";
            outgoing-cred-cmd = catSecret "gmail";
            copy-to = "Sent";
            folders-sort = "INBOX,Sent,[Gmail]/Sent Mail,[Gmail]/Drafts,[Gmail]/Trash,[Gmail]/All Mail";
          };
        };
        imapnotify = {
          enable = true;
          boxes = [ "INBOX" ];
          onNotify = notifyCmd "Gmail";
        };
      };

      # klima-it = {
      #   address = a.klima-it.address;
      #   realName = a.klima-it.realName;
      #   userName = a.klima-it.userName;
      #   passwordCommand = catSecret "tu_berlin";
      #   imap = {
      #     host = a.klima-it.imapHost;
      #     port = 993;
      #     tls.enable = true;
      #   };
      #   smtp = {
      #     host = a.klima-it.smtpHost;
      #     port = 587;
      #     tls.useStartTls = true;
      #   };
      #   mbsync = {
      #     enable = true;
      #     create = "maildir";
      #   };
      #   msmtp.enable = true;
      #   neomutt = {
      #     enable = true;
      #     extraMailboxes = [ "Sent" "Drafts" "Trash" ];
      #   };
      #   aerc = {
      #     enable = true;
      #     extraAccounts = {
      #       source = "imaps://${urlEncode a.klima-it.userName}@${a.klima-it.imapHost}:993";
      #       outgoing = "smtp+starttls://${urlEncode a.tu-berlin.userName}@${a.klima-it.smtpHost}:587";
      #       default = "INBOX";
      #       source-cred-cmd = catSecret "tu_berlin";
      #       outgoing-cred-cmd = catSecret "tu_berlin";
      #       copy-to = "Sent";
      #       folders-sort = "INBOX,Sent,Drafts,Trash";
      #       check-mail-timeout = "5m";
      #     };
      #   };
      #   imapnotify = {
      #     enable = true;
      #     boxes = [ "INBOX" ];
      #     onNotify = notifyCmd "Klima-IT";
      #   };
      # };

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
        };
        msmtp.enable = true;
        neomutt = {
          enable = true;
          extraMailboxes = [ "Gesendet" "Entwürfe" "Papierkorb" "Archiv" ];
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
          onNotify = notifyCmd "Alganize";
        };
      };
    };
  };
}
