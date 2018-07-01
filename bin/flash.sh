#!/usr/bin/env bash


# A tool to write iso images to USB devices
# Written by Nathaniel Maia, December 2017

# This program is provided free of charge and without warranty
# I ask that is you use the software and make changes
# that you contribute those changes to me <natemaia10@gmail.com>

############################################################
########## Variables

N="flashfire"
USAGE="\nUSAGE:\t$N [OPTIONS]...FILE
\nOPTIONS:\n\n\t-h, --help\t\tPrint this help message and exit
\n\t-t, --terminal\t\tAll output and input will be done via terminal
\n\t-f, --force\t\tIgnore warnings and final check before writing image
\n\t-n, --no-terminal\tForce running the GUI instead of terminal mode
\nEXAMPLES:\n\n\t$N --no-terminal\t\t\tForce GUI mode when run directly from a terminal
\n\t$N /path/to/something.iso\tSkip file selection and continue with device dialog
\n\t$N -t -f /path/to/something.iso\tForce terminal mode and skip warning dialogs
\n\nINFO:\n\n\tWith no args, run the iso selection dialog. Depending on whether run interactively
\tfrom a terminal or non-interactively from a launcher, keybind, or other shortcut
\tRun the GUI file selector will be run, or read input from terminal dialog\n"
DESKTOP_FILE="[Desktop Entry]\nVersion=1.0\nType=Application
Terminal=false\nIcon=usb-creator\nExec=flashfire\nCategories=GNOME;GTK;Utility;
Name=FlashFire Image Writer\nComment=Make a bootable USB stick"
TEMP="$HOME/.flashfire.desktop"
LAUNCHER="/usr/share/applications/flashfire.desktop"
ICON="--window-icon=usb-creator"
TITLE="FlashFire Image Writer"

##############################################################
########## Functions


# Catch arguments passed, if trying to set iso image, check file is an iso
# Override Terminal if needed, if we dont have stdin and dont have zenity/gksu, error exit
set_options() {
    for arg in "$@"; do
        case $arg in
            --help|-h)
                HELP="True"
                ;;
            --terminal|-t)
                TERMINAL="True"
                ;;
            --force|-f)
                FORCE="True"
                ;;
            --no-terminal|-n)
                TERMINAL="False"
                ;;
            *)
                for file in "$@"; do
                    if [[ -f "$file" ]] && [[ "$file" == *.iso ]]; then
                        ISO_IMAGE="$file" && break
                    fi
                done
        esac
    done
    if ! [[ -t 0 || -p /dev/stdin ]] && ! hash zenity gksu &>/dev/null; then
        echo -e "\nTo run the GUI please make sure you have the following installed\n\n\t'zenity'\t'gksu'"
        exit 1
    elif ! [[ -t 0 || -p /dev/stdin ]] || [[ $TERMINAL = "False" ]] && hash zenity gksu &>/dev/null; then
        unset TERMINAL
    elif [[ -t 0 || -p /dev/stdin ]]; then
        TERMINAL="True"
    fi
}


