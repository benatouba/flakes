{ pkgs, ... }:

let
  grimblast_watermark = pkgs.writeShellScriptBin "grimblast_watermark" ''
        FILE=$(date "+%Y-%m-%d"T"%H:%M:%S").png
    # Get the picture from maim
        grimblast --notify --cursor save area $HOME/pictures/src.png >> /dev/null 2>&1
    # add shadow, round corner, border and watermark
        convert $HOME/pictures/src.png \
          \( +clone -alpha extract \
          -draw 'fill black polygon 0,0 0,8 8,0 fill white circle 8,8 8,0' \
          \( +clone -flip \) -compose Multiply -composite \
          \( +clone -flop \) -compose Multiply -composite \
          \) -alpha off -compose CopyOpacity -composite $HOME/pictures/output.png
    #
        convert $HOME/pictures/output.png -bordercolor none -border 20 \( +clone -background black -shadow 80x8+15+15 \) \
          +swap -background transparent -layers merge +repage $HOME/pictures/$FILE
    #
        composite -gravity Southeast "${./watermark.png}" $HOME/pictures/$FILE $HOME/pictures/$FILE
    #
        wl-copy < $HOME/pictures/$FILE
    #   remove the other pictures
        rm $HOME/pictures/src.png $HOME/pictures/output.png
  '';

  grimshot_watermark = pkgs.writeShellScriptBin "grimshot_watermark" ''
        FILE=$(date "+%Y-%m-%d"T"%H:%M:%S").png
    # Get the picture from maim
        grimshot --notify  save area $HOME/pictures/src.png >> /dev/null 2>&1
    # add shadow, round corner, border and watermark
        convert $HOME/pictures/src.png \
          \( +clone -alpha extract \
          -draw 'fill black polygon 0,0 0,8 8,0 fill white circle 8,8 8,0' \
          \( +clone -flip \) -compose Multiply -composite \
          \( +clone -flop \) -compose Multiply -composite \
          \) -alpha off -compose CopyOpacity -composite $HOME/pictures/output.png
    #
        convert $HOME/pictures/output.png -bordercolor none -border 20 \( +clone -background black -shadow 80x8+15+15 \) \
          +swap -background transparent -layers merge +repage $HOME/pictures/$FILE
    #
        composite -gravity Southeast "${./watermark.png}" $HOME/pictures/$FILE $HOME/pictures/$FILE
    #
    # # Send the picture to clipboard
        wl-copy < $HOME/pictures/$FILE
    #
    # # remove the other pictures
        rm $HOME/pictures/src.png $HOME/pictures/output.png
  '';
in
{
  home.packages = [
    grimblast_watermark
    grimshot_watermark
  ];
}
