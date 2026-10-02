# Template for <nix-secrets>/identity.nix. Copy it there and replace the values.
# Every key is optional: missing keys fall back to these anonymised placeholders,
# so CI and forks evaluate without any private data.
{
  email = "user@example.org";
  workoutDomain = "workout.example.org"; # public wger hostname (esprimo)
  matrixDomain = "matrix.example.org"; # Matrix server_name (ec2)
  ddnsHostname = "myhost-example.dedyn.io"; # deSEC dynamic DNS name (esprimo)
  lanIp = "192.168.1.10"; # esprimo LAN address for split-horizon DNS + allowed hosts
  sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPlaceholderPlaceholderPlaceholderPlace user@example.org";
}
