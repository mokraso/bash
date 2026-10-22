# ============================================================
# fzf helpers
# Dependencies: fzf, fd, bat, git, docker, kubectl
# ============================================================

# ------------------------------------------------------------
# Check whether a command exists
# ------------------------------------------------------------
_fzf_require() {
    local cmd

    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            printf 'fzf: required command not found: %s\n' "$cmd" >&2
            return 1
        fi
    done
}


# ============================================================
# ff - Find and open a file
# ============================================================
ff() {
    _fzf_require fzf || return

    local file

    file=$(
        find . \
            -type f \
            -not -path './.git/*' \
            -print |
        fzf \
            --prompt='File > ' \
            --preview='
                if command -v bat >/dev/null 2>&1; then
                    bat --color=always --style=numbers --line-range=:200 {}
                else
                    sed -n "1,200p" {}
                fi
            '
    ) || return 0

    [[ -z "$file" ]] && return 0

    "${EDITOR:-vim}" "$file"
}


# ============================================================
# fcd - Find and cd into a directory
# ============================================================
fcd() {
    _fzf_require fzf || return

    local dir

    dir=$(
        find . \
            -type d \
            -not -path './.git/*' \
            -print |
        fzf --prompt='Directory > '
    ) || return 0

    [[ -z "$dir" ]] && return 0

    cd -- "$dir" || return
}


