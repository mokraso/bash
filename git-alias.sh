# ==============================
# Git helper functions
# ==============================

# gitp: pull from origin using current branch
gitp() {
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  if [[ -z "$branch" ]]; then
    echo "❌ Not a git repository"
    return 1
  fi

  git pull origin "$branch"
}

# ==============================
# gita function
# ==============================

# gita: add, commit, push with commit message
# check if CLAUDE.md file existed, then copy to .git folder
# after commit message, restore CLAUDE.md file

gita() {
  local message="$1"
  local push_flag="$2"
  local has_claude=false

  # -----------------------------
  # Find git root directory
  # -----------------------------
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "❌ Not in a git repository"
    return 1
  }

  local claude_file="$git_root/CLAUDE.md"
  local git_claude_file="$git_root/.git/CLAUDE.md"

  # -----------------------------
  # Handle push enable/disable
  # -----------------------------
  if [[ "$push_flag" == "0" ]]; then
    export TEMP_GIT_PUSH_ENABLED=false
  else
    export TEMP_GIT_PUSH_ENABLED=true
  fi

  # -----------------------------
  # Handle commit message
  # -----------------------------
  if [[ -n "$message" ]]; then
    export TEMP_GIT_COMMIT_MESSAGE="$message"
  elif [[ -z "$TEMP_GIT_COMMIT_MESSAGE" ]]; then
    echo "❌ Commit message is required"
    echo 'Usage: gita "your commit message" [0]'
    return 1
  fi

  # -----------------------------
  # Handle CLAUDE.md + Git operations
  # -----------------------------
  if [[ -f "$claude_file" ]]; then
    if [[ -f "$git_root/.git/allow-claude.log" ]]; then
      # allow-claude.log exists: commit CLAUDE.md as normal file
      echo "✓ Committing CLAUDE.md due to allow-claude.log present"
      git add -A || return 1
      git commit -S -m "$TEMP_GIT_COMMIT_MESSAGE" || return 1
    else
      # No allow-claude.log: move CLAUDE.md away, add/commit, then restore
      has_claude=true
      mv "$claude_file" "$git_claude_file" || {
        echo "❌ Failed to move CLAUDE.md into .git"
        return 1
      }
      git add -A || {
        mv "$git_claude_file" "$claude_file"
        return 1
      }
      git commit -S -m "$TEMP_GIT_COMMIT_MESSAGE" || {
        mv "$git_claude_file" "$claude_file"
        return 1
      }
      mv "$git_claude_file" "$claude_file"
    fi
  else
    # No CLAUDE.md: normal git add/commit
    git add -A || return 1
    git commit -S -m "$TEMP_GIT_COMMIT_MESSAGE" || return 1
  fi

  # -----------------------------
  # check push flag then push
  # -----------------------------
  if [[ "$TEMP_GIT_PUSH_ENABLED" == true ]]; then
    git push || return 1
  else
    echo "⚠️  git push skipped (TEMP_GIT_PUSH_ENABLED=false)"
  fi
}

gitconfig() {
  NAMES=("Đặng Quốc Lai (VSF-DL-NTDL)" "lai-2")
  EMAILS=("v.laidq@vinsmartfuture.tech" "laidq@outlook.com")
  GPGKEYS=("7C16AFE6C3BF3FBB" "33EADC8DEDE48179")
  COMMENTS=("git@gitlab.vinsmartfuture.tech:vsf-qtvhbds/ai-platform/" "PAT token")
  IDX=${1:-1}
  NAME=${NAMES[$IDX]}
  EMAIL=${EMAILS[$IDX]}
  GPGKEY=${GPGKEYS[$IDX]}
  COMMENT=${COMMENTS[$IDX]}

  FOLDER=$(basename "$PWD")

  if [ "$IDX" -eq 1 ]; then
    COMMENT="${COMMENT}${FOLDER}"
  fi

  git config user.name "$NAME"
  git config user.email "$EMAIL"
  git config user.signingkey "$GPGKEY"
  git config commit.gpgsign true

  echo "Set config for user $NAME <$EMAIL>"
  echo "GPG signing key: $GPGKEY"
  echo "Use remote here $COMMENT"
}

# copy git branch name
alias gitb='printf "%s" "$(git branch --show-current)" | xclip -selection clipboard'
