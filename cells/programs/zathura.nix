{ config, ... }:
let
  c = config.my.theme.colors;
in
{
  config.my.branches.desktop.hmModules = [
    {
      programs.zathura = {
        enable = true;
        options = {
          adjust-open = "best-fit";
          pages-per-row = 1;
          scroll-page-aware = true;
          scroll-full-overlap = 0.01;
          scroll-step = 50;
          zoom-min = 10;
          guioptions = "";
          render-loading = false;
          selection-clipboard = "clipboard";

          font = "${config.my.theme.font.mono} ${toString config.my.theme.font.monoSize}";

          default-fg = "#${c.blue}";
          default-bg = "#${c.base}";

          completion-bg = "#${c.base}";
          completion-fg = "#${c.blue}";
          completion-highlight-bg = "#${c.surface0}";
          completion-highlight-fg = "#${c.blue}";
          completion-group-bg = "#${c.base}";
          completion-group-fg = "#${c.sky}";

          statusbar-fg = "#${c.lavender}";
          statusbar-bg = "#${c.base}";
          statusbar-h-padding = 10;
          statusbar-v-padding = 10;

          notification-bg = "#${c.base}";
          notification-fg = "#${c.text}";
          notification-error-bg = "#${c.red}";
          notification-error-fg = "#${c.text}";
          notification-warning-bg = "#${c.yellow}";
          notification-warning-fg = "#${c.text}";
          selection-notification = true;

          inputbar-fg = "#${c.lavender}";
          inputbar-bg = "#${c.base}";

          recolor = false;
          recolor-lightcolor = "#${c.base}";
          recolor-darkcolor = "#${c.text}";

          index-fg = "#${c.blue}";
          index-bg = "#${c.base}";
          index-active-fg = "#${c.blue}";
          index-active-bg = "#${c.surface0}";

          render-loading-bg = "#${c.base}";
          render-loading-fg = "#${c.blue}";

          highlight-color = "#${c.blue}";
          highlight-active-color = "#${c.mauve}";
        };
      };
    }
  ];
}
