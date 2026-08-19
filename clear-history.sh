history -c
rm -f ~/.bash_history ~/.zsh_history
rm -rf ~/.claude/projects
unset -f ff

if [ "$1" != "1" ]; then
  claude auth logout
  echo "zsh: command not found: ff"
fi

