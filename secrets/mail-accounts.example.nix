{
  institution = {
    address = "you@example.org";
    aliases = [ "alias@example.org" ];
    realName = "Your Name";
    userName = "you";
    signature = "Best regards";
    imapHost = "imap.example.org";
    smtpHost = "smtp.example.org";
  };

  # Optional: enabled only when b-tu metadata exists; password is SOPS mail_btu.
  # INBOX and Sent are synced.
  b-tu = {
    address = "you@example.org";
    aliases = [ ];
    realName = "Your Name";
    userName = "your-btu-login";
    imapHost = "mailin.b-tu.de";
    smtpHost = "mailout.b-tu.de";
    signature = ''
      Dr. Your Name

      Wissenschaftlicher Mitarbeiter | Postdoctoral Researcher
      Fachgebiet Atmosphärische Prozesse | Chair of Atmospheric Processes

      Fakultät 2
      Brandenburgische Technische Universität Cottbus-Senftenberg
      Burger Chaussee 2, D-03044 Cottbus, Germany

      you@example.org
      https://www.b-tu.de/fg-meteorologie
    '';
  };

  gmail = {
    address = "you@gmail.com";
    realName = "Your Name";
    userName = "you@gmail.com";
    imapHost = "imap.gmail.com";
    smtpHost = "smtp.gmail.com";
  };

  company = {
    address = "you@work.example";
    realName = "Your Name";
    userName = "you@work.example";
    imapHost = "imap.work.example";
    smtpHost = "smtp.work.example";
  };

  "company-kundenservice" = {
    address = "support@work.example";
    realName = "Your Name";
    userName = "support@work.example";
    imapHost = "imap.work.example";
    smtpHost = "smtp.work.example";
  };

  outlook = {
    address = "you@outlook.example";
    realName = "Your Name";
    userName = "you@outlook.example";
    imapHost = "outlook.office365.example";
    smtpHost = "smtp.office365.example";
  };
}
