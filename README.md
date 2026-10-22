# Load on ubuntu
Mỗi khi khởi động terminal mới, hãy chạy:

```bash
source ~/.local/data/mokraso-bash/alias.sh
source ~/.local/data/mokraso-bash/git-alias.sh
source ~/.local/data/mokraso-bash/fzf-alias.sh
```

> Lưu ý: `ff` được định nghĩa ở cả `alias.sh` (xóa history) và `fzf-alias.sh` (tìm file). File source sau sẽ ghi đè file trước.

# Hướng dẫn dùng

`[x]` = tùy chọn, `<x>` = bắt buộc.

## alias.sh

| Lệnh | Công dụng | Param |
|---|---|---|
| `cc` | `claude --dangerously-skip-permissions` | - |
| `yank` | Copy stdin vào clipboard (bỏ xuống dòng): `cmd \| yank` | - |
| `lmp3` | Phát ngẫu nhiên mp3 trong `$d/lai-2-temp` | - |
| `cu` | Vào custom ubuntu | - |
| `calc <expr>` | Tính biểu thức, in số dạng `1.234.567` | `calc 1500*3` |
| `lssm [n]` | SSM vào EC2 thứ n trong danh sách | `n` mặc định 1 |
| `snip` | Bật/tắt icon Snipaste trên tray | - |
| `epoch [ts]` | Đổi epoch (giây hoặc ms) sang UTC/UTC+7 | không truyền = hiện tại |
| `pyac [n]` | Activate venv: `.venv` ở thư mục hiện tại, không có thì venv mặc định | `n` = chọn venv theo số thứ tự |
| `ff` | Chạy `clear-history.sh` (xóa history, xóa session Claude) | - |

## git-alias.sh

| Lệnh | Công dụng | Param |
|---|---|---|
| `gitp` | Pull `origin` theo branch hiện tại | - |
| `gita "<msg>" [0]` | `add -A` + commit (ký GPG) + push. Chặn push `staging` và commit >10 file. CLAUDE.md bị bỏ qua trừ khi có `.git/allow-claude.log` | `<msg>` commit message; `0` = không push |
| `gitconfig [i]` | Set user/email/GPG key cho repo hiện tại | `i`: 0 = công ty, 1 = cá nhân (mặc định 1) |
| `gitb` | Copy tên branch hiện tại vào clipboard | - |
| `gits` | Status ngắn + thống kê changed/added/deleted | - |
| `gitc <0\|1\|-\|-b name\|branch>` | `0` main + pull, `1` staging + pull, `-` branch trước, `-b <name>` tạo branch mới, `<branch>` checkout | không param = in hướng dẫn |
| `gitd [args]` | `git diff` hiển thị 2 dòng cũ/mới, nền đỏ/xanh, tô đậm từ thay đổi, có số dòng | nhận mọi tham số của `git diff` (`--staged`, `<file>`...) |

## fzf-alias.sh

Cần: `fzf`, `git`, `bat` (tùy chọn), `docker`, `kubectl`. Phím chung: `alt-j`/`alt-k` cuộn preview, `ctrl-/` bật/tắt preview.

| Lệnh | Công dụng | Param |
|---|---|---|
| `ff` | Chọn file (có preview) rồi mở bằng `$EDITOR` | - |
| `fcd` | Chọn thư mục rồi `cd` | - |
| `gcof` | Chọn branch (local/remote) rồi switch | - |
| `glogf` | Duyệt commit toàn repo, Enter xem `git show` | - |
| `glogfile [file]` | Lịch sử 1 file (theo dõi cả đổi tên), preview diff cùng màu `gitd`. Enter xem commit, `ctrl-y` copy hash | `file`: không truyền thì chọn bằng fzf |
| `dlogs` | Chọn container rồi `docker logs -f` | - |
| `klogs` | Chọn pod rồi `kubectl logs -f` | - |
| `kns` | Chọn namespace rồi set cho context hiện tại | - |
