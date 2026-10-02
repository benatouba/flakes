self: super: {
  gdal = super.gdal.overrideAttrs (_old: {
    name = "gdal-3.4.0";
    pname = "gdal";
    src = self.fetchFromGitHub {
      owner = "OSGeo";
      repo = "gdal";
      rev = "v3.4.0";
      # On hash mismatch, nix prints the wanted hash; paste it below.
      hash = "sha256-fdj/o+dm7V8QLrjnaQobaFX80+penn+ohx/yNmUryRA=";
    };
  });
}
