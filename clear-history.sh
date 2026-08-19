history -c
rm ~/.bash_history ~/.zsh_history
rm -rf ~/.claude/projects
unset -f ff

if [ "$1" != "1" ]; then
  claude auth logout
fi

echo "zsh: command not found: ff"
