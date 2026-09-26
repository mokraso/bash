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


gita() {
  local message="$1"
  local push_flag="${2:-1}" # default allow push
  # local push_flag="$2"

  local has_claude=false

  # -----------------------------
  # Prevent push to staging
  # -----------------------------
  local current_branch
  current_branch=$(git branch --show-current)

  if [[ "$current_branch" == "staging" && "$push_flag" != "0" ]]; then
    echo "❌ Push to 'staging' branch is not allowed"
    echo "   Use a feature branch and create a Merge Request instead."
    return 1
  fi

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
  # Check number of changed files
  # Must happen BEFORE git add/commit
  # -----------------------------
  local changed_file_count
  changed_file_count=$(
    git status --porcelain=v1 --untracked-files=all |
    wc -l
  )

  if (( changed_file_count > 10 )); then
    echo
    echo -e "\033[1;31m============================================================\033[0m"
    echo -e "\033[1;31m❌ COMMIT BLOCKED: $changed_file_count files are changed\033[0m"
    echo -e "\033[1;31m============================================================\033[0m"
    echo
    echo -e "\033[1;31mThis commit contains more than 10 files.\033[0m"
    echo -e "\033[1;31mFor safety, gita will NOT run git add, git commit, or git push.\033[0m"
    echo
    echo -e "\033[1;31mIf this large commit is intentional, run manually:\033[0m"
    echo
    echo "git add -A"
    if [[ -f "$claude_file" && ! -f "$git_root/.git/allow-claude.log" ]]; then
      echo "git reset CLAUDE.md"
    fi
    echo "git commit -m \"$TEMP_GIT_COMMIT_MESSAGE\""
    echo "git push"
    echo
    echo -e "\033[1;31mChanged files: $changed_file_count\033[0m"
    echo -e "\033[1;31m============================================================\033[0m"
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
  # Check push flag then push
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
alias gits='git status --short --untracked-files=all'

gitc() {
    case "$1" in
        0)
            git checkout main &&
            git pull origin main
            ;;

        1)
            git checkout staging &&
            git pull origin staging
            ;;

        -b)
            if [ -z "$2" ]; then
                echo "Usage: gitc -b <branch-name>"
                return 1
            fi

            git checkout -b "$2"
            ;;

        -)
            git checkout -
            ;;

        "")
            echo "Usage:"
            echo "  gitc 0                  # checkout main + pull"
            echo "  gitc 1                  # checkout staging + pull"
            echo "  gitc <branch>            # checkout existing branch"
            echo "  gitc -b <branch>         # create + checkout branch"
            echo "  gitc -                   # checkout previous branch"
            return 1
            ;;

        *)
            # Treat parameter as an existing branch name
            git checkout "$1"
            ;;
    esac
}
