{ fetchurl, stdenv, pkgconfig, autoreconfHook, gettext, glib, buildPackages }:

# gts generates binaries during build that will be used during the build process.
# In case of cross-platform  builds, this package needs to bootstrap itself
# in order to generate these binaries for the propper build architecture.
# Please keep that in mind when making changes to the derivation.

# When making significant changes, please try to test cross-platform builds as well.
# Example:
#   nix-build . -A pkgsCross.aarch64-multiplatform.gts
#   nix-shell -p qemu --run "qemu-aarch64 result-bin/bin/transform --help"

let

  cross = stdenv.hostPlatform != stdenv.buildPlatform;

  name = "gts";
  drv = { pname ? name } : rec {
    inherit pname;
    version = "0.7.6";

    outputs = [ "bin" "dev" "out" ];

    depsBuildBuild = [ buildPackages.stdenv.cc ];

    src = fetchurl {
      url = "mirror://sourceforge/gts/${name}-${version}.tar.gz";
      sha256 = "07mqx09jxh8cv9753y2d2jsv7wp8vjmrd7zcfpbrddz3wc9kx705";
    };

    # glib needs to be in nativeBuildInputs in order for AM_PATH_GLIB_2_0
    # c to be generated orrectly during cross-platform builds
    nativeBuildInputs = [ pkgconfig autoreconfHook glib ];
    buildInputs = [ gettext ];
    propagatedBuildInputs = [ glib ];

    doCheck = false; # fails with "permission denied"

    meta = {
      homepage = "http://gts.sourceforge.net/";
      license = stdenv.lib.licenses.lgpl2Plus;
      description = "GNU Triangulated Surface Library";

      longDescription = ''
        Library intended to provide a set of useful functions to deal with
        3D surfaces meshed with interconnected triangles.
      '';

      maintainers = [ stdenv.lib.maintainers.viric ];
      platforms = stdenv.lib.platforms.linux ++ stdenv.lib.platforms.darwin;
    };
  };

  bootstrap = stdenv.mkDerivation (drv { pname = "${name}-bootstrap"; } // stdenv.lib.optionalAttrs (cross) {
    configureFlags = [ "CC=${buildPackages.stdenv.cc}/bin/cc" ];
    postInstall = ''
      install -m 755 src/predicates_init $bin/bin/predicates_init
    '';
  });

in stdenv.mkDerivation (drv {} // stdenv.lib.optionalAttrs (cross) {
  postConfigure = ''
    substituteInPlace src/Makefile --replace './predicates_init' "${bootstrap.bin}/bin/predicates_init"
  '';
})
