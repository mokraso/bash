#!/bin/bash

# Tên màn hình (kiểm tra bằng: xrandr)
LAPTOP="eDP-1"      # Thay bằng tên màn hình laptop của bạn
EXTERNAL="HDMI-1"   # Thay bằng tên external screen của bạn

if xrandr | grep "$EXTERNAL connected"; then
    # External screen có kết nối
    xrandr --output $EXTERNAL --auto --primary \
           --output $LAPTOP --off
else
    # Chỉ có laptop screen
    xrandr --output $LAPTOP --auto --primary
fi

# Restart i3 để apply layout
# i3-msg restart

# i3 tự tạo workspace theo từng output đang active lúc khởi động
# (vd: ws1 -> eDP-1, ws2 -> HDMI-1). Khi script này tắt bớt 1 output,
# workspace của nó bị gộp sang output còn lại nhưng focus không đổi,
# nên hay bị kẹt ở workspace 2. Ép về workspace 1 để luôn nhất quán.
i3-msg 'workspace 1' >/dev/null 2>&1
