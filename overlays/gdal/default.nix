self: super:
{
  gdal = super.gdal.overrideAttrs (old: {
    name = "gdal-3.4.0";
    pname = "gdal-3.4.0";
    src = self.fetchFromGitHub {
      owner = "OSGeo";
      repo = "gdal";
      rev = "v3.4.0";
      # If you don't know the hash, the first time, set:
      # sha256 = "0000000000000000000000000000000000000000000000000000";
      # then nix will fail the build with such an error message:
      # hash mismatch in fixed-output derivation '/nix/store/m1ga09c0z1a6n7rj8ky3s31dpgalsn0n-source':
      # wanted: sha256:0000000000000000000000000000000000000000000000000000
      # got:    sha256:173gxk0ymiw94glyjzjizp8bv8g72gwkjhacigd1an09jshdrjb4
      hash = "sha256-fdj/o+dm7V8QLrjnaQobaFX80+penn+ohx/yNmUryRA=";
    };
  });
}
