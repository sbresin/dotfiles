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
cat > "$DEFAULT_NIX" << EOF
{pkgs, ...}:
let
  version = "$VERSION";
  srcHash = "$SRC_HASH";
  nodeModulesHash = "$NM_HASH";
in
pkgs.unstable.opencode.overrideAttrs (final: old: {
  inherit version;
  src = old.src.override {
    hash = srcHash;
  };
  node_modules = old.node_modules.overrideAttrs {
    outputHash = nodeModulesHash;
  };
})
EOF

echo "Updated opencode: v$CURRENT -> v$VERSION"
