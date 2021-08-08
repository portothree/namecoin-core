final: prev: {
  namecoin-core = prev.callPackage ./namecoin-core.nix {};

  devShell = final.namecoin-core;
}
