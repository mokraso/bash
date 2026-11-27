export d="$HOME/.local/data"

# claude code without confirm
alias cc='claude --dangerously-skip-permissions'

# yank to copy everything
alias yank='tr -d "\n" | xclip -selection clipboard'

# play music
alias lmp3='cvlc --random --extraintf rc --rc-fake-tty $d/lai-2-temp/*.mp3'

# enter to custom ubuntu
alias cu='$d/mokraso-bash/custom-ubuntu/start.sh'

calc() {
    python3 -c "print(f'{($*):,}'.replace(',', '.'))"
}

lssm() {
  # default index = 1 (zsh arrays are 1-indexed)
  local index="${1:-1}"
  # EC2 instance IDs
  local instances=(
    "i-02e81293870252d3d"  # gitlab runner tony
  )
  # validate index is a number
  if [[ ! "$index" =~ ^[0-9]+$ ]]; then
    echo "❌ Invalid index: $index (must be a number)"
    return 1
  fi
  # validate index range
  if (( index < 1 || index > ${#instances[@]} )); then
    echo "❌ Index out of range"
    echo "Available instances:"
    for i in {1..${#instances[@]}}; do
      echo "  [$i] ${instances[$i]}"
    done
    return 1
  fi
  local instance_id="${instances[$index]}"
  echo "🚀 Connecting to instance [$index]: $instance_id"
  aws ssm start-session --target "$instance_id"
}

snip() {
  local app="$HOME/.local/app/Snipaste-2.11.2-x86_64.AppImage"
  local config="$HOME/.snipaste/config.ini"

  # toggle hide_tray_icon trong config, rồi restart Snipaste để áp dụng
  if grep -q "^hide_tray_icon=true" "$config"; then
    sed -i 's/^hide_tray_icon=true/hide_tray_icon=false/' "$config"
    echo "Đang hiện icon Snipaste trên tray..."
  else
    sed -i 's/^hide_tray_icon=false/hide_tray_icon=true/' "$config"
    echo "Đang ẩn icon Snipaste trên tray..."
  fi

  pgrep -f "$app" > /dev/null && "$app" exit
  sleep 1
  "$app" > /dev/null 2>&1 &
  disown
}

epoch () {
    local input_ts=$1
    local ts
    local ts_ms

    # Không truyền timestamp -> lấy thời gian hiện tại
    if [ -z "$input_ts" ]; then
        ts=$(date +%s)
        ts_ms=$(date +%s%3N)
    else
        # Nếu >= 13 digits -> milliseconds
        if [ ${#input_ts} -ge 13 ]; then
            ts_ms=$input_ts
            ts=${input_ts:0:10}
        else
            ts=$input_ts
            ts_ms=$((ts * 1000))
        fi
    fi

    echo "UTC     : $(date -u -d @"$ts" "+%Y-%m-%d %H:%M:%S")"
    echo "UTC+7   : $(TZ=Asia/Ho_Chi_Minh date -d @"$ts" "+%Y-%m-%d %H:%M:%S")"
    echo "Epoch   : $ts"
    echo "Epoch ms: $ts_ms"
}

pyac () {
    local venvs
    venvs=("$HOME/.edata/core-ai-platform/.venv")

    # Case B: has parameter → use index
    if [[ -n "$1" ]]; then
        local idx=$1
        local venv_path="${venvs[$((idx-1))]}"

        if [[ -z "$venv_path" ]]; then
            echo "Invalid index (valid: 1-${#venvs[@]})"
            return 1
        fi
    else
        # Case A: no param → check local .venv first
        if [[ -d ".venv" ]]; then
            venv_path="$(pwd)/.venv"
        else
            venv_path="${venvs[0]}"
        fi
    fi

    local activate_file="$venv_path/bin/activate"

    if [[ ! -f "$activate_file" ]]; then
        echo "Activate file not found: $activate_file"
        return 1
    fi

    source "$activate_file"
    echo "Activated venv: $venv_path"
}

ff() {
  source "$HOME/.local/data/mokraso-bash/clear-history.sh"
}


# thống kê số container docker và RAM/CPU đang dùng
dstat() {
  local all stats ports
  all=$(docker ps -aq) || return 1
  stats=$(docker stats --no-stream --format 'S\t{{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.CPUPerc}}') || return 1
  ports=$(docker ps --format 'P\t{{.Names}}\t{{.Ports}}') || return 1

  # LC_NUMERIC=C: docker in số dạng "0.45", locale dùng dấu phẩy sẽ làm awk cắt mất phần thập phân
  printf '%s\n%s\n' "$ports" "$stats" | LC_NUMERIC=C awk -F'\t' -v total="$(printf '%s' "$all" | grep -c .)" '
    # "51.04MiB / 7.6GiB" -> 51.04
    function mib(s,    n, u) {
      sub(/ *\/.*/, "", s)
      n = s + 0
      u = s
      gsub(/[0-9. ]/, "", u)
      if (u == "GiB") return n * 1024
      if (u == "KiB") return n / 1024
      if (u == "B") return n / 1048576
      return n
    }
    # "0.0.0.0:8080->80/tcp, :::8080->80/tcp, 5432/tcp" -> "8080->80/tcp" (chỉ port publish ra host, bỏ trùng IPv4/IPv6)
    $1 == "P" {
      n = split($3, a, /, */); out = ""; delete seen
      for (k = 1; k <= n; k++) {
        if (a[k] !~ /->/) continue
        sub(/^.*:/, "", a[k])
        if (seen[a[k]]++) continue
        out = out (out ? ", " : "") a[k]
      }
      port[$2] = out
      next
    }
    $1 == "S" && NF == 5 {
      c++
      name[c] = $2; mem[c] = mib($3); memp[c] = $4 + 0; cpu[c] = $5 + 0
      summem += mem[c]; summemp += memp[c]; sumcpu += cpu[c]
      if (length($2) > w) w = length($2)
    }
    END {
      printf "Container: %d (đang chạy %d, đã dừng %d)\n", total, c, total - c
      if (!c) exit
      if (w < 9) w = 9
      row = "%-" w "s  %12s  %7s  %7s  %s\n"
      printf "\n" row, "NAME", "RAM", "RAM %", "CPU %", "PORTS"
      # nhiều RAM nhất lên đầu
      for (i = 1; i <= c; i++) {
        top = 0
        for (j = 1; j <= c; j++)
          if (!done[j] && (!top || mem[j] > mem[top])) top = j
        done[top] = 1
        printf row, name[top], sprintf("%.2f MiB", mem[top]), sprintf("%.2f%%", memp[top]), sprintf("%.2f%%", cpu[top]), (port[name[top]] != "" ? port[name[top]] : "-")
      }
      printf row, "TOTAL", sprintf("%.2f MiB", summem), sprintf("%.2f%%", summemp), sprintf("%.2f%%", sumcpu), ""
    }'
}

# xóa lịch sử chat claude code của TẤT CẢ project (giữ lại memory và các file/folder khác)
# usage: del        -> in danh sách mapping
#        del 1      -> xóa chat history của mọi project claude code
#        del 2      -> xóa Chrome history file
del() {
  # mapping: key (1-indexed) -> thư mục gốc chứa các project của claude code
  local dirs=(
    "$HOME/.claude/projects"
  )
  local chrome_history="/home/laidq/.config/google-chrome/Default/History"

  if [[ -z "$1" ]]; then
    echo "Usage: del <index>"
    echo "Available folders:"
    for i in {1..${#dirs[@]}}; do
      echo "  [$i] ${dirs[$i]}"
    done
    echo "  [2] $chrome_history"
    return 0
  fi

  if [[ "$1" == "2" ]]; then
    if [[ ! -f "$chrome_history" ]]; then
      echo "❌ File not found: $chrome_history"
      return 1
    fi
    rm -f "$chrome_history"
    echo "🧹 Deleted Chrome history: $chrome_history"
    return 0
  fi

  if [[ ! "$1" =~ ^[0-9]+$ ]] || (( $1 < 1 || $1 > ${#dirs[@]} )); then
    echo "❌ Invalid index: $1 (valid: 1-${#dirs[@]}, 2)"
    return 1
  fi

  local dir="${dirs[$1]}"
  if [[ ! -d "$dir" ]]; then
    echo "❌ Folder not found: $dir"
    return 1
  fi

  # trong mỗi project chỉ xóa: file *.jsonl (chat) và folder có tên là UUID (subagents, tool-results)
  # giữ lại: memory/ và mọi thứ khác
  find "$dir" -mindepth 2 -maxdepth 2 -type f -name '*.jsonl' -print -delete
  find "$dir" -mindepth 2 -maxdepth 2 -type d \
    -regextype posix-extended \
    -regex '.*/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' \
    -print -exec rm -rf {} +
  echo "🧹 Cleared chat history of all projects in [$1] $dir (kept memory & other files)"
}
