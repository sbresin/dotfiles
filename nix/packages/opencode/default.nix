{ pkgs, ... }:
let
  version = "1.17.7";
  srcHash = "sha256-rTeJuwqc11r6Xiksfg5IoTezK2ZtG3GlenQCxTW04P4=";
  nodeModulesHash = "sha256-UVRkdH3Csera41el/UKuh+HwqX0J26TQd8K20mzzEkg=";
in
pkgs.unstable.opencode.overrideAttrs (
  final: old: {
    inherit version;
    src = old.src.override {
      hash = srcHash;
    };
    node_modules = old.node_modules.overrideAttrs (nmFinal: nmOld: {
      outputHash = nodeModulesHash;
      # Install all deps including root devDeps (prettier needed for generate.ts during build)
      buildPhase = ''
        runHook preBuild

        export BUN_INSTALL_CACHE_DIR=$(mktemp -d)

        bun install \
          --cpu="*" \
          --force \
          --frozen-lockfile \
          --ignore-scripts \
          --no-progress \
          --os="*"

        bun run ./nix/scripts/canonicalize-node-modules.ts
        bun run ./nix/scripts/normalize-bun-binaries.ts

        runHook postBuild
      '';
    });

    # Use upstream build script instead of nixpkgs bundle.ts (which doesn't exist in newer versions)
    buildPhase = ''
      runHook preBuild

      # Copy node_modules, removing any existing symlinks first
      chmod -R u+w . || true
      rm -rf node_modules packages/*/node_modules
      cp -R ${final.node_modules}/. .
      chmod -R u+w .
      patchShebangs node_modules
      patchShebangs packages/*/node_modules

      cd ./packages/opencode
      bun --bun ./script/build.ts --single --skip-install --skip-embed-web-ui

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      install -Dm755 dist/opencode-*/bin/opencode $out/bin/opencode
      bun --bun ./script/schema.ts $out/share/opencode/schema.json

      runHook postInstall
    '';

    # The embedded native file watcher addon (.node) needs libstdc++ at runtime
    # via dlopen, but upstream packaging only sets PATH in the wrapper.
    postFixup = ''
      wrapProgram $out/bin/opencode \
        --prefix LD_LIBRARY_PATH : ${pkgs.unstable.stdenv.cc.cc.lib}/lib
    '';
  }
)