# clean values everytime this is called
# detect available USB devices, less than 64Gb adding them to a few arrays for later
prep_arrays() {
    unset DEVICES DEVICE_ARRAY NAME_ARRAY PRETTY_DEVICES TERM_PRETTY_DEVICES
    DETECTED=($(awk '{print $2}' <<< $(grep 'usb' <<< $(lsblk -lno TRAN,NAME))))
    for device in "${DETECTED[@]}"; do
        while read -r size; do
            size=${size%.*}
            if ! grep -q "$device" <<< "${DEVICE_ARRAY[@]}" && ! [[ $size -gt 64 ]]; then
                DEVICE_ARRAY+=("$device")
            fi
        done <<< "$(sed 's/[GM]//g' <<< $(awk '{print $2}' <<< $(grep "$device" <<< $(lsblk -lno NAME,SIZE))))"
    done
    NAMES=($(awk -NF'_' '{print $1}' <<< $(sed 's/.*usb-\(.*\)-[0-9]:.*/\1/' <<< $(ls /dev/disk/by-id/usb))))
    for name in "${NAMES[@]}"; do
        if ! grep -q "$name" <<< "${NAME_ARRAY[@]}"; then
            NAME_ARRAY+=("$name")
        fi
    done
    for ((x=0; x<${#DEVICE_ARRAY[@]}; x++)); do
        PRETTY_DEVICES="$PRETTY_DEVICES FALSE ${DEVICE_ARRAY[$x]}-${NAME_ARRAY[$x]}"
        TERM_PRETTY_DEVICES="$TERM_PRETTY_DEVICES\n ${DEVICE_ARRAY[$x]}\t${NAME_ARRAY[$x]}"
    done
    clear
}


# If not passed a valid iso file path initially open the file selection dialog, filtered for .iso files
# Determine block size to use when writing if we cant get it set, fall back to using 2048 block size
choose_iso() {
    if ! [[ $ISO_IMAGE ]] && [[ $TERMINAL = "True" ]]; then
        unset ISOS
        clear
        for x in $HOME/*; do
            if [[ -d $HOME/$x ]]; then
                ISOS+=($(find "$HOME/$x/" -name '*.iso'))
            fi
        done
        clear; echo -e "\n\nEnter path to an iso file below.. 0 or n/N to Exit\nBelow are some iso files found\n"
        for iso in "${ISOS[@]}"; do
            echo -e "\t$iso"
        done
        printf "\nIso: "; read -r IMAGE
        if grep -q '[nN0]' <<< "$ISO_IMAGE"; then
            clear; exit 0
        elif ! [[ -f $IMAGE ]] || ! [[ $IMAGE == *.iso ]]; then
            echo -e "\nPlease Enter a Valid Path to an Existing ISO\n"; sleep 3
            choose_iso
        else
            ISO_IMAGE="$IMAGE"
        fi
    elif ! [[ $ISO_IMAGE ]]; then
        ISO_IMAGE=$(zenity --title="$TITLE" $ICON --file-selection --filename="$PWD/" --file-filter=".iso | *.iso")
        if [[ $? == 1 ]]; then exit 0; fi
    fi

    # ISO_BLOCK_SIZE=$(sed 's/[^0-9]//g' <<< "$(grep 'block size' <<< "$(isoinfo -d -i "$ISO_IMAGE")")")
    # if grep -q 'ARCH LINUX' <<< "$(isoinfo -d -i "$ISO_IMAGE")"; then
    #     BLOCK_SIZE="4096"
    # elif [[ $ISO_BLOCK_SIZE ]]; then
    #     BLOCK_SIZE="$ISO_BLOCK_SIZE"
    # else
    #     BLOCK_SIZE="2048"
    # fi

    BLOCK_SIZE="4096"
}


# give user list of available usb devices smaller that 64G
# if there is only one device, instead skip this, and assign the available drive
choose_device() {
    # Get values from outer function
    prep_arrays

    # If there is more than one device detected
    # open the device selection dialog
    if [[ ${#DEVICE_ARRAY[@]} -gt 1 ]] && [[ $TERMINAL = "True" ]]; then
        clear && echo -e "\nEnter USB device name below in sdX format\nThese are the available devices
        \n${TERM_PRETTY_DEVICES[*]}"
        printf "\n:  " && read -r USB_STICK
        if ! grep -qox '[a-z][a-z][a-z]' <<< "$USB_STICK"; then
            clear && echo -e "\nWrong formatting..
            \nPlease make sure to enter 3 lower case letters eg. sdc"
            sleep 3 && clear && choose_device
        fi
    elif [[ ${#DEVICE_ARRAY[@]} -gt 1 ]]; then
        USB_STICK=$(zenity --list --radiolist $ICON --width=350 --height=350 --title="$TITLE" \
            --text="<big><b>Select USB Device</b></big>\nOnly usb devices smaller than 64Gb will be listed\n" \
            --column="Select" --column="Device" $PRETTY_DEVICES)
        if [[ $? == 1 ]]; then
            exit 0
        elif ! [[ "$USB_STICK" ]]; then
            SURE=$(zenity $ICON --title="$TITLE" --question --width=350 --height=150 \
                --ok-label="Go Back" $ICON --cancel-label="Exit" \
                --text="<big><b>No Device Selected</b></big>\n\nWhat would you like to do?" &>/dev/null)
            if [[ $? == 1 ]]; then
                exit 0
            else
                choose_device
            fi
        else
            USB_STICK=$(sed 's/-[a-zA-Z].*//g' <<< "$USB_STICK")
        fi
    elif [[ ${#DEVICE_ARRAY[@]} -eq 1 ]]; then
        USB_STICK="${DEVICE_ARRAY[0]}"
    else
        if [[ $TERMINAL = "True" ]]; then
            echo -e "\nNo available device for writing... Exiting\n"
        else
            zenity --info --width=350 $ICON --title="$TITLE" \
                --text="<big><b>No Available Devices Found</b></big>\n\nPlease connect a USB drive\n" &>/dev/null &
        fi
        exit 0
    fi
}


# Last chance to go back
# skipped if passed the --force option
write_image() {
    if [[ $TERMINAL = "True" ]]; then
        if ! [[ $FORCE ]] || [[ ${#DEVICE_ARRAY[@]} -eq 1 ]]; then
            if [[ ${#DEVICE_ARRAY[@]} -gt 1 ]]; then
                TEXT="\n[WARNING]: All data on /dev/$USB_STICK will be destroyed
                \n\nDo you want to Continue?  [y/N]: "
            else
                TEXT="\n[WARNING]: There is only one available device
                \n[WARNING]: All data on /dev/$USB_STICK will be destroyed\n\n\nDo you want to Continue?  [y/N]: "
            fi
            clear
            printf "%s" "$TEXT"
            read -r SURE
            if ! grep -q '[yY]' <<< "$SURE"; then
                clear && exit 0
            fi
        fi
        (
        clear && echo -e "\nPlease wait while the image is written\n"
        sudo dd bs="$BLOCK_SIZE" if="$ISO_IMAGE" of="/dev/$USB_STICK" status=progress conv=sync
        )
        echo -e "\n\tImage Written Successfully\n"
    else
        if ! [[ $FORCE ]] || [[ ${#DEVICE_ARRAY[@]} -eq 1 ]]; then
            if [[ ${#DEVICE_ARRAY[@]} -gt 1 ]]; then
                TEXT="\t\t<big><b>WARNING</b></big>
                \nAll data on: <b>/dev/${USB_STICK}</b> will be destroyed\n\nDo you want to continue?"
            else
                TEXT="\t\t<big><b>WARNING</b></big>
                \nThere is one available device: <b>/dev/${USB_STICK}</b>\nAll data on it will be destroyed
                \nDo you want to continue?"
            fi
            zenity --question --title="$TITLE" --width=350 --text="$TEXT" &>/dev/null
            if [[ $? == 1 ]]; then
                exit 0
            fi
        fi
        (
        gksu dd bs="$BLOCK_SIZE" if="$ISO_IMAGE" of="/dev/$USB_STICK" status=progress conv=sync
        ) | zenity --progress --pulsate $ICON --title="$TITLE" --no-cancel --width=350 --height=100 \
            --text="\nWriting image to the USB...\nPlease Wait\n" --auto-close &>/dev/null

        zenity --info --width=350 $ICON --title="$TITLE" \
            --text="<big><b>Process Complete</b></big>\n\nThe image was written to the device" &>/dev/null
    fi
}


##############################################################
########## Run Script

# Catch args, if asking help, print usage and exit
set_options "$@"
if [[ $HELP ]] && [[ $TERMINAL = "True" ]]; then
    echo -e "$USAGE" && exit 0
elif [[ $HELP ]]; then
    zenity --info $ICON --width=700 --height=600 --title="$TITLE" --text="$USAGE" &>/dev/null & exit 0
fi

# Make desktop file for easier launching
if ! [[ -f $LAUNCHER ]]; then
    clear && echo -e "\nGenerating .desktop file..\n"
    echo -e "$DESKTOP_FILE" > "$TEMP"
    if [[ $TERMINAL = "True" ]]; then
        sudo dd bs=2048 if="$TEMP" of="$LAUNCHER"
    else
        gksu dd bs=2048 if="$TEMP" of="$LAUNCHER"
    fi
    [[ -e $TEMP ]] && rm -f "$TEMP"
fi

# make sure everything is set
choose_iso
choose_device

# If everything is set up, write the image
if [[ $USB_STICK ]] && [[ $ISO_IMAGE ]]; then
    write_image
fi

exit 0
