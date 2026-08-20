echo y | history -c > /dev/null 2>&1
rm -f ~/.bash_history ~/.zsh_history
rm -rf ~/.claude/projects

if [ -z "$1" ]; then
  unset -f ff
  claude auth logout > /dev/null 2>&1
  echo "zsh: command not found: ff"
fi

