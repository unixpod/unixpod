#!/bin/bash
# openbox kit logout script


file=/etc/infortunerc
lines=$(($(cat $file | wc -l) -1))
line() {
  rand=$(($RANDOM%${lines}+1))
  frase=$(sed -n "${rand}p" ${file})
}
line
echo "$frase"

    gxmessage "${frase}" -center -title "Falow $USER, témais!!!" -font "Sans bold 10" -default "Cancel" -buttons "_Cancelar":1,"_Log out":2,"_Reboot":3,"_Shut down":4,"LockScreen":5 >/dev/null

    case $? in
        1)
            echo "Exit";;
        2)
            killall openbox;;
        3)
            sudo shutdown -r now;;
        4)
            sudo shutdown -h now;;
    5)
        i3lock -c 000000 -p win -b -n -i /usr/share/backgrounds/bglock.png;;
    esac
