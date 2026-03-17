# dotfiles task runner
# usage: just <recipe>          — run a recipe
#        just --list             — list all recipes
#        just update-pkg <name>  — update a single package

# ── Formatting & Validation ──────────────────────────────────────────

# format all nix files
fmt:
	nix fmt

# run flake checks
check:
	nix flake check

# ── Flake Updates ────────────────────────────────────────────────────

# update all flake inputs
update-flake:
	nix flake update

# update nixpkgs-unstable to newest rev where PACKAGES are cached
update-flake-cached +PACKAGES:
	nix-cached-update {{PACKAGES}}

# ── Package Updates ──────────────────────────────────────────────────

# snowfall-lib puts nix sources in a separate store path, so nix-update
# can't locate the file to patch. --override-filename fixes this.
# format: "attr:relative/path/to/file.nix"
_nix_update_pkgs := "chrome-devtools-mcp:nix/packages/chrome-devtools-mcp/package.nix docs-mcp-server:nix/packages/docs-mcp-server/package.nix sfp-cli:nix/packages/sfp-cli/default.nix rusty-psn:nix/packages/rusty-psn/default.nix oclif:nix/packages/oclif/default.nix razer-cli:nix/packages/razer-cli/default.nix es-de:nix/packages/es-de/default.nix apple-emoji-linux:nix/packages/apple-emoji-linux/default.nix"

# update a single package via nix-update (pass extra args after name)
[no-exit-message]
update-pkg PKG *ARGS:
	#!/usr/bin/env bash
	set -euo pipefail
	file="nix/packages/{{PKG}}/default.nix"
	[[ -f "nix/packages/{{PKG}}/package.nix" ]] && file="nix/packages/{{PKG}}/package.nix"
	nix-update "{{PKG}}" --flake --override-filename "$file" {{ARGS}}

# update opencode (custom script)
update-opencode:
	./nix/packages/opencode/update.sh

# update sf-cli (custom script)
update-sf-cli:
	./nix/packages/sf-cli/update.sh

# update all packages that support nix-update
[no-exit-message]
update-nix-update-pkgs:
	#!/usr/bin/env bash
	set -uo pipefail
	failed=()
	succeeded=()
	skipped=()
	for entry in {{_nix_update_pkgs}}; do
	    pkg="${entry%%:*}"
	    file="${entry#*:}"
	    echo "── updating $pkg ──"
	    if output=$(nix-update "$pkg" --flake --override-filename "$file" 2>&1); then
	        if echo "$output" | grep -q "No changes\|No update\|skipping"; then
	            skipped+=("$pkg")
	            echo "  skipped (up to date)"
	        else
	            succeeded+=("$pkg")
	            echo "  updated"
	        fi
	    else
	        failed+=("$pkg")
	        echo "  FAILED"
	        echo "$output" | tail -5 | sed 's/^/    /'
	    fi
	    echo
	done
	echo "══════════════════════════════════════"
	echo " results"
	echo "══════════════════════════════════════"
	[[ ${#succeeded[@]} -gt 0 ]] && echo " updated:    ${succeeded[*]}"
	[[ ${#skipped[@]}   -gt 0 ]] && echo " up to date: ${skipped[*]}"
	[[ ${#failed[@]}    -gt 0 ]] && echo " failed:     ${failed[*]}"
	echo "══════════════════════════════════════"
	[[ ${#failed[@]} -gt 0 ]] && exit 1 || exit 0

# update ALL packages (nix-update + custom scripts)
[no-exit-message]
update-packages:
	#!/usr/bin/env bash
	set -uo pipefail
	failed=()
	succeeded=()
	skipped=()
	# ── custom update scripts ──
	for entry in "opencode:./nix/packages/opencode/update.sh" "sf-cli:./nix/packages/sf-cli/update.sh"; do
	    pkg="${entry%%:*}"
	    script="${entry#*:}"
	    echo "── updating $pkg (custom) ──"
	    if output=$("$script" 2>&1); then
	        if echo "$output" | grep -qi "already up to date"; then
	            skipped+=("$pkg")
	            echo "  skipped (up to date)"
	        else
	            succeeded+=("$pkg")
	            echo "$output" | tail -1 | sed 's/^/  /'
	        fi
	    else
	        failed+=("$pkg")
	        echo "  FAILED"
	        echo "$output" | tail -5 | sed 's/^/    /'
	    fi
	    echo
	done
	# ── nix-update packages ──
	for entry in {{_nix_update_pkgs}}; do
	    pkg="${entry%%:*}"
	    file="${entry#*:}"
	    echo "── updating $pkg ──"
	    if output=$(nix-update "$pkg" --flake --override-filename "$file" 2>&1); then
	        if echo "$output" | grep -q "No changes\|No update\|skipping"; then
	            skipped+=("$pkg")
	            echo "  skipped (up to date)"
	        else
	            succeeded+=("$pkg")
	            echo "  updated"
	        fi
	    else
	        failed+=("$pkg")
	        echo "  FAILED"
	        echo "$output" | tail -5 | sed 's/^/    /'
	    fi
	    echo
	done
	echo "══════════════════════════════════════"
	echo " results"
	echo "══════════════════════════════════════"
	[[ ${#succeeded[@]} -gt 0 ]] && echo " updated:    ${succeeded[*]}"
	[[ ${#skipped[@]}   -gt 0 ]] && echo " up to date: ${skipped[*]}"
	[[ ${#failed[@]}    -gt 0 ]] && echo " failed:     ${failed[*]}"
	echo "══════════════════════════════════════"
	[[ ${#failed[@]} -gt 0 ]] && exit 1 || exit 0

# ── Build & Deploy ───────────────────────────────────────────────────

# rebuild NixOS system config
os *ARGS:
	nh os switch . {{ARGS}}

# rebuild home-manager config
home *ARGS:
	nh home switch . {{ARGS}}

# build a specific host without switching
build HOST:
	nix build '.#nixosConfigurations.{{HOST}}.config.system.build.toplevel'

# ── Stow ─────────────────────────────────────────────────────────────

# opencode is excluded from stow (via .stow-local-ignore) and symlinked
# as a directory so that its auto-installed node_modules resolves
# correctly for custom tool imports.
[private]
ensure-opencode-symlink:
	#!/usr/bin/env bash
	set -euo pipefail
	target="$HOME/.config/opencode"
	source="$HOME/workspace/dotfiles/stow/dot-config/opencode"
	if [[ -L "$target" ]]; then
		exit 0
	fi
	if [[ -d "$target" ]]; then
		echo "warning: replacing ~/.config/opencode directory with symlink"
		rm -rf "$target"
	fi
	ln -s "$source" "$target"

# symlink stow packages into $HOME
stow: ensure-opencode-symlink
	stow stow

# re-stow (prune dead symlinks + restow)
restow: ensure-opencode-symlink
	stow -R stow

# remove all stow symlinks
unstow:
	stow -D stow
	rm -f "$HOME/.config/opencode"
