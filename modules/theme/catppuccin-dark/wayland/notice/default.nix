{ config, pkgs, ... }:

{
  services = {
    mako = {
      settings = {
        font = "Iosevka Nerd Font 12";
        width = 256;
        height = 500;
        margin = "10";
        padding = "5";
        border-size = 3;
        border-radius = 3;
        background-color = "#1a1b26";
        border-color = "#c0caf5";
        progress-color = "over #302D41";
        text-color = "#c0caf5";
        text-alignment = "center";

        "urgency=high" = {
          border-color = "#F8BD96";
        };
      };
    };
  };
}
