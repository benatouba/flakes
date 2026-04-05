{
  tuKey = "~/.ssh/id_ed25519";

  tuProxy = {
    hostname = "proxy.example.org";
    user = "user";
    port = 22;
  };

  hosts = {
    github = {
      hostname = "github.com";
      user = "git";
    };

    "tu-proxy" = {
      hostname = "proxy.example.org";
      user = "user";
      port = 22;
    };
  };
}
