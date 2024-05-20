
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/lai/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/lai/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/lai/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/lai/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
export PATH=/opt/homebrew/bin:$PATH

export GPG_TTY=$(tty)

parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1/'
}
COLOR_DEF='%f'
COLOR_DIR='%F{27}'
COLOR_GIT='%F{76}'
setopt PROMPT_SUBST
export PROMPT='${COLOR_DIR}%1d${COLOR_DEF}${COLOR_GIT}$(parse_git_branch)${COLOR_DEF} $ '

source ~/.aliases
export HOMEBREW_NO_AUTO_UPDATE=1

export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

export WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'
autoload -Uz select-word-style
select-word-style normal

export PATH="/opt/homebrew/opt/openjdk/bin:/Users/lai/dbt-env/bin/:$PATH"
