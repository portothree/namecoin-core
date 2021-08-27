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
  wrapQtAppsHook ? null
  }:

with lib;
let
  additionalFilters = [ "*.nix" "nix/" "build/" ];
  filterSource = nix-gitignore.gitignoreSource additionalFilters;
  cleanedSource = filterSource ../.;
  qtbase = libsForQt5.qt5.qtbase;
  qttools = libsForQt5.qt5.qttools;
in stdenv.mkDerivation rec {
  pname = "namecoin-core";
  # TODO: find a better way to determine version, but it doesn't seem to be version controlled
  version = "0.21.1";

  src = cleanedSource;

  withWallet = true;
  withGui = true;
  withUpnp = false;
  withNatpmp = false;
  withHardening = true;

  nativeBuildInputs = [ pkg-config autoreconfHook boost ] 
    ++ optionals (withGui) [ wrapQtAppsHook ];

  buildInputs = [ python3 libtool libevent zeromq hexdump libsForQt5.qt5.qtbase]
    ++ optionals (withWallet) [ db48 sqlite ]
    ++ optionals (withUpnp) [ libupnp ]
    ++ optionals (withNatpmp) [ libnatpmp];

    configureFlags = optionals (!withGui) [ "--without-gui" ]
      ++ optionals (!withWallet) [ "--disable-wallet" ]
      ++ optionals (withUpnp) [ "--with-miniupnpc" "--enable-upnp-default" ]
      ++ optionals (withNatpmp) [ "--with-natpmp" "--enable-natpmp-default" ]
      ++ optionals (!withHardening) [ "--disable-hardening" ] 
      ++ optionals withGui [
        "--with-gui=qt5"
        "--with-qt-bindir=${qtbase.dev}/bin:${qttools.dev}/bin"
      ];

    configurePhase = ''
        ./autogen.sh
        ./configure --with-boost-libdir=${boost}/lib --prefix=$out
    '';

    buildPhase = '' make '';

    installPhase = '' make install '';

    postInstall = ''
        install -Dm644 bin/namecoin-qt $out/share/applications/namecoin-qt.desktop
    '';

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
