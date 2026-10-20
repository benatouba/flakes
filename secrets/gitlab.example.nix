{
  # Private metadata only. The token itself stays in the vault and is read by rbw.
  # Like other private Nix metadata, these values enter generated Nix-store files.
  host = "gitlab.example.org";
  userName = "your-gitlab-username";
  tokenEntry = "your-vault-entry-id";
}
