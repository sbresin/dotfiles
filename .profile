# if gsed is installed (macOS), use instead of builtin
if [[ -x "$(command -v gsed)" ]]; then
  alias sed="gsed"
fi

# if gxargs is installed (macOS), use instead of builtin
if [[ -x "$(command -v gxargs)" ]]; then
  alias xargs="gxargs"
fi

. "$HOME/.cargo/env"
