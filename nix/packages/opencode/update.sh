#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DEFAULT_NIX="$SCRIPT_DIR/default.nix"

# Fetch latest version from GitHub
echo "Fetching latest release..."
VERSION=$(gh api repos/anomalyco/opencode/releases/latest --jq .tag_name | sed 's/^v//')
echo "Latest version: $VERSION"

CURRENT=$(grep 'version = ' "$DEFAULT_NIX" | head -1 | grep -oP '"\K[^"]+')
if [[ "$VERSION" == "$CURRENT" ]]; then
  echo "Already up to date (v$VERSION)"
  exit 0
fi

# Prefetch source hash
echo "Prefetching source..."
SRC_HASH=$(nix flake prefetch --json "github:anomalyco/opencode/v${VERSION}" | jq -r .hash)
SRC_HASH=$(echo "$SRC_HASH" | tr -d '[:space:]')
echo "Source hash: $SRC_HASH"

# Compute node_modules hash by building just the FOD with a fake hash
# NOTE: We use a custom buildPhase that installs ALL deps (no --filter, no --production)
# because prettier is needed from root devDeps for generate.ts during build
echo "Computing node_modules hash..."
FAKE_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
SYSTEM=$(nix eval --raw --impure --expr builtins.currentSystem)

BUILD_OUTPUT=$(nix build -L --impure --no-link --expr "
let
  pkgs = (builtins.getFlake \"$FLAKE_DIR\").inputs.nixpkgs-unstable.legacyPackages.${SYSTEM};
  nm = pkgs.opencode.node_modules.overrideAttrs {
    outputHash = \"$FAKE_HASH\";
    src = pkgs.fetchFromGitHub {
      owner = \"anomalyco\";
      repo = \"opencode\";
      tag = \"v${VERSION}\";
      hash = \"${SRC_HASH}\";
    };
    version = \"${VERSION}\";
    # Install all deps including root devDeps (prettier needed for generate.ts during build)
    buildPhase = ''
      runHook preBuild

      export BUN_INSTALL_CACHE_DIR=\$(mktemp -d)

      bun install \\
        --cpu=\"*\" \\
        --force \\
        --frozen-lockfile \\
        --ignore-scripts \\
        --no-progress \\
        --os=\"*\"

      bun run ./nix/scripts/canonicalize-node-modules.ts
      bun run ./nix/scripts/normalize-bun-binaries.ts

      runHook postBuild
    '';
  };
in nm
" 2>&1) || true

NM_HASH=$(echo "$BUILD_OUTPUT" | grep -oP 'got: \Ksha256-[A-Za-z0-9+/]+=*' | head -1)

if [[ -z "$NM_HASH" ]]; then
  echo "ERROR: Could not extract node_modules hash from build output."
  echo "--- Full build output ---"
  echo "$BUILD_OUTPUT"
  echo "--- End build output ---"
  echo "Run 'nix build $FLAKE_DIR#sebe-opencode' manually and update nodeModulesHash."
  exit 1
fi
NM_HASH=$(echo "$NM_HASH" | tr -d '[:space:]')
echo "Node modules hash: $NM_HASH"

# Update default.nix
cat > "$DEFAULT_NIX" << 'NIXEOF'
{ pkgs, ... }:
let
  version = "VERSION_PLACEHOLDER";
  srcHash = "SRC_PLACEHOLDER";
  nodeModulesHash = "NM_PLACEHOLDER";
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
NIXEOF

sed -i "s|VERSION_PLACEHOLDER|$VERSION|" "$DEFAULT_NIX"
sed -i "s|SRC_PLACEHOLDER|$SRC_HASH|" "$DEFAULT_NIX"
sed -i "s|NM_PLACEHOLDER|$NM_HASH|" "$DEFAULT_NIX"

echo "Updated opencode: v$CURRENT -> v$VERSION"
