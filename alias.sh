# claude code without confirm
alias cc='claude --dangerously-skip-permissions'

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

sql1 () {
  local ts output_file
  ts=$(date +"%Y%m%d_%H%M%S")
  output_file="/tmp/result_sql_count_${ts}.sql"

  awk '
    NF {
      gsub(/^[ \t]+|[ \t]+$/, "", $0)
      if ($0 != "") {
        printf "select '\''%s'\'' table_name, count(1) from %s union all\n", $0, $0
      }
    }
  ' > "$output_file"

  # bỏ union all cuối cùng
  sed -i '$ s/ union all$//' "$output_file"

  cat "$output_file"
  echo
  echo "cat $output_file"
}
