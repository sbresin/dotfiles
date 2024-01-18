set -g fish_greeting

if status is-interactive
    # Commands to run in interactive sessions can go here
end

# linux config path on macOS
set --export XDG_CONFIG_HOME "$HOME/.config"

# lazygit alias to use linux config path on macOS
# alias lazygit="lazygit -ucf ~/.config/lazygit/config.yml"
alias lg="lazygit -ucf ~/.config/lazygit/config.yml"

# delta default to side-by-side
set --export DELTA_FEATURES "+side-by-side"

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# sf cli settings
set --export SF_DISABLE_TELEMETRY true # stop calling home
set --export SF_ORG_METADATA_REST_DEPLOY true # speed up deployments
set --export SF_IMPROVED_CODE_COVERAGE true # better coverage report

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
