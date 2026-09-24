{
  instKey = "~/.ssh/example";

  instProxy = {
    hostname = "proxy.example.org";
    user = "user";
    port = 22;
  };

  hosts = {
    github = {
      hostname = "github.com";
      user = "git";
    };

    projectCompanyDevice = {
      hostname = "example.host.com";
      user = "example-user";
    };

    "inst-proxy" = {
      hostname = "proxy.example.org";
      user = "user";
      port = 22;
    };

    esprimo = {
      hostname = "1.1.1.1";
      user = "example";
      port = 22;
    };
  };
}
