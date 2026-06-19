#!/usr/bin/env bash
# Update FastFlowLM and regenerate Cargo.lock
set -euo pipefail
cd "$(dirname "$0")/../../.."

latest=$(git ls-remote --tags --sort=-v:refname https://github.com/FastFlowLM/FastFlowLM.git \
  | grep -oP 'refs/tags/v\K[0-9]+\.[0-9]+\.[0-9]+$' | head -1)

current=$(grep -oP "version = \"\K[^\"]*" nix/packages/fastflowlm/package.nix)

if [[ "$latest" == "$current" ]]; then
  echo "fastflowlm: already up to date ($current)"
  exit 0
fi

echo "fastflowlm: $current -> $latest"

# Update version and hash
sed -i "s|version = \"$current\"|version = \"$latest\"|" nix/packages/fastflowlm/package.nix
nix-update fastflowlm --flake --override-filename nix/packages/fastflowlm/package.nix --version=skip

# Regenerate Cargo.lock from new source
src=$(nix eval --raw ".#fastflowlm.src" 2>/dev/null)
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
cp -r "$src/third_party/tokenizers-cpp/rust/"* "$tmpdir/"
chmod -R u+w "$tmpdir"
cargo generate-lockfile --manifest-path "$tmpdir/Cargo.toml" 2>/dev/null
cp "$tmpdir/Cargo.lock" nix/packages/fastflowlm/Cargo.lock

echo "fastflowlm updated to $latest (Cargo.lock regenerated)"
