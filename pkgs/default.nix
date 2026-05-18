{
  overlay =
    final: _prev:
    let
      dirContents = builtins.readDir ../pkgs;
      isPackageDir =
        name: dirContents.${name} == "directory" && builtins.pathExists (../pkgs + "/${name}/default.nix");
      genPackage = name: {
        inherit name;
        value = final.callPackage (../pkgs + "/${name}") { };
      };
      names = builtins.filter isPackageDir (builtins.attrNames dirContents);
    in
    builtins.listToAttrs (map genPackage names);
}
