{
  inputs = {
    # https://hydra.nixos-cuda.org/project/nixos-cuda
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://azuwis.cachix.org"
      "https://cache.nixos-cuda.org"
    ];
    extra-trusted-public-keys = [
      "azuwis.cachix.org-1:194mFftt8RhaRjVyUrq8ttZCvYFwecVO+D5SC75d+9E="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };

  outputs =
    inputs@{ ... }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      eachSystem =
        f:
        inputs.nixpkgs.lib.genAttrs systems (
          system:
          let
            mkPkgs =
              {
                config ? { },
                overlays ? [ ],
              }:
              import inputs.nixpkgs {
                inherit system;
                config = {
                  allowUnfree = true;
                }
                // config;
                overlays = [
                  (final: prev: {
                    pianotrans = final.callPackage ./nix/pianotrans { };
                    python3Packages = prev.python3Packages.overrideScope (
                      pyfinal: pyprev: {
                        piano-transcription-inference = pyfinal.callPackage ./nix/piano-transcription-inference { };
                      }
                    );
                  })
                ]
                ++ overlays;
              };
          in
          f rec {
            inherit system;
            devshell = import inputs.devshell { nixpkgs = pkgs; };
            pkgs = mkPkgs { };
            pkgs-bin = mkPkgs {
              # torch-bin on Linux also reference cudaPackages, enable
              # cudaSupport to get cache hit on cache.nixos-cuda.org
              config.cudaSupport = pkgs.stdenv.hostPlatform.isLinux;
              overlays = [
                (final: prev: {
                  python3Packages = prev.python3Packages.overrideScope (
                    pyfinal: pyprev: {
                      torch = pyfinal.torch-bin;
                    }
                  );
                })
              ];
            };
            pkgs-cuda = mkPkgs {
              config.cudaSupport = true;
            };
            pkgs-rocm = mkPkgs {
              config.rocmSupport = true;
            };
          }
        );
    in
    {
      packages = eachSystem (
        {
          pkgs,
          pkgs-bin,
          pkgs-cuda,
          pkgs-rocm,
          ...
        }:
        let
          pianotrans = pkgs.pianotrans;
          wrapBlas =
            blas:
            pkgs.runCommand "pianotrans" { buildInputs = [ pkgs.makeWrapper ]; } ''
              makeWrapper ${pianotrans}/bin/pianotrans $out/bin/pianotrans \
                --set LD_PRELOAD "${blas}/lib/libblas.so"
            '';
        in
        {
          inherit pianotrans;
          default = pianotrans;
          pianotrans-bin = pkgs-bin.pianotrans;
          pianotrans-blis = wrapBlas pkgs.blis;
          pianotrans-amd-blis = wrapBlas pkgs.amd-blis;
          pianotrans-cuda = pkgs-cuda.pianotrans;
          pianotrans-mkl = wrapBlas pkgs.mkl;
          pianotrans-rocm = pkgs-rocm.pianotrans;
        }
      );

      devShells = eachSystem (
        {
          devshell,
          pkgs,
          pkgs-bin,
          pkgs-cuda,
          pkgs-rocm,
          ...
        }:
        let
          mkShell =
            {
              pkgs ? pkgs,
              blas ? null,
            }:
            devshell.mkShell (
              {
                packages = [
                  (pkgs.python.withPackages (ps: [
                    ps.piano-transcription-inference
                    ps.resampy
                    ps.tkinter
                  ]))
                  pkgs.ffmpeg
                ];
              }
              // (
                if blas != null then
                  {
                    env = [
                      {
                        name = "LD_PRELOAD";
                        value = "${blas}/lib/libblas.so";
                      }
                    ];
                  }
                else
                  { }
              )
            );
          shell = mkShell { };
        in
        {
          inherit shell;
          default = shell;
          shell-amd-blis = mkShell { blas = pkgs.amd-blis; };
          shell-bin = mkShell { pkgs = pkgs-bin; };
          shell-blis = mkShell { blas = pkgs.blis; };
          shell-cuda = mkShell { pkgs = pkgs-cuda; };
          shell-mkl = mkShell { blas = pkgs.mkl; };
          shell-rocm = mkShell { pkgs = pkgs-rocm; };
        }
      );
    };
}
