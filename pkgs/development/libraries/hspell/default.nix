{ stdenv, fetchurl, buildPackages, zlib }:

# hspell uses a couple of binaries it generates during it's own build.
# These will cause the build to fail later in cross-platform builds as
# these binaries have the wrong executable format.
# Using a hspell to bootstrap it's own build natively resolves this issue.

let
  upstream_name = "hspell";
  mkDrv = {
    pname ? upstream_name,
    version ? "1.1",
    sha256 ? "08x7rigq5pa1pfpl30qp353hbdkpadr1zc49slpczhsn0sg36pd6",
  }: rec {

    passthru = {
      pname = pname;
      version = version;
    };

    patchPhase = ''patchShebangs .'';
    preConfigure = stdenv.lib.optionalString (stdenv.hostPlatform != stdenv.buildPlatform) ''
      substituteInPlace Makefile.in --replace "ar cr" "${stdenv.lib.getBin stdenv.cc.bintools.bintools}/bin/${stdenv.cc.targetPrefix}ar cr"
      substituteInPlace Makefile.in --replace "ranlib" "${stdenv.lib.getBin stdenv.cc.bintools.bintools}/bin/${stdenv.cc.targetPrefix}ranlib"
      substituteInPlace Makefile.in --replace "STRIP=strip" "STRIP=${stdenv.lib.getBin stdenv.cc.bintools.bintools}/bin/${stdenv.cc.targetPrefix}strip"
    '';

    PERL_USE_UNSAFE_INC = "1";

    name = "${upstream_name}-${version}";
    src = fetchurl {
      url = "${meta.homepage}${name}.tar.gz";
      sha256 = sha256;
    };

    nativeBuildInputs = [ buildPackages.perl ];
    buildInputs = [ zlib ];

    meta = with stdenv.lib; {
      description = "Hebrew spell checker";
      homepage = "http://hspell.ivrix.org.il/";
      platforms = platforms.all;
      license = licenses.gpl2;
      maintainers = [ maintainers.kampka ];
    };
  };

  bootstrap = stdenv.mkDerivation (mkDrv{ pname = "hspell-bootstrap"; } // {
    nativeBuildInputs = [ buildPackages.perl ];
    configureFlags = [ "CC=${buildPackages.stdenv.cc}/bin/cc" ];
    postConfigure = ''
      substituteInPlace Makefile --replace "\$(STRIP)" "-\$(STRIP)"
    '';
    postInstall = ''
      install -m 755 ./find_sizes $out/bin
    '';
  });
in stdenv.mkDerivation (mkDrv{ } // stdenv.lib.optionalAttrs (stdenv.hostPlatform != stdenv.buildPlatform) {
  postConfigure = ''
      substituteInPlace Makefile --replace "./find_sizes" "${bootstrap}/bin/find_sizes"
  '';
})
