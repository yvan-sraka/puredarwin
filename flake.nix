{
  description = "PureDarwin development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
        isLinux = pkgs.stdenv.hostPlatform.isLinux;

        commonBuildInputs = with pkgs; [
          cmake
          ninja
          openssl
          zlib
          pkg-config
          python3
        ];

        linuxQemuInputs = with pkgs; [
          qemu
          curl
          xz
          p7zip
        ];

        mkPureDarwinShell = { name, extraPackages ? [], shellHookExtra ? "" }: pkgs.mkShell {
          inherit name;
          packages = commonBuildInputs ++ extraPackages;

          shellHook = ''
            export OPENSSL_ROOT_DIR="${pkgs.openssl.dev}"
            export ZLIB_ROOT="${pkgs.zlib.dev}"
            export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.zlib.dev}/lib/pkgconfig''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

            if [ "$(uname -s)" = "Darwin" ]; then
              if ! xcode-select -p >/dev/null 2>&1; then
                echo "warning: Xcode command-line tools not found; PureDarwin requires AppleClang from Xcode."
              fi
              echo "PureDarwin build shell (macOS)"
              echo "  nix develop"
              echo "  cmake -B build -G Ninja \\"
              echo "    -DOPENSSL_ROOT_DIR=$OPENSSL_ROOT_DIR \\"
              echo "    -DZLIB_ROOT=$ZLIB_ROOT"
            else
              echo "PureDarwin Linux shell"
              echo "  Full CMake builds require macOS + Xcode."
              echo "  Use the QEMU helpers to boot released images:"
              echo "    ./qemu/fetch-image.sh pd-17.4"
              echo "    ./qemu/run.sh pd-17.4"
            fi
            ${shellHookExtra}
          '';
        };
      in {
        devShells = {
          default = mkPureDarwinShell {
            name = "puredarwin";
            extraPackages = pkgs.lib.optionals isLinux linuxQemuInputs;
          };

          qemu = mkPureDarwinShell {
            name = "puredarwin-qemu";
            extraPackages = linuxQemuInputs;
            shellHookExtra = ''
              export PD_IMAGE_DIR="$PWD/qemu/images"
            '';
          };
        };

        apps = pkgs.lib.optionalAttrs isLinux {
          qemu-pd17 = {
            type = "app";
            program = toString (pkgs.writeShellScript "qemu-pd17" ''
              set -euo pipefail
              ROOT="$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || pwd)"
              exec "$ROOT/qemu/run.sh" pd-17.4 "$@"
            '');
          };
        };

        formatter = pkgs.nixpkgs-fmt;
      });
}
