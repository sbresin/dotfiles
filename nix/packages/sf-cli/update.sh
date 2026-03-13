#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_NIX="$SCRIPT_DIR/default.nix"

# Fetch latest version + git short hash from npm registry
echo "Fetching latest sf-cli release from npm..."
NPM_META=$(curl -sf "https://registry.npmjs.org/@salesforce/cli/latest")
VERSION=$(echo "$NPM_META" | jq -r '.version')
GIT_HEAD=$(echo "$NPM_META" | jq -r '.gitHead')
SHORT_HASH="${GIT_HEAD:0:7}"

echo "Latest version: $VERSION (${SHORT_HASH})"

CURRENT=$(grep 'version = ' "$DEFAULT_NIX" | head -1 | grep -oP '"\K[^"]+')
if [[ "$VERSION" == "$CURRENT" ]]; then
  echo "Already up to date (v$VERSION)"
  exit 0
fi

# Construct the Salesforce CDN URL
URL="https://developer.salesforce.com/media/salesforce-cli/sf/versions/${VERSION}/${SHORT_HASH}/sf-v${VERSION}-${SHORT_HASH}-linux-x64.tar.xz"

# Verify URL is reachable
echo "Verifying download URL..."
HTTP_CODE=$(curl -sf -o /dev/null -w '%{http_code}' "$URL" || true)
if [[ "$HTTP_CODE" != "200" ]]; then
  echo "ERROR: CDN URL returned HTTP $HTTP_CODE — falling back to stable channel URL"
  URL="https://developer.salesforce.com/media/salesforce-cli/sf/channels/stable/sf-linux-x64.tar.xz"
  HTTP_CODE=$(curl -sf -o /dev/null -w '%{http_code}' "$URL" || true)
  if [[ "$HTTP_CODE" != "200" ]]; then
    echo "ERROR: Stable channel URL also unreachable (HTTP $HTTP_CODE)"
    exit 1
  fi
fi

# Prefetch to get the Nix SRI hash
echo "Prefetching tarball..."
SRI_HASH=$(nix-prefetch-url --type sha256 --unpack "$URL" 2>/dev/null | xargs nix hash convert --hash-algo sha256 --to sri)
echo "Hash: $SRI_HASH"

# Update default.nix via sed
sed -i "s|version = \".*\"|version = \"${VERSION}\"|" "$DEFAULT_NIX"
sed -i "s|url = \".*\"|url = \"${URL}\"|" "$DEFAULT_NIX"
sed -i "s|hash = \".*\"|hash = \"${SRI_HASH}\"|" "$DEFAULT_NIX"

echo "Updated sf-cli: v$CURRENT -> v$VERSION"
