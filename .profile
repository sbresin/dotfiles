# if gsed is installed (macOS), use instead of builtin sed
if [[ -x "$(command -v gsed)" ]]; then
  alias sed="gsed"
fi

. "$HOME/.cargo/env"
