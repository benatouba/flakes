{ config, ... }:
let
  cavaGradient = config.my.theme.cava;
  colorSection = ''
    [color]

    gradient = 1

    gradient_color_1 = '${cavaGradient.gradient_color_1}'
    gradient_color_2 = '${cavaGradient.gradient_color_2}'
    gradient_color_3 = '${cavaGradient.gradient_color_3}'
    gradient_color_4 = '${cavaGradient.gradient_color_4}'
    gradient_color_5 = '${cavaGradient.gradient_color_5}'
    gradient_color_6 = '${cavaGradient.gradient_color_6}'
    gradient_color_7 = '${cavaGradient.gradient_color_7}'
    gradient_color_8 = '${cavaGradient.gradient_color_8}'
  '';
in
{
  config.my.branches.desktop.hmModules = [
    {
      home.file.".config/cava/config".text = ''
        [general]

        [input]

        [output]

        ${colorSection}

        [smoothing]

        [eq]
      '';

      home.file.".config/cava/config1".text = ''
        [general]
        bars = 12
        sleep_timer = 10

        [input]

        [output]
        method = raw
        data_format = ascii
        ascii_max_range = 7

        [color]

        [smoothing]

        [eq]
      '';
    }
  ];
}
