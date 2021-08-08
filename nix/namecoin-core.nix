{ lib, stdenv, fetchFromGitHub, nix-gitignore, pkg-config, autoreconfHook }:

let
  additionalFilters = [ "*.nix" "nix/" "build/" ];
  filterSource = nix-gitignore.gitignoreSource additionalFilters;
  cleanedSource = filterSource ../.;
in stdenv.mkDerivation {
  pname = "namecoin-core";
  # TODO: find a better way to determine version, but it doesn't seem to be version controlled
  version = "0.21.1";

  src = cleanedSource;

  nativeBuildInputs = [ pkg-config autoreconfHook ];
  buildInputs = [ ];
}
