# nidome zsh hook (M0 prototype)
# Emits OSC 133 shell-integration markers around every command so the PTY
# wrapper (`nidome shell`) can cut the output stream into per-command chunks.
# When running under the wrapper (NIDOME_PTY=1) it also sends the command line
# and cwd through a private OSC that the wrapper strips before the terminal.
[[ -n ${__nidome_loaded-} ]] && return
typeset -g __nidome_loaded=1 __nidome_running=0

autoload -Uz add-zsh-hook

__nidome_preexec() {
  __nidome_running=1
  if [[ -n ${NIDOME_PTY-} ]]; then
    # BEL / ESC are dropped so they cannot terminate the payload early.
    # Parameter expansion only: no subshell fork on the hot path.
    print -rn -- $'\e]7771;nidome;cwd='"${${PWD//$'\a'/}//$'\e'/}"$'\a'
    print -rn -- $'\e]7771;nidome;cmd='"${${1//$'\a'/}//$'\e'/}"$'\a'
  fi
  print -rn -- $'\e]133;C\a'
}

__nidome_precmd() {
  local ret=$?
  if (( __nidome_running )); then
    print -rn -- $'\e]133;D;'"$ret"$'\a'
    __nidome_running=0
  fi
  print -rn -- $'\e]133;A\a'
}

add-zsh-hook preexec __nidome_preexec
add-zsh-hook precmd __nidome_precmd
