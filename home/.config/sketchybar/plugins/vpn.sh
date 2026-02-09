#!/bin/bash

HIGHLIGHT=0xff7aa2f7
DIM=0xff565f89

# F5 BIG-IP Edge Client: svpn daemon runs when tunnel is active
if pgrep -x svpn > /dev/null 2>&1; then
  sketchybar --set "$NAME" icon="󰌾" icon.color=$HIGHLIGHT label="VPN" label.color=$HIGHLIGHT
else
  sketchybar --set "$NAME" icon="󰌿" icon.color=$DIM label="" label.color=$DIM
fi
