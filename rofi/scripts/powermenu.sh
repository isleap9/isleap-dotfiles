#!/usr/bin/env bash

dir="$HOME/.config/rofi/powermenu/type-4"
theme='style-1'

uptime="$(uptime -p | sed -e 's/up //g')"

shutdown='󰐥'
reboot='󰜉'
lock='󰌾'
suspend='󰒲'
logout='󰍃'
yes='󰋊'
no='󰚌'

rofi_cmd() {
    rofi -dmenu \
        -p "Goodbye ${USER}" \
        -mesg "Uptime: $uptime" \
        -theme ${dir}/${theme}.rasi
}

confirm_cmd() {
    rofi -dmenu \
        -p 'Confirmation' \
        -mesg 'Are you Sure?' \
        -theme ${dir}/shared/confirm.rasi
}

confirm_exit() {
    echo -e "$yes\n$no" | confirm_cmd
}

run_rofi() {
    echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

run_cmd() {
    selected="$(confirm_exit)"
    if [[ "$selected" == "$yes" ]]; then
        if [[ $1 == '--shutdown' ]]; then
            systemctl poweroff
        elif [[ $1 == '--reboot' ]]; then
            systemctl reboot
        elif [[ $1 == '--suspend' ]]; then
            systemctl suspend
        elif [[ $1 == '--logout' ]]; then
            hyprctl dispatch exit
        fi
    else
        exit 0
    fi
}

chosen="$(run_rofi)"
if [[ -z "$chosen" ]]; then
    exit 0
fi

case ${chosen} in
    $shutdown)  run_cmd --shutdown ;;
    $reboot)    run_cmd --reboot ;;
    $lock)      blazinlock -s ;;
    $suspend)   run_cmd --suspend ;;
    $logout)    run_cmd --logout ;;
esac
