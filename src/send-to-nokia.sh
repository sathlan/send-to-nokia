#! /usr/bin/env zsh
# File: send_to_nokia.sh
# Send a list of file to my nokia.  Note it doesn't support blancs in filename.

# By default the files arrive in "Fichiers reçus", which is on the
# phone memory.  From there I cannot traverse filesystem as in
# "..\\Mcard" (Mcard being the name I gave to my memory card).  But,
# when the phone memory is filled, the files are written directly to
# the memory card.  From there I can go in the desired subdirectory.
# But, by lack of unicity in those solution I prefer to "selece all
# files" in the phone and move them to the appropriate directory

# 1M = 2s
WAIT=.00000190734863281250

check_and_start ()
{
    if ! ps faux | grep -q "[/]$1"; then
        if [ -e /etc/rc.d/${1} ]; then
            sudo /etc/rc.d/${1} onestart
        else
            if [ -e /usr/local/etc/rc.d/${1} ]; then
                sudo /usr/local/etc/rc.d/${1} onestart
            else
                echo "Cannot find service $1" >&2
                exit 2
            fi
        fi
    fi
}

sanitize ()
{
    local orig_name="$1"
    echo -n "$orig_name" | perl -pe 's/\s+/_/g';
}

sudo sysctl dev.acpi_ibm.0.bluetooth=1
(
    check_and_start sdpd
    check_and_start hcsecd
    old_dir="$PWD"
    to_delete=""
    while [ "$#" -ne 0 ]; do
        cd "`dirname \"${1}\"`"
        fin_name="`sanitize \"$1\"`";
        [ ! -e "$fin_name" ] && ln "$1" "$fin_name"
        to_delete="$to_delete $fin_name"
        echo "put $fin_name $fin_name"
        shift
    done
    [ -n "$to_delete" ] && echo  $to_delete >/tmp/to-delete-$$
    cd "$old_dir"
    echo "dis"
) | obexapp -a nokia -C OPUSH
rm `cat /tmp/to-delete-$$`
rm /tmp/to-delete-$$
