{
  config,
  lib,
  myHostLib,
  ...
}:
let
  cfg = config.my.matrix;
  flakeCfg = config;
in
{
  config.my.branches.matrix.nixosModules = [
    (
      { config, ... }:
      {
        options.my.matrix.enable = myHostLib.mkDefaultOnEnable {
          inherit lib;
          description = "self-hosted Matrix stack";
        };

        config = lib.mkIf config.my.matrix.enable {
          services.matrix-synapse = {
            enable = true;
            settings = {
              server_name = cfg.domain;
              public_baseurl = "https://${cfg.domain}/";
              listeners = [
                {
                  bind_addresses = [ "127.0.0.1" ];
                  port = 8008;
                  type = "http";
                  tls = false;
                  x_forwarded = true;
                  resources = [
                    {
                      compress = true;
                      names = [
                        "client"
                        "federation"
                      ];
                    }
                  ];
                }
              ];
              enable_registration = false;
            };
          };

          security.acme = {
            acceptTerms = true;
            defaults.email = flakeCfg.my.user.email;
          };

          services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            virtualHosts.${cfg.domain} = {
              enableACME = true;
              forceSSL = true;
              locations."/" = {
                proxyPass = "http://127.0.0.1:8008";
              };
            };
          };

          networking.firewall.allowedTCPPorts = [
            80
            443
            8448
          ];

          services.mautrix-telegram = lib.mkIf cfg.enableTelegramBridge {
            enable = true;
            registerToSynapse = true;
            settings = {
              homeserver.address = "http://127.0.0.1:8008";
              homeserver.domain = cfg.domain;
            };
          };

          services.mautrix-whatsapp = lib.mkIf cfg.enableWhatsappBridge {
            enable = true;
            registerToSynapse = true;
            settings = {
              homeserver.address = "http://127.0.0.1:8008";
              homeserver.domain = cfg.domain;
            };
          };

          services.mautrix-signal = lib.mkIf cfg.enableSignalBridge {
            enable = true;
            registerToSynapse = true;
            settings = {
              homeserver.address = "http://127.0.0.1:8008";
              homeserver.domain = cfg.domain;
            };
          };

          warnings = lib.flatten [
            (lib.optional cfg.enableTelegramBridge "mautrix-telegram enabled: set bridge credentials in /var/lib/mautrix-telegram/env before starting the service.")
            (lib.optional cfg.enableWhatsappBridge "mautrix-whatsapp enabled: finish QR login in bridge admin room after first start.")
            (lib.optional cfg.enableSignalBridge "mautrix-signal enabled: set bridge credentials in /var/lib/mautrix-signal/env before starting the service.")
          ];
        };
      }
    )
  ];
}
