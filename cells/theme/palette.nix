{ config, ... }:
let
  themes = {
    catppuccin-mocha = {
      slug = "catppuccin-mocha";
      variant = "dark";
      colors = {
        rosewater = "f5e0dc";
        flamingo = "f2cdcd";
        pink = "f5c2e7";
        mauve = "cba6f7";
        red = "f38ba8";
        maroon = "eba0ac";
        peach = "fab387";
        yellow = "f9e2af";
        green = "a6e3a1";
        teal = "94e2d5";
        sky = "89dceb";
        sapphire = "74c7ec";
        blue = "89b4fa";
        lavender = "b4befe";
        text = "cdd6f4";
        subtext1 = "bac2de";
        subtext0 = "a6adc8";
        overlay2 = "9399b2";
        overlay1 = "7f849c";
        overlay0 = "6c7086";
        surface2 = "585b70";
        surface1 = "45475a";
        surface0 = "313244";
        base = "1e1e2e";
        mantle = "181825";
        crust = "11111b";
      };
      accent = "mauve";
      borderColor = "ffc0cb";
      gtk = {
        theme = "Catppuccin-Frappe-Pink";
        package = "catppuccin-frappe-gtk";
      };
      icons = {
        name = "Papirus-Dark";
      };
      cursor = {
        name = "Catppuccin-Frappe-Dark";
        size = 20;
      };
      colorScheme = "prefer-dark";
      kvantum = "catppuccin-mocha-mauve";
      weztermColorScheme = "Catppuccin Mocha";
      starshipPalette = "catppuccin_mocha";
      waybarVariation = "mocha";
      font = {
        sans = "Noto Sans";
        mono = "JetBrainsMono Nerd Font";
        size = 11;
        monoSize = 15;
      };
      cava = {
        gradient_color_1 = "#B5E8E0";
        gradient_color_2 = "#89DCEB";
        gradient_color_3 = "#96CDFB";
        gradient_color_4 = "#DDB6F2";
        gradient_color_5 = "#F5C2E7";
        gradient_color_6 = "#E8A2AF";
        gradient_color_7 = "#F2CDCD";
        gradient_color_8 = "#F5E0DC";
      };
    };

    catppuccin-latte = {
      slug = "catppuccin-latte";
      variant = "light";
      colors = {
        rosewater = "dc8a78";
        flamingo = "dd7878";
        pink = "ea76cb";
        mauve = "8839ef";
        red = "d20f39";
        maroon = "e64553";
        peach = "fe640b";
        yellow = "df8e1d";
        green = "40a02b";
        teal = "179299";
        sky = "04a5e5";
        sapphire = "209fb5";
        blue = "1e66f5";
        lavender = "7287fd";
        text = "4c4f69";
        subtext1 = "5c5f77";
        subtext0 = "6c6f85";
        overlay2 = "7c7f93";
        overlay1 = "8c8fa1";
        overlay0 = "9ca0b0";
        surface2 = "acb0be";
        surface1 = "bcc0cc";
        surface0 = "ccd0da";
        base = "eff1f5";
        mantle = "e6e9ef";
        crust = "dce0e8";
      };
      accent = "mauve";
      borderColor = "C4ACEB";
      gtk = {
        theme = "Catppuccin-Latte-Green";
        package = "catppuccin-latte-gtk";
      };
      icons = {
        name = "Papirus-Light";
      };
      cursor = {
        name = "Catppuccin-Latte-Dark";
        size = 20;
      };
      colorScheme = "prefer-light";
      kvantum = "catppuccin-latte-mauve";
      weztermColorScheme = "Catppuccin Latte";
      starshipPalette = "catppuccin_latte";
      waybarVariation = "latte";
      font = {
        sans = "Noto Sans";
        mono = "JetBrainsMono Nerd Font";
        size = 11;
        monoSize = 15;
      };
      cava = {
        gradient_color_1 = "#179299";
        gradient_color_2 = "#04a5e5";
        gradient_color_3 = "#209fb5";
        gradient_color_4 = "#1e66f5";
        gradient_color_5 = "#8839ef";
        gradient_color_6 = "#ea76cb";
        gradient_color_7 = "#dd7878";
        gradient_color_8 = "#dc8a78";
      };
    };
  };
in
{
  config.my.theme =
    themes.${config.my.profile.theme} or (throw "Unknown theme: ${config.my.profile.theme}");
}
