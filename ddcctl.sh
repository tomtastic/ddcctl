#!/bin/bash
# Control a monitor using ddcctl, using a state file as some monitors don't
# support reading current control settings.

ddcctl="/usr/local/bin/ddcctl"

# An LG display is at '1'
ddc_lg="$ddcctl -d 1"
# An HP display is at '2'
ddc_hp="$ddcctl -d 2"

poweroff() {
    # Power button will need pressing to power back on
    $ddc_lg -p 5
}

volmute() {
    # Set volume to 0 / mute
    newvol=0
    volume=$newvol
    $ddc_lg -v $newvol
}

voldown() {
    # Decrement the volume by one
    newvol=$((volume-1))
    # But dont be negative
    [[ $newvol -lt 0 ]] && newvol=0
    volume=$newvol
    $ddc_lg -v $newvol
}

volup() {
    # Increment the volume by one
    newvol=$((volume+1))
    # But cap at 30 so we dont damage anything
    [[ $newvol -gt 30 ]] && newvol=30
    volume=$newvol
    $ddc_lg -v $volume
}

dim() {
    $ddc_lg -b 42 -c 26
}

bright() {
    $ddc_lg -b 100 -c 75
}

up() {
    newb=$((brightness+10))
    [[ $newb -gt 100 ]] && newb=100
    brightness=$newb
    $ddc_lg -b $brightness
    #$ddc_lg -b $brightness -c 12+
}

down() {
    newb=$((brightness-10))
    [[ $newb -lt 0 ]] && newb=0
    brightness=$newb
    $ddc_lg -b $brightness
    #$ddc_lg -b 20- -c 12-
}

init() {
    state_file="$HOME/.ddc_control_state"
    if [[ ! -f $state_file ]]; then
        touch "$state_file"
        echo "Creating a new state file... ($state_file)"
    else
        # shellcheck source=/dev/null
        source "$state_file"
        echo "Reading state file... ($state_file)"
    fi

    if [[ -z "$volume" ]]; then
        volume=5
        echo "No state [volume]     (setting to $volume)"
    elif [[ -z "$brightness" ]]; then 
        brightness=42
        echo "No state [brightness] (setting to $brightness)"
    elif [[ -z "$contrast" ]]; then 
        contrast=70
        echo "No state [contrast]   (setting to $contrast)"
    fi
}

savestate() {
    echo "Saving state to file..."
    cat <<EOF > "$state_file"
export volume=$volume
export brightness=$brightness
export contrast=$contrast
EOF
}

case "$1" in
    dim|bright|up|down) init; $1; savestate;;
    volmute) init; $1;;
    voldown|volup) init; $1; savestate;;
    *)  #no scheme given, match local Hour of Day
        #HoD=$(date +%k) #hour of day
        #let "night = (( $HoD < 7 || $HoD > 16 ))" #daytime is 7a-4p
        #(($night)) && dim || bright
        ;;
esac

