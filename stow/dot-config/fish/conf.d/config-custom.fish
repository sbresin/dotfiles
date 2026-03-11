set -g fish_greeting

if status is-interactive
    # Commands to run in interactive sessions can go here
end

# theme
fish_config theme choose "Rosé Pine"

# linux config path on macOS
set --export XDG_CONFIG_HOME "$HOME/.config"

# GNU coreutils in OSX
if test -x "$(command -v gsed)"
    alias sed="gsed"
end

if test -x "$(command -v gxargs)"
    alias xargs="gxargs"
end

# lazygit alias to use linux config path on macOS
# alias lazygit="lazygit -ucf ~/.config/lazygit/config.yml"
alias lg="lazygit -ucf ~/.config/lazygit/config.yml"

# delta default to side-by-side
# set --export DELTA_FEATURES "+side-by-side"

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# sf cli settings are set via home-manager (nix/modules/home/shell)


