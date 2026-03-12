let
  common = import ../common;
in
[
  ./imgview
  ./notice
  ./mpv
  ./wlogout
  ./walker
] ++ common
