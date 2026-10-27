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
  NAMES=("Đặng Quốc Lai (VSF-KDL&AI-SPDL&AI)" "lai-2")
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

gits() {
    # One letter per file (M/A/D), relative to HEAD, regardless of staging.
    # Untracked files count as A.
    local list
    list=$({
        git diff HEAD --name-status --no-renames
        git ls-files --others --exclude-standard | sed 's/^/A\t/'
    } | sort -k2)

    # M yellow, A green, D red
    printf "%s\n" "$list" | sed '/^$/d' | awk -F'\t' '
        $1 == "M" { c = "\033[33m" }
        $1 == "A" { c = "\033[32m" }
        $1 == "D" { c = "\033[31m" }
        { printf "%s%s %s\033[0m\n", c, $1, $2 }'

    echo
    printf "Changed: %s | Added: %s | Deleted: %s\n" \
        "$(printf "%s\n" "$list" | grep -c '^M')" \
        "$(printf "%s\n" "$list" | grep -c '^A')" \
        "$(printf "%s\n" "$list" | grep -c '^D')"
}

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

# gitd: git diff with line numbers, red/green line bg, highlighted changed words
# _gitd_py: print the python renderer (shared by gitd and glogfile)
_gitd_py() {
  cat <<'PY'
import difflib
import re
import sys

RESET = "\033[0m"
DEL = "\033[48;5;52m"       # removed line bg
DEL_HI = "\033[48;5;124m"   # removed word bg
ADD = "\033[48;5;22m"       # added line bg
ADD_HI = "\033[48;5;28m"    # added word bg
HUNK = "\033[48;5;238;36m"  # hunk header
FILE = "\033[1;33m"
DIM = "\033[90m"
EL = "\033[K"               # fill the rest of the line with current bg

TOKEN = re.compile(r"\w+|\s+|[^\w\s]")
HUNK_RE = re.compile(r"^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@(.*)")


def num(n):
    return f"{n:>5}" if n is not None else "     "


def render(sign, text, base, hi, spans, o, n):
    out, pos = [], 0
    for a, b in spans:
        out.append(text[pos:a] + hi + text[a:b] + base)
        pos = b
    out.append(text[pos:])
    gutter = f"{DIM}{num(o)} {num(n)} {RESET}"
    return f"{gutter}{base}{sign} {''.join(out)}{EL}{RESET}"


def word_spans(old, new):
    a, b = TOKEN.findall(old), TOKEN.findall(new)
    sm = difflib.SequenceMatcher(None, a, b, autojunk=False)
    so, sn = [], []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            continue
        if i2 > i1:
            so.append((len("".join(a[:i1])), len("".join(a[:i2]))))
        if j2 > j1:
            sn.append((len("".join(b[:j1])), len("".join(b[:j2]))))
    return so, sn


def flush(dels, adds, o, n, out):
    paired = min(len(dels), len(adds))
    spans_d = [[] for _ in dels]
    spans_a = [[] for _ in adds]
    for k in range(paired):
        spans_d[k], spans_a[k] = word_spans(dels[k], adds[k])
    for k, t in enumerate(dels):
        out.append(render("-", t, DEL, DEL_HI, spans_d[k], o + k, None))
    for k, t in enumerate(adds):
        out.append(render("+", t, ADD, ADD_HI, spans_a[k], None, n + k))
    return o + len(dels), n + len(adds)


def main():
    out, dels, adds = [], [], []
    o = n = 0
    in_hunk = False
    for line in sys.stdin.read().split("\n"):
        if line.endswith("\r"):
            line = line[:-1]
        if in_hunk and line[:1] in ("-", "+"):
            (dels if line[0] == "-" else adds).append(line[1:])
            continue
        if dels or adds:
            o, n = flush(dels, adds, o, n, out)
            dels, adds = [], []
        m = HUNK_RE.match(line)
        if m:
            o, n, in_hunk = int(m[1]), int(m[2]), True
            out.append(f"{HUNK}{line}{EL}{RESET}")
        elif in_hunk and line.startswith(" "):
            out.append(f"{DIM}{num(o)} {num(n)} {RESET}  {line[1:]}")
            o, n = o + 1, n + 1
        elif line.startswith("diff --git"):
            in_hunk = False
            out.append(f"{FILE}{line}{RESET}")
        elif line.startswith(("--- ", "+++ ", "index ", "new file", "deleted file", "similarity", "rename")):
            out.append(f"{DIM}{line}{RESET}")
        elif line.startswith("\\"):
            out.append(f"{DIM}{line}{RESET}")
        else:
            out.append(line)
    if dels or adds:
        flush(dels, adds, o, n, out)
    sys.stdout.write("\n".join(out).rstrip("\n") + "\n")


try:
    main()
except BrokenPipeError:
    pass
PY
}

gitd() {
  git -c color.ui=never diff "$@" | python3 <(_gitd_py) | less -RFX
}
