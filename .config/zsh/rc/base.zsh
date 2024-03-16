HISTFILE="${ZDATADIR}/zsh_history"

command -v nvim

if command -v nvim >/dev/null 2>&1; then
  export EDITOR=${EDITOR:-nvim}
else
  export EDITOR=${EDITOR:-vim}
fi
