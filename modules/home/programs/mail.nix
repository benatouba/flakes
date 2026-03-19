{ config, pkgs, lib, inputs, theme, ... }:

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
  sops.defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
  sops.age.keyFile = "/persist/sops/age/keys.txt";

  sops.secrets = {
    mail_tu_berlin = { };
    mail_gmail = { };
    mail_alganize = { };
  };

  programs.neomutt = {
    enable = true;
    vimKeys = true;
    sort = "reverse-date";
    sidebar = {
      enable = true;
      width = 30;
    };
    settings = {
      mail_check_stats = "yes";
      mailcap_path = "${config.xdg.configHome}/neomutt/mailcap";
    };
    binds = [
      # Sidebar navigation
      { map = [ "index" "pager" ]; key = "\\Ck"; action = "sidebar-prev"; }
      { map = [ "index" "pager" ]; key = "\\Cj"; action = "sidebar-next"; }
      { map = [ "index" "pager" ]; key = "\\Co"; action = "sidebar-open"; }
      { map = [ "index" "pager" ]; key = "B";    action = "sidebar-toggle-visible"; }

      # Index: vim motions
      { map = [ "index" ]; key = "j";  action = "next-entry"; }
      { map = [ "index" ]; key = "k";  action = "previous-entry"; }
      { map = [ "index" ]; key = "gT"; action = "noop"; }
      { map = [ "index" ]; key = "g";  action = "noop"; }
      { map = [ "index" ]; key = "gg"; action = "first-entry"; }
      { map = [ "index" ]; key = "G";  action = "last-entry"; }
      { map = [ "index" ]; key = "\\Cd"; action = "half-down"; }
      { map = [ "index" ]; key = "\\Cu"; action = "half-up"; }
      { map = [ "index" ]; key = "l";  action = "display-message"; }
      { map = [ "index" ]; key = "dT"; action = "noop"; }
      { map = [ "index" ]; key = "d";  action = "delete-message"; }
      { map = [ "index" ]; key = "u";  action = "undelete-message"; }
      { map = [ "index" ]; key = "r";  action = "reply"; }
      { map = [ "index" ]; key = "R";  action = "group-reply"; }
      { map = [ "index" ]; key = "f";  action = "forward-message"; }
      { map = [ "index" ]; key = "c";  action = "mail"; }
      { map = [ "index" ]; key = "/";  action = "search"; }
      { map = [ "index" ]; key = "n";  action = "search-next"; }
      { map = [ "index" ]; key = "N";  action = "search-opposite"; }
      { map = [ "index" ]; key = "x";  action = "sync-mailbox"; }
      { map = [ "index" ]; key = "s";  action = "save-message"; }
      { map = [ "index" ]; key = "t";  action = "tag-entry"; }

      # Pager: vim motions
      { map = [ "pager" ]; key = "j";  action = "next-line"; }
      { map = [ "pager" ]; key = "k";  action = "previous-line"; }
      { map = [ "pager" ]; key = "gT"; action = "noop"; }
      { map = [ "pager" ]; key = "g";  action = "noop"; }
      { map = [ "pager" ]; key = "gg"; action = "top"; }
      { map = [ "pager" ]; key = "G";  action = "bottom"; }
      { map = [ "pager" ]; key = "\\Cd"; action = "half-down"; }
      { map = [ "pager" ]; key = "\\Cu"; action = "half-up"; }
      { map = [ "pager" ]; key = "h";  action = "exit"; }
      { map = [ "pager" ]; key = "l";  action = "view-attachments"; }
      { map = [ "pager" ]; key = "r";  action = "reply"; }
      { map = [ "pager" ]; key = "R";  action = "group-reply"; }
      { map = [ "pager" ]; key = "f";  action = "forward-message"; }
      { map = [ "pager" ]; key = "dT"; action = "noop"; }
      { map = [ "pager" ]; key = "d";  action = "delete-message"; }
      { map = [ "pager" ]; key = "u";  action = "undelete-message"; }
      { map = [ "pager" ]; key = "/";  action = "search"; }
      { map = [ "pager" ]; key = "n";  action = "search-next"; }
      { map = [ "pager" ]; key = "N";  action = "search-opposite"; }

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
      { map = [ "index" ]; key = "gi"; action = "<change-folder>=tu-berlin/INBOX<enter>"; }
      { map = [ "index" ]; key = "gm"; action = "<change-folder>=gmail/INBOX<enter>"; }
      # { map = [ "index" ]; key = "gk"; action = "<change-folder>=klima-it/INBOX<enter>"; }
      { map = [ "index" ]; key = "ga"; action = "<change-folder>=alganize/INBOX<enter>"; }
    ];
  };

  programs.mbsync.enable = true;
  programs.msmtp.enable = true;

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

  # --- aerc (alternative client, connects to IMAP directly) ---
  programs.aerc = {
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
  };

  # --- neomutt account definitions (via home-manager email module) ---
  accounts.email = {
    maildirBasePath = "mail";

    accounts = {
      tu-berlin = {
        primary = true;
        address = a.tu-berlin.address;
        aliases = a.tu-berlin.aliases;
        realName = a.tu-berlin.realName;
        userName = a.tu-berlin.userName;
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
        address = a.gmail.address;
        realName = a.gmail.realName;
        userName = a.gmail.userName;
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
        address = a.alganize.address;
        realName = a.alganize.realName;
        userName = a.alganize.userName;
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
