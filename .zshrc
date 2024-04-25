parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1/'
}
COLOR_DEF='%f'
COLOR_DIR='%F{27}'
COLOR_GIT='%F{76}'
setopt PROMPT_SUBST
export PROMPT='${COLOR_DIR}%1d${COLOR_DEF}${COLOR_GIT}$(parse_git_branch)${COLOR_DEF} $ '

source /Users/lai/.docker/init-zsh.sh || true # Added by Docker Desktop

dy()
{
  aws dynamodb scan --table-name $1 --endpoint-url=http://localhost:8001
}

killport()
{
kill -9 $(lsof -i:$1 -t) 2> /dev/null
}

autoload -U +X bashcompinit && bashcompinit
autoload -Uz compinit && compinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform

source ~/.aliases

export HOMEBREW_NO_AUTO_UPDATE=1

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/lai/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/lai/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/lai/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/lai/google-cloud-sdk/completion.zsh.inc'; fi

export PATH=/opt/homebrew/opt/mysql-client/bin:$PATH
export GPG_TTY=$(tty)
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_202.jdk/Contents/Home
