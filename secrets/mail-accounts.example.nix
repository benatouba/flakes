{
  "tu-berlin" = {
    address = "you@example.org";
    aliases = [ "alias@example.org" ];
    realName = "Your Name";
    userName = "you";
    signature = "Best regards";
    imapHost = "imap.example.org";
    smtpHost = "smtp.example.org";
  };

  gmail = {
    address = "you@gmail.com";
    realName = "Your Name";
    userName = "you@gmail.com";
    imapHost = "imap.gmail.com";
    smtpHost = "smtp.gmail.com";
  };

  alganize = {
    address = "you@work.example";
    realName = "Your Name";
    userName = "you@work.example";
    imapHost = "imap.work.example";
    smtpHost = "smtp.work.example";
  };

  "alganize-kundenservice" = {
    address = "support@work.example";
    realName = "Your Name";
    userName = "support@work.example";
    imapHost = "imap.work.example";
    smtpHost = "smtp.work.example";
  };

  # Needed even though secrets.example.yaml deliberately carries no
  # mail_outlook_client_id: cells/programs/mail.nix gates the *account* on that
  # secret, but the warning it emits when the secret is absent interpolates
  # a.outlook.address, so the attribute has to exist either way.
  outlook = {
    address = "you@outlook.example";
    realName = "Your Name";
    userName = "you@outlook.example";
    imapHost = "outlook.office365.example";
    smtpHost = "smtp.office365.example";
  };
}
