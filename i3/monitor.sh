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
