# i3 config backup

Bản backup/version-control cho cấu hình i3 window manager + polybar đang dùng trên máy (Ubuntu, session `i3.desktop` chạy qua GDM). Các file gốc nằm ở `~/.config/i3/`, `~/.config/polybar/` và `~/.xprofile`; nội dung ở đây là bản copy để track thay đổi.

## Cấu trúc & vai trò từng file

```
.
├── config                    # ~/.config/i3/config       - file cấu hình chính của i3
├── startup.sh                # ~/.config/i3/startup.sh   - script mở app theo workspace (không được gọi tự động)
├── monitor.sh                # ~/.config/i3/monitor.sh   - tự động cấu hình xrandr khi cắm/rút màn hình ngoài
├── xprofile                  # ~/.xprofile               - biến môi trường set khi bắt đầu X session
├── autostart/                # ~/.config/autostart/*.desktop - override tắt bớt autostart app dưới i3 (xem phần "Đã sửa" bên dưới)
│   ├── ibus.desktop
│   ├── autorandr.desktop
│   ├── im-launch.desktop
│   ├── com.cloudflare.WarpTaskbar.desktop
│   ├── solaar.desktop
│   ├── geoclue-demo-agent.desktop
│   ├── spice-vdagent.desktop
│   ├── ubuntu-advantage-notification.desktop
│   ├── update-notifier.desktop
│   └── ubuntu-report-on-upgrade.desktop
└── polybar/
    ├── config.ini            # ~/.config/polybar/config.ini      - cấu hình thanh bar (theme, module)
    ├── launch.sh             # ~/.config/polybar/launch.sh       - kill + relaunch polybar
    └── scripts/
        └── ibus.sh           # ~/.config/polybar/scripts/ibus.sh - hiện trạng gõ tiếng Việt (VI/EN) trên bar
```

### `config` (i3 main config)
File do `i3-config-wizard` sinh ban đầu rồi chỉnh tay. Các phần đáng chú ý:
- `set $mod Mod4` — phím mod là Super.
- Autostart (`exec`/`exec_always`):
  - `dex --autostart --environment i3` — chạy toàn bộ XDG autostart `.desktop` phù hợp môi trường `i3` (đã bớt tải, xem phần "Đã sửa để start nhanh hơn").
  - `xss-lock ... i3lock` — khoá màn hình khi suspend.
  - ~~`nm-applet`~~ — **đã bỏ**, vì `nm-applet.desktop` (autostart hệ thống) không loại trừ i3 nên `dex` đã tự chạy nó rồi; giữ dòng `exec` này chỉ khiến `nm-applet` bị spawn 2 lần mỗi lần login.
  - `ibus-daemon -drx` — khởi động bộ gõ tiếng Việt (Bamboo). Giờ là **nguồn khởi động ibus duy nhất** dưới i3 (xem bên dưới).
  - `~/.config/polybar/launch.sh` (`exec_always`) — bar.
  - `~/.config/i3/monitor.sh` (`exec_always`) — auto xrandr theo màn hình cắm ngoài.
  - 2 lệnh `xinput set-prop` (`exec_always`) — bật natural scrolling + tap-to-click cho touchpad ELAN.
- Keybindings chuẩn i3 (focus/move/split/resize/workspace 1-10) + `$mod+Return` mở `ghostty` thay vì terminal mặc định.
- `startup.sh` **không** được `exec` trong file này (dòng 216 bị comment) — tức nó chỉ chạy khi gọi tay.

### `startup.sh`
Script tiện ích để mở sẵn app theo từng workspace (terminal, firefox, zed, evolution) bằng `i3-msg`, có `sleep` giữa các bước. Hiện đang bị comment trong `config` nên không tự chạy lúc login.

### `monitor.sh`
Detect màn hình ngoài (`HDMI-1`) qua `xrandr`; nếu có thì bật HDMI làm primary và tắt màn laptop (`eDP-1`), nếu không thì chỉ bật laptop. Được gán vào cả `exec_always` (chạy mỗi lần i3 start/reload) và bind `$mod+Shift+d` để chạy tay.

### `xprofile`
Chỉ set `GTK_THEME=Yaru-dark` cho GTK app hiển thị đúng theme dark khi không chạy full GNOME session.

### `polybar/config.ini`
Theme Catppuccin-ish (`#1e1e2e` / `#cdd6f4` / `#89b4fa`). Bar `main` cao 28px, đặt top, modules trái: `i3 xwindow`; phải: `cpu memory network volume ibus date`. Module `network` hard-code interface `wlp0s20f3`. Module `ibus` là `custom/script` gọi `scripts/ibus.sh` mỗi giây.

### `polybar/launch.sh`
`killall polybar` rồi `polybar main &` — pattern chuẩn để tránh chạy trùng bar khi reload i3.

### `polybar/scripts/ibus.sh`
Đọc `ibus engine` hiện tại, in `VI` nếu là `Bamboo*`, `EN` nếu là `xkb:us*`, còn lại in `??`. Polybar poll script này mỗi giây để hiện trạng gõ trên bar.

## Vì sao i3 start lâu hơn GNOME?

Session i3 vào qua `i3.desktop` (GDM) chạy thẳng i3, **không** qua `gnome-session` — nên về lý thuyết phải khởi động nhanh hơn nhiều so với GNOME Shell. Review autostart thì nguyên nhân chính không nằm ở bản thân i3 mà ở **tầng autostart apps**:

