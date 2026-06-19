#!/usr/bin/env bash
# Update XRT and xrt-plugin-amdxdna (they share the same version tag)
set -euo pipefail
cd "$(dirname "$0")/../../.."

latest=$(git ls-remote --tags --sort=-v:refname https://github.com/Xilinx/XRT.git \
  | grep -oP 'refs/tags/\K[0-9]+\.[0-9]+\.[0-9]+$' | head -1)

current=$(grep -oP "version = \"\K[^\"]*" nix/packages/xrt/package.nix)

if [[ "$latest" == "$current" ]]; then
  echo "xrt: already up to date ($current)"
  exit 0
fi

echo "xrt: $current -> $latest"

# Update XRT
sed -i "s|version = \"$current\"|version = \"$latest\"|" nix/packages/xrt/package.nix
nix-update xrt --flake --override-filename nix/packages/xrt/package.nix --version=skip

# Update xrt-plugin-amdxdna (same version tag from amd/xdna-driver)
sed -i "s|version = \"$current\"|version = \"$latest\"|" nix/packages/xrt-plugin-amdxdna/package.nix
nix-update xrt-plugin-amdxdna --flake --override-filename nix/packages/xrt-plugin-amdxdna/package.nix --version=skip

echo "xrt + xrt-plugin-amdxdna updated to $latest"
