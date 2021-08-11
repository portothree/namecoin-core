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
  libnatpmp
  }:

let
  additionalFilters = [ "*.nix" "nix/" "build/" ];
  filterSource = nix-gitignore.gitignoreSource additionalFilters;
  cleanedSource = filterSource ../.;
in stdenv.mkDerivation rec {
  pname = "namecoin-core";
  # TODO: find a better way to determine version, but it doesn't seem to be version controlled
  version = "0.21.1";

  src = cleanedSource;

  withWallet = true;
  withGui = false;
  withUpnp = false;
  withNatpmp = false;
  withHardening = true;

  nativeBuildInputs = [ pkg-config autoreconfHook boost] ; #wrapQtAppsHook qtbase

  buildInputs = [ python3 libtool libevent zeromq hexdump ]
    ++ lib.optionals (withWallet) [ db48 sqlite ]
    ++ lib.optionals (withUpnp) [ libupnp ]
    ++ lib.optionals (withNatpmp) [ libnatpmp];

    configureFlags = lib.optionals (!withGui) [ "--without-gui" ]
      ++ lib.optionals (!withWallet) [ "--disable-wallet" ]
      ++ lib.optionals (withUpnp) [ "--with-miniupnpc" "--enable-upnp-default" ]
      ++ lib.optionals (withNatpmp) [ "--with-natpmp" "--enable-natpmp-default" ]
      ++ lib.optionals (!withHardening) [ "--disable-hardening" ] ;

    configurePhase = ''
        ./autogen.sh
        ./configure --with-boost-libdir=${boost}/lib --prefix=$out
    '';

    buildPhase = '' make '';

    installPhase = '' make install '';

    qtWrapperArgs = [ ''--prefix PATH : $out/bin/namecoin-qt'' ];

    meta = {
      homepage = "https://namecoin.org";
      downloadPage = "https://namecoin.org/download";
      description = "a decentralized open source information registration and transfer system based on the Bitcoin cryptocurrency.";
    };
}