# ============================================================
# gcof - Interactive git branch checkout
# ============================================================
gcof() {
    _fzf_require fzf git || return

    # Make sure we are inside a Git repository.
    local repo_root

    repo_root=$(git rev-parse --show-toplevel) || {
        echo "gcof: not inside a Git repository" >&2
        return 1
    }

    local branch

    branch=$(
        git -C "$repo_root" branch \
            --all \
            --format='%(refname:short)' |
        grep -v '^HEAD -> ' |
        fzf \
            --prompt='Branch > ' \
            --preview="
                git -C '$repo_root' log \
                    --oneline \
                    --decorate \
                    --graph \
                    --color=always \
                    '{}' 2>&1
            " \
            --preview-window='right:60%' \
            --bind='alt-j:preview-down' \
            --bind='alt-k:preview-up' \
            --bind='ctrl-/:toggle-preview'
    ) || return 0

    [[ -z "$branch" ]] && return 0

    # Local branch
    if git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch"; then
        git switch -- "$branch"
        return
    fi

    # Remote branch
    if [[ "$branch" == origin/* ]]; then
        local local_branch="${branch#origin/}"

        if git -C "$repo_root" show-ref --verify --quiet "refs/heads/$local_branch"; then
            git switch -- "$local_branch"
        else
            git switch --track "$branch"
        fi

        return
    fi

    echo "gcof: branch not found: $branch" >&2
    return 1
}

# ============================================================
# glogf - Browse Git commits with diff preview
# ============================================================
glogf() {
    _fzf_require fzf git || return

    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        echo "glogf: not inside a Git repository" >&2
        return 1
    }

    local commit

    commit=$(
        git log \
            --all \
            --date-order \
            --pretty=format:'%h%x09%an%x09%ad%x09%s' \
            --date=format:'%Y-%m-%d %H:%M' |
        fzf \
            --prompt='Commit > ' \
            --delimiter=$'\t' \
            --preview='
                commit=$(printf "%s" {} | cut -f1)

                git show \
                    --color=always \
                    --stat \
                    -m --first-parent \
                    "$commit"

                printf "\n"

                git show \
                    --color=always \
                    --format=fuller \
                    -m --first-parent \
                    "$commit"
            ' \
            --preview-window='right:65%' \
            --bind='alt-j:preview-down' \
            --bind='alt-k:preview-up' \
            --bind='ctrl-/:toggle-preview' |
        cut -f1
    ) || return 0

    [[ -z "$commit" ]] && return 0

    git show -m --first-parent "$commit"
}

# ============================================================
# glogfile - Browse the history of a single file (follows renames)
# Usage: glogfile [file]   (no argument: pick a tracked file with fzf)
# Keys : enter = show commit patch for the file, ctrl-y = copy hash
# ============================================================
glogfile() {
    _fzf_require fzf git || return

    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        echo "glogfile: not inside a Git repository" >&2
        return 1
    }

    local file="$1"

    if [[ -z "$file" ]]; then
        file=$(
            git ls-files |
            fzf \
                --prompt='File > ' \
                --preview='
                    git log -5 --color=always \
                        --pretty=format:"%C(yellow)%h%Creset %C(green)%ad%Creset %s" \
                        --date=short -- {}
                '
        ) || return 0

        [[ -z "$file" ]] && return 0
    fi

    git log --follow --max-count=1 --format=%h -- "$file" 2>/dev/null |
        grep -q . || {
        echo "glogfile: no history for: $file" >&2
        return 1
    }

    # Same renderer as gitd (defined in git-alias.sh); fall back to plain git colors.
    local render="cat" renderer=""
    if typeset -f _gitd_py >/dev/null 2>&1; then
        renderer=$(mktemp) || return 1
        _gitd_py > "$renderer"
        render="python3 $renderer"
    fi

    local commit

    commit=$(
        git log --follow \
            --pretty=format:'%h%x09%an%x09%ad%x09%s' \
            --date=format:'%Y-%m-%d %H:%M' -- "$file" |
        fzf \
            --prompt="$file > " \
            --delimiter=$'\t' \
            --preview='
                commit=$(printf "%s" {} | cut -f1)

                {
                    git -c color.ui=never log --follow -p -1 --format=fuller "$commit" -- '"'$file'"'
                } | '"$render"'
            ' \
            --preview-window='right:65%' \
            --bind='alt-j:preview-down' \
            --bind='alt-k:preview-up' \
            --bind='ctrl-/:toggle-preview' \
            --bind='ctrl-y:execute-silent(printf "%s" {1} | xclip -selection clipboard)' |
        cut -f1
    ) || { rm -f "$renderer"; return 0; }

    [[ -z "$commit" ]] && { rm -f "$renderer"; return 0; }

    git -c color.ui=never log --follow -p -1 --format=fuller "$commit" -- "$file" |
        eval "$render" | less -RFX

    rm -f "$renderer"
}

# ============================================================
# dlogs - Select a Docker container and follow its logs
# ============================================================
dlogs() {
    _fzf_require fzf docker || return

    docker info >/dev/null 2>&1 || {
        echo "dlogs: Docker daemon is not available" >&2
        return 1
    }

    local container

    container=$(
        docker ps \
            --format '{{.Names}}\t{{.Image}}\t{{.Status}}' |
        fzf \
            --prompt='Container > ' \
            --delimiter=$'\t' \
            --with-shell=bash \
            --preview='
                name=$(printf "%s" {} | cut -f1)
                docker logs --tail 100 "$name" 2>&1
            ' |
        cut -f1
    ) || return 0

    [[ -z "$container" ]] && return 0

    docker logs -f "$container"
}


# ============================================================
# klogs - Select a Kubernetes pod and follow its logs
# ============================================================
klogs() {
    _fzf_require fzf kubectl || return

    kubectl cluster-info >/dev/null 2>&1 || {
        echo "klogs: Kubernetes cluster is not available" >&2
        return 1
    }

    local pod

    pod=$(
        kubectl get pods \
            --no-headers \
            -o custom-columns='NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName' |
        fzf \
            --prompt='Pod > ' \
            --delimiter=' ' \
            --preview='
                pod=$(printf "%s" {} | awk "{print \$1}")
                kubectl describe pod "$pod" 2>/dev/null
            ' |
        awk '{print $1}'
    ) || return 0

    [[ -z "$pod" ]] && return 0

    kubectl logs -f "$pod"
}


# ============================================================
# kns - Select and switch Kubernetes namespace
# ============================================================
kns() {
    _fzf_require fzf kubectl || return

    kubectl cluster-info >/dev/null 2>&1 || {
        echo "kns: Kubernetes cluster is not available" >&2
        return 1
    }

    local namespace

    namespace=$(
        kubectl get namespaces \
            --no-headers \
            -o custom-columns='NAME:.metadata.name,STATUS:.status.phase' |
        fzf \
            --prompt='Namespace > ' \
            --delimiter=' ' \
            --preview='
                ns=$(printf "%s" {} | awk "{print \$1}")
                kubectl get all -n "$ns" 2>/dev/null
            ' |
        awk '{print $1}'
    ) || return 0

    [[ -z "$namespace" ]] && return 0

    kubectl config set-context --current --namespace="$namespace"
}


# ============================================================
# Optional: fzf defaults
# ============================================================
if command -v fzf >/dev/null 2>&1; then
    export FZF_DEFAULT_OPTS="
        --height=60%
        --layout=reverse
        --border
        --info=inline
    "

    if command -v fd >/dev/null 2>&1; then
        # export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git' # remove fd app
        export FZF_DEFAULT_COMMAND='find . -type f -not -path "./.git/*"'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
    fi
fi
