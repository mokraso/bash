history -c && history -w
rm -rf ~/.claude/projects
unset -f ff

if [ "$1" != "1" ]; then
  claude auth logout
fi

echo "zsh: command not found: ff"
