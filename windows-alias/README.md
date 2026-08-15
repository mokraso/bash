# windows-alias

Script/tiện ích dùng trên máy Windows.

## `install-git-claude.cmd`

Script one-click cài đặt các công cụ dev cần thiết trên Windows: **Git**, **Node.js LTS + npm**, **Claude Code CLI**, sau đó tự tạo **SSH key** cho Git.

Chạy bằng cách double-click file (tự elevate lên Administrator qua UAC nếu cần).

Luồng xử lý:
1. Tự request quyền Admin (`net session` check → nếu chưa có thì `Start-Process -Verb RunAs` để relaunch chính nó).
2. Kiểm tra `winget` có sẵn không (dùng để cài tự động).
3. Với từng tool (Git, Node.js, Claude Code CLI): tìm trong PATH và các đường dẫn cài đặt phổ biến trước, nếu không có thì cài qua `winget install` (riêng Claude Code CLI cài qua `npm install -g @anthropic-ai/claude-code`, cần Node/npm sẵn), rồi verify lại bằng cách dò executable thực tế (không tin PATH ngay sau khi cài).
4. In *FINAL REPORT* tổng hợp trạng thái (SUCCESS / ALREADY INSTALLED / FAILED) cho từng tool, kèm link tải thủ công nếu fail.
5. Generate SSH key (`~/.ssh/id_ed25519`, thuật toán `ed25519`, không passphrase) nếu chưa có sẵn — để dùng cho Git.
6. Ghi log toàn bộ quá trình vào `install-dev-tools.log` (cùng thư mục với script).

### Bug đã fix: SSH key generation không chạy

Script gọi thẳng lệnh `ssh-keygen` sau khi cài Git, nhưng **`ssh-keygen.exe` không nằm trong PATH được script thêm vào**. Git for Windows có 2 tầng binary:

- `Git\cmd\git.exe` / `Git\bin\git.exe` — đây là những gì script tìm và add vào PATH cho phần cài Git.
- `Git\usr\bin\` — chứa các tool MSYS2/OpenSSH thật (`ssh-keygen.exe`, `ssh.exe`, ...), **không** nằm trong `cmd\` hay `bin\`.

Vì vậy gọi bare `ssh-keygen` báo lỗi "not recognized" → nhánh `[FAILED] SSH key generation failed.` luôn bị trigger dù Git cài thành công.

Đã sửa: script giờ tự dò `ssh-keygen.exe` giống cách dò `git.exe`/`node.exe` (qua `where`, rồi tới `Git\usr\bin\ssh-keygen.exe` ở cả `%ProgramFiles%` và `%LocalAppData%\Programs`), rồi gọi bằng full path thay vì tên lệnh trần. Nếu vẫn không tìm thấy thì báo rõ nguyên nhân (thiếu OpenSSH trong bản Git đã cài) thay vì fail âm thầm. Cũng bỏ luôn `pause` bị lặp 2 lần ở cuối script.
