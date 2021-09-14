{
  lib,
  stdenv,
  fetchFromGitHub,
  nix-gitignore,
  pkg-config,
  autoreconfHook,
  boost,
  python3,
  libtool,
  libevent,
  zeromq,
  hexdump,
  db48,
  sqlite,
  libupnp,
  libnatpmp,
  libsForQt5,
  withWallet ? false,
  withGui ? true,
  withUpnp ? false,
  withNatpmp ? false,
  withHardening ? true
  }:

with lib;
let
  additionalFilters = [ "*.nix" "nix/" "build/" ];
  filterSource = nix-gitignore.gitignoreSource additionalFilters;
  cleanedSource = filterSource ../.;
  desktop = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/bitcoin-core/packaging/0.21/debian/bitcoin-qt.desktop";
    sha256 = "0cpna0nxcd1dw3nnzli36nf9zj28d2g9jf5y0zl9j18lvanvniha";
  };

  inherit (libsForQt5.qt5) qtbase qttools qmake wrapQtAppsHook;
in stdenv.mkDerivation rec {
  pname = "namecoin-core";
  # TODO: find a better way to determine version, but it doesn't seem to be version controlled
  version = "0.21.1";

  src = cleanedSource;

  nativeBuildInputs = [ pkg-config autoreconfHook boost wrapQtAppsHook ]
    ++ optionals (withGui) [ wrapQtAppsHook qmake ];

  buildInputs = [ python3 libtool libevent zeromq hexdump qtbase qttools ]
    ++ optionals (withWallet) [ db48 sqlite ]
    ++ optionals (withUpnp) [ libupnp ]
    ++ optionals (withNatpmp) [ libnatpmp];

    configureFlags = [ ]
      ++ optionals (!withGui) [ " --without-gui " ]
      ++ optionals (!withWallet) [ "--disable-wallet" "--without-bdb" ]
      ++ optionals (withUpnp) [ "--with-miniupnpc" "--enable-upnp-default" ]
      ++ optionals (withNatpmp) [ "--with-natpmp" "--enable-natpmp-default" ]
      ++ optionals (!withHardening) [ "--disable-hardening" ] 
      ++ optionals withGui [
        "--with-gui=qt5"
        "--with-qt-bindir=${qtbase.dev}/bin:${qttools.dev}/bin"
      ];

    configurePhase = ''
        ./autogen.sh
        ./configure --enable-cxx --without-bdb --disable-shared --prefix=${db48}/bin --with-boost=${boost} --with-boost-libdir=${boost}/lib --prefix=$out
    '';

    QT_PLUGIN_PATH = if withGui then "${qtbase}/${qtbase.qtPluginPrefix}" else null;
    LRELEASE = "${qttools.dev}/bin/lrelease";
    LUPDATE = "${qttools.dev}/bin/lupdate";
    LCONVERT = "${qttools.dev}/bin/lconvert";

    postConfigure = "make qmake_all";

    buildPhase = '' 
      make -j 4
    '';

    installPhase = '' make install '';

    postInstall = optionalString withGui ''
        install -Dm644 ${desktop} $out/share/applications/namecoin-qt.desktop
    '';
    
    qtWrapperArgs = [ ''--prefix PATH : ${placeholder "out"}/bin/namecoin-qt '' ];

    checkFlags =
        [ "LC_ALL=C.UTF-8" ]
        # QT_PLUGIN_PATH needs to be set when executing QT, which is needed when testing Bitcoin's GUI.
        # See also https://github.com/NixOS/nixpkgs/issues/24256
        ++ optional withGui "QT_PLUGIN_PATH=${qtbase}/${qtbase.qtPluginPrefix}";

    meta = {
      homepage = "https://namecoin.org";
      downloadPage = "https://namecoin.org/download";
      description = "a decentralized open source information registration and transfer system based on the Bitcoin cryptocurrency.";
    };
}
