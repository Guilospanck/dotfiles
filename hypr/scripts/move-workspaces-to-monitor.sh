#!/bin/bash

if hyprctl monitors | grep -q "HDMI-A-1"; then
  for i in 1 2 3 4; do
      hyprctl dispatch moveworkspacetomonitor "$i" HDMI-A-1
  done
else
  for i in 1 2 3 4; do
      hyprctl dispatch moveworkspacetomonitor "$i" eDP-1
  done
fi