1. **`dex --autostart --environment i3` kéo gần như toàn bộ autostart app của hệ thống**, vì hầu hết `.desktop` trong `/etc/xdg/autostart/` không có `OnlyShowIn=GNOME` hay `NotShowIn=i3` để loại trừ i3 (các `gsd-*`/GNOME Settings Daemon, gnome-keyring, tracker, orca thì có `OnlyShowIn=GNOME` nên **không** chạy dưới i3 — không phải thủ phạm). Thủ phạm thật là các app "phụ" vẫn lọt qua: `autorandr`, `im-launch`, `solaar`, `geoclue-demo-agent`, `spice-vdagent`, `update-notifier`, `ubuntu-advantage-notification`, `ubuntu-report-on-upgrade`, và **Cloudflare WARP taskbar** (`com.cloudflare.WarpTaskbar.desktop`, gọi `systemctl --user start warp-taskbar`).
2. **`dex` không có cơ chế phase/delay như `gnome-session`**: nhiều entry có `X-GNOME-Autostart-Delay=60` (vd. `update-notifier`, `ubuntu-advantage-notification`) — dưới GNOME chúng bị lùi lại 60s để không tranh tài nguyên lúc login, nhưng `dex` không đọc field này nên dưới i3 chúng chạy **ngay lập tức**, cộng dồn vào cùng lúc với mọi thứ khác.
3. **Xung đột/trùng lặp xrandr**: `autorandr.desktop` (`autorandr -c --default default`) chạy song song với `~/.config/i3/monitor.sh` (`exec_always` trong `config`) — cả hai cùng can thiệp xrandr gần như đồng thời lúc login.
4. **IBus từng bị khởi động tới 2-3 lần**: phát hiện `~/.config/autostart/ibus.desktop` (override cũ, không giới hạn môi trường) chạy `ibus-daemon -drx` — **y hệt** dòng `exec ibus-daemon -drx` trong `i3/config` — cộng thêm `im-launch.desktop` (autostart hệ thống) cũng có thể tự khởi động input method. Bamboo Vietnamese IME load hơi chậm nên bị start trùng vài lần là tốn thời gian thấy rõ.
5. **`nm-applet` bị spawn 2 lần**: vừa qua `nm-applet.desktop` (autostart hệ thống, không loại trừ i3) vừa qua dòng `exec nm-applet` khai báo tay trong `config`.

## Đã sửa để start nhanh hơn

`dex` (0.8.0) không có flag `--exclude`, nên cách chuẩn để tắt một autostart entry riêng cho i3 mà **không đụng tới GNOME session** là tạo file override cùng tên trong `~/.config/autostart/` (ghi đè file hệ thống ở `/etc/xdg/autostart/`) và thêm `NotShowIn=i3;`. Không dùng `Hidden=true` vì field đó tắt luôn cho *mọi* môi trường, kể cả khi login lại GNOME.

Đã tạo/sửa các override sau (nằm trong `autostart/` ở đây, bản gốc ở `~/.config/autostart/`):

| File | Xử lý | Lý do |
|---|---|---|
| `ibus.desktop` | thêm `NotShowIn=i3;` | trùng với `exec ibus-daemon -drx` trong `i3/config` → giờ chỉ còn 1 nguồn start ibus dưới i3 |
| `im-launch.desktop` | thêm `NotShowIn=i3;` | cũng có thể tự start input method, trùng với ibus-daemon ở trên |
| `autorandr.desktop` | thêm `NotShowIn=i3;` | trùng việc với `monitor.sh` (`exec_always`), tránh 2 lần probe xrandr |
| `com.cloudflare.WarpTaskbar.desktop` | thêm `NotShowIn=i3;` | chỉ là icon tray hiển thị trạng thái — **VPN thật (`warp-svc`) là system service, tự chạy độc lập, không phụ thuộc icon này**; icon hiện tại cũng không hiển thị dưới i3 nên tắt hẳn autostart, cần thì tự `systemctl --user start warp-taskbar` |
| `solaar.desktop` | thêm `NotShowIn=i3;` | chỉ là GUI quản lý receiver Logitech, chuột/bàn phím vẫn hoạt động bình thường không cần app này chạy nền |
| `geoclue-demo-agent.desktop` | thêm `NotShowIn=GNOME;i3;` | chỉ là demo agent định vị, không dùng tới |
| `spice-vdagent.desktop` | thêm `NotShowIn=i3;` | máy chạy bare-metal (`systemd-detect-virt` = none), không phải VM nên agent này vô dụng |
| `ubuntu-advantage-notification.desktop` | thêm `NotShowIn=i3;` | chỉ là thông báo, không ảnh hưởng chức năng |
| `update-notifier.desktop` | thêm `i3` vào `NotShowIn` | chỉ là thông báo có update, không ảnh hưởng chức năng |
| `ubuntu-report-on-upgrade.desktop` | thêm `NotShowIn=i3;` | chỉ chạy có ý nghĩa ngay sau khi upgrade release, không cần mỗi lần login |

Và trong `i3/config`:
- Bỏ dòng `exec --no-startup-id nm-applet` (đã có comment giải thích) — `dex` đã tự start nó qua `nm-applet.desktop`.
- Thêm comment ở dòng `dex --autostart` trỏ tới các override trên để lần sau biết vì sao thiếu mấy app đó.

**Không đổi**: `at-spi-dbus-bus` (bus accessibility, nhiều app GTK/Qt cần), `evolution-alarm-notify` (bạn có dùng Evolution — thấy trong `startup.sh`), `snap-userd-autostart`, `xdg-user-dirs*` — đều nhẹ hoặc thật sự cần thiết.

Đã test bằng `i3 -C -c ~/.config/i3/config` (hợp lệ) và `i3-msg reload` (thành công). Muốn thấy hiệu quả rõ nhất thì cần **logout/login lại** (hoặc reboot) vì phần lớn thay đổi nằm ở autostart lúc đăng nhập, không phải thứ `i3 reload` kích hoạt lại được.
