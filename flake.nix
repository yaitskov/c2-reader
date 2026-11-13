{
  description = "A simple c2reader SPA built with Haskell and Miso";

  nixConfig = {
    extra-substituters = [
      "https://haskell-miso-cachix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "haskell-miso-cachix.cachix.org-1:m8hN1cvFMJtYib4tj+06xkKt5ABMSGfe8W7s40x1kQ0="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    miso.url = "github:dmjio/miso/1.15.0";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, miso }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells = {
          default = pkgs.mkShell {
            name = "The c2reader GHC WASM + HLS shell";
            inputsFrom = [
              miso.devShells.${system}.wasm
              miso.devShells.${system}.hls
            ];
            packages = [ pkgs.cabal-install ];
          };
          wasm = miso.devShells.${system}.wasm;
          ghcjs = miso.devShells.${system}.ghcjs;
          hls = miso.devShells.${system}.hls;
        };

        apps = let
          serve = {
            type = "app";
            program = toString (pkgs.writeShellScript "serve" ''
              exec ${pkgs.http-server}/bin/http-server public -p 8080 -c-1 --proxy http://localhost:8080?
            '');
            meta.description = "Serve the built c2reader on http://localhost:8080";
          };
        in {
          default = serve;
          inherit serve;
        };
      });
}
