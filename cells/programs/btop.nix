{ config, ... }:
let
  theme = config.my.theme;
  c = theme.colors;
  upper = s: builtins.replaceStrings [ "a" "b" "c" "d" "e" "f" ] [ "A" "B" "C" "D" "E" "F" ] s;
  btopTheme = ''
    theme[main_bg]="#${upper c.base}"
    theme[main_fg]="#${upper c.text}"
    theme[title]="#${upper c.text}"
    theme[hi_fg]="#${upper c.blue}"
    theme[selected_bg]="#${upper c.surface1}"
    theme[selected_fg]="#${upper c.blue}"
    theme[inactive_fg]="#${upper c.overlay1}"
    theme[graph_text]="#${upper c.rosewater}"
    theme[meter_bg]="#${upper c.surface1}"
    theme[proc_misc]="#${upper c.rosewater}"
    theme[cpu_box]="#${upper c.sapphire}"
    theme[mem_box]="#${upper c.green}"
    theme[net_box]="#${upper c.mauve}"
    theme[proc_box]="#${upper c.flamingo}"
    theme[div_line]="#${upper c.overlay0}"
    theme[temp_start]="#${upper c.yellow}"
    theme[temp_mid]="#${upper c.peach}"
    theme[temp_end]="#${upper c.red}"
    theme[cpu_start]="#${upper c.sapphire}"
    theme[cpu_mid]="#${upper c.sky}"
    theme[cpu_end]="#${upper c.teal}"
    theme[free_start]="#${upper c.teal}"
    theme[free_mid]="#${upper c.teal}"
    theme[free_end]="#${upper c.green}"
    theme[cached_start]="#${upper c.pink}"
    theme[cached_mid]="#${upper c.pink}"
    theme[cached_end]="#${upper c.mauve}"
    theme[available_start]="#${upper c.rosewater}"
    theme[available_mid]="#${upper c.flamingo}"
    theme[available_end]="#${upper c.flamingo}"
    theme[used_start]="#${upper c.peach}"
    theme[used_mid]="#${upper c.peach}"
    theme[used_end]="#${upper c.red}"
    theme[download_start]="#${upper c.lavender}"
    theme[download_mid]="#${upper c.lavender}"
    theme[download_end]="#${upper c.mauve}"
    theme[upload_start]="#${upper c.lavender}"
    theme[upload_mid]="#${upper c.lavender}"
    theme[upload_end]="#${upper c.mauve}"
    theme[process_start]="#${upper c.sapphire}"
    theme[process_mid]="#${upper c.sky}"
    theme[process_end]="#${upper c.teal}"
  '';
in
{
  config.my.branches.desktop.hmModules = [
    {
      programs.btop = {
        enable = true;
        settings = {
          color_theme = theme.slug;
        };
      };
      home.file.".config/btop/themes/${theme.slug}.theme".text = btopTheme;
    }
  ];
}
