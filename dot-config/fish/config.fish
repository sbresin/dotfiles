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

# sf cli settings
set --export SF_DISABLE_TELEMETRY true # stop calling home
set --export SF_ORG_METADATA_REST_DEPLOY true # speed up deployments
set --export SF_IMPROVED_CODE_COVERAGE true # better coverage report

# zoxide setup
zoxide init fish | source

# starship setup
function starship_transient_prompt_func
    starship module character
end
function starship_transient_rprompt_func
    starship module time
end
starship init fish | source
enable_transience

# google cloud sdk
# source "$(brew --prefix)/share/google-cloud-sdk/path.fish.inc"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# if test -f /usr/local/Caskroom/miniforge/base/bin/conda
#     eval /usr/local/Caskroom/miniforge/base/bin/conda "shell.fish" "hook" $argv | source
# else
#     if test -f "/usr/local/Caskroom/miniforge/base/etc/fish/conf.d/conda.fish"
#         . "/usr/local/Caskroom/miniforge/base/etc/fish/conf.d/conda.fish"
#     else
#         set -x PATH "/usr/local/Caskroom/miniforge/base/bin" $PATH
#     end
# end
# <<< conda initialize <<<
