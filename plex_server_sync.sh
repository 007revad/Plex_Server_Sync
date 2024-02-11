#!/usr/bin/env bash
#-----------------------------------------------------------------------------
# Script to sync Plex server database & metadata to backup Plex server.
#
# It also syncs your settings, though you can disable this by adding the
# following to the included plex_rsync_exclude.txt
# Preferences.xml
#
# Requirements:
#   The script MUST be run on the device where the main Plex server is.
#   The following files must be in the same folder as Plex_Server_Sync.sh
#     1. plex_server_sync.config
#     2. plex_rsync_exclude.txt
#     3. edit_preferences.sh
#
# If you want to schedule this script to run as a user:
#  1. You need SSH keys setup so SCP and rsync can connect without passwords.
#  2. You also need your user to be able to sudo without a password prompt.
#
# https://github.com/007revad/Plex_Server_Sync
# Script verified at https://www.shellcheck.net/
#------------------------------------------------------------------------------

scriptver="v2.0.6"
script=Plex_Server_Sync
repo="007revad/Plex_Server_Sync"
scriptname=plex_server_sync

# Show script version
echo -e "$script $scriptver\n"


# Check if script is running in GNU bash and not BusyBox ash
Shell=$(/proc/self/exe --version 2>/dev/null | grep "GNU bash" | cut -d "," -f1)
if [ "$Shell" != "GNU bash" ]; then
    echo -e "You need to install bash to be able to run this script."
    echo -e "\nIf running this script on an ASUSTOR:"
    echo "1. Install Entware from App Central"
    echo "2. Run the following commands in a shell:"
    echo "opkg update && opkg upgrade"
    echo -e "opkg install bash\n"
    exit 1
fi


# Read variables from plex_server_sync.config
if [[ -f $(dirname -- "$0";)/plex_server_sync.config ]]; then
    # shellcheck disable=SC1090,SC1091
    while read -r var; do
        if [[ $var =~ ^[a-zA-Z0-9_]+=.* ]]; then export "$var"; fi
    done < "$(dirname -- "$0";)"/plex_server_sync.config
else
    echo "plex_server_sync.config file missing!"
    exit 1
fi


#src_Directory="/volume1/plex_test/AppData/Plex Media Server"             # test, delete later ##########
#dst_Directory="/volume1/plex_test/Library/Plex Media Server"             # test, delete later ##########

#dst_Directory="/volume1/plex_test/From DSM7"                             # test, delete later ##########


#-----------------------------------------------------
# Set date and time variables

# Timer variable to log time taken to sync PMS
start="${SECONDS}"

# Get Start Time and Date
Started=$( date )


#-----------------------------------------------------
# Set log file name

if [[ ! -d $LogPath ]]; then
    LogPath=$( dirname -- "$0"; )
fi
Log="$LogPath/$( date '+%Y%m%d')_Plex_Server_Sync.log"
if [[ -f $Log ]]; then
    # Include hh-mm if log file already exists (already run today)
    Log="$LogPath/$( date '+%Y%m%d-%H%M')_Plex_Server_Sync.log"
fi
ErrLog="${Log%.*}_ERRORS.log"

# Log header
CYAN='\e[0;36m'
WHITE='\e[0;37m'
echo -e "${CYAN}--- Plex Server Sync ---${WHITE}"  # shell only
echo -e "--- Plex Server Sync ---\n" 1>> "$Log"    # log only
echo -e "Syncing $src_IP to $dst_IP\n" |& tee -a "$Log"


#-----------------------------------------------------
# Initial checks

# Convert hostnames to lower case
src_IP=${src_IP,,}
dst_IP=${dst_IP,,}


if [[ -z $dst_SshPort ]]; then dst_SshPort=22; fi

if [[ ! $dst_SshPort =~ ^[0-9]+$ ]]; then
    echo "Aborting! Destination SSH Port is not numeric: $dst_SshPort" |& tee -a "$Log"
    exit 1
fi

Exclude_File="$( dirname -- "$0"; )/plex_rsync_exclude.txt"
if [[ ! -f $Exclude_File ]]; then
    echo -e "Aborting! Exclude_File not found: \n$Exclude_File"  |& tee -a "$Log"
    exit 1
fi

edit_preferences="$( dirname -- "$0"; )/edit_preferences.sh"
if [[ ! -f $edit_preferences ]]; then
    echo -e "Aborting! edit_preferences.sh not found: \n$edit_preferences"  |& tee -a "$Log"
    exit 1
fi

# Check script is running on the source device
host=$(hostname)  # for comparability
ip=$(ip route get 1 | sed 's/^.*src \([^ ]*\).*$/\1/;q')  # for comparability
if [[ $src_IP != "${host,,}" ]] && [[ $src_IP != "$ip" ]]; then
    echo "Aborting! Script is not running on source device: $src_IP"  |& tee -a "$Log"
    exit 1
fi

echo "Source:      $src_Directory" |& tee -a "$Log"
echo "Destination: $dst_Directory" |& tee -a "$Log"


if [[ ${Delete,,} != "yes" ]] && [[ ${Delete,,} != "no" ]]; then
    echo -e "\nDelete extra files on destination? [y/n]:" |& tee -a "$Log"
    read -r -t 10 answer
    if [[ ${answer,,} == y ]]; then
        Delete=yes
        echo yes 1>> "$Log"
    else
        echo no 1>> "$Log"
    fi
    answer=    
fi


if [[ ${DryRun,,} != "yes" ]] && [[ ${DryRun,,} != "no" ]]; then
    echo -e "\nDo a dry run test? [y/n]:" |& tee -a "$Log"
    read -r -t 10 answer
    if [[ ${answer,,} == y ]]; then
        DryRun=yes
        echo yes 1>> "$Log"
    else
        echo no 1>> "$Log"
    fi
    answer=    
fi


#-----------------------------------------------------
# Check host and destination are not the same

# This function is also used by PlexVersion function
Host2IP(){ 
    if [[ $2 == "remote" ]]; then
        # Get remote IP from hostname
        ip=$(ssh "${dst_User}@${1,,}" -p "$dst_SshPort"\
            "ip route get 1 | sed 's/^.*src \([^ ]*\).*$/\1/;q'")
    else
        # Get local IP from hostname
        ip=$(ip route get 1 | sed 's/^.*src \([^ ]*\).*$/\1/;q')
    fi
    echo "$ip"
}

# Check the source isn't also the target
if [[ $src_IP == "$dst_IP" ]]; then
    echo -e "\nSource and Target are the same!" |& tee -a "$Log"
    echo "Source: $src_IP" |& tee -a "$Log"
    echo "Target: $dst_IP" |& tee -a "$Log"
    exit 1
elif [[ $(Host2IP "$src_IP") == $(Host2IP "$dst_IP" remote) ]]; then
    echo -e "\nSource and Target are the same!"
    echo "Source: $src_IP"
    echo "Target: $dst_IP"
    exit 1
fi


#-----------------------------------------------------
# Get Plex version BEFORE we stop both Plex servers

# we can get the Plex version from Plex binary but location is OS dependant
# so we'll use the independent method (but it requires Plex to be running)

PlexVersion(){ 
    if [[ $2 == "remote" ]]; then
        ip=$(Host2IP "$1" remote)
    else
        ip=$(Host2IP "$1")
    fi
    if [[ $ip ]]; then
        # Get Plex version from IP address
        Response=$(curl -s "http://${ip}:32400/identity")
        ver=$(printf %s "$Response" | grep '" version=' | awk -F= '$1=="version"\
            {print $2}' RS=' ' | cut -d'"' -f2 | cut -d"-" -f1)
        echo "$ver"
    fi
    return
}

src_Version=$(PlexVersion "$src_IP")
echo -e "\nSource Plex version:      $src_Version" |& tee -a "$Log"

dst_Version=$(PlexVersion "$dst_IP" remote)
echo -e "Destination Plex version: $dst_Version\n" |& tee -a "$Log"

if [[ ! $src_Version ]] || [[ ! $dst_Version ]]; then
    echo "WARN: Unable to get one or both Plex versions." |& tee -a "$Log"
    echo "One or both servers may be stopped already." |& tee -a "$Log"
    echo "Are both Plex versions the same? [y/n]" |& tee -a "$Log"
    read -r answer
    if [[ ${answer,,} != y ]]; then
        echo no 1>> "$Log"
        exit 1
    else
        echo yes 1>> "$Log"
    fi
fi

# Check both versions are the same
if [[ $src_Version != "$dst_Version" ]]; then
    if [[ $answer != "y" ]]; then
        echo "Plex versions are different. Aborting." |& tee -a "$Log"
        echo -e "Source:      $src_Version \nDestination: $dst_Version" |& tee -a "$Log"
        exit 1
    fi
fi


#-----------------------------------------------------
# Plex Stop Start function

PlexControl(){ 
    if [[ $1 == "start" ]] || [[ $1 == "stop" ]]; then
        if [[ $2 == "local" ]]; then
            # stop or start local server
            if [[ $src_Docker == "yes" ]]; then
                if [[ ${src_OS,,} == "dsm7" ]] || [[ ${src_OS,,} == "dsm6" ]]; then
                # https://www.reddit.com/r/synology/comments/15h6dn3/how_to_stop_all_docker_containers_peacefully/
                    synowebapi --exec api=SYNO.Docker.Container method="$1" version=1 \
                        name="$src_Docker_plex_name" >/dev/null
                else
                    # docker stop results in "Docker container stopped unexpectedly" alert and email.
                    docker "$1" "$(docker ps -qf name=^"$src_Docker_plex_name"$)" >/dev/null
                fi
            else
                case ${src_OS,,} in
                    dsm7)
                        sudo /usr/syno/bin/synopkg "$1" PlexMediaServer >/dev/null
                        ;;
                    dsm6)
                        sudo /usr/syno/bin/synopkg "$1" "Plex Media Server"
                        ;;
                    adm)
                        sudo /usr/local/AppCentral/plexmediaserver/CONTROL/start-stop.sh "$1"
                        ;;
                    linux)
                        # UNTESTED
                        #sudo systemctl "$1" plexmediaserver
                        sudo service plexmediaserver "$1"
                        ;;
                    *)
                        echo "Unknown local OS type. Cannot $1 Plex." |& tee -a "$Log"
                        exit 1
                        ;;
                esac
            fi
        elif [[ $2 == "remote" ]]; then
            # stop or start remote server
            if [[ $src_Docker == "yes" ]]; then
                if [[ ${src_OS,,} == "dsm7" ]] || [[ ${src_OS,,} == "dsm6" ]]; then
                # https://www.reddit.com/r/synology/comments/15h6dn3/how_to_stop_all_docker_containers_peacefully/
                    ssh "${dst_User}@${dst_IP}" -p "$dst_SshPort" \
                        "sudo synowebapi --exec api=SYNO.Docker.Container method=$1 version=1" \
                            "name=$dst_Docker_plex_name" >/dev/null
                else
                    # docker stop results in "Docker container stopped unexpectedly" alert and email.
                    ssh "${dst_User}@${dst_IP}" -p "$dst_SshPort" \
                        "sudo docker $1 $(docker ps -qf name=^"$dst_Docker_plex_name"$)" >/dev/null
                fi
            else
                case ${dst_OS,,} in
                    dsm7)
                        ssh "${dst_User}@${dst_IP}" -p "$dst_SshPort" \
                            "sudo /usr/syno/bin/synopkg $1 PlexMediaServer" >/dev/null
                        ;;
                    dsm6)
                        ssh "${dst_User}@${dst_IP}" -p "$dst_SshPort" \
                            "sudo /usr/syno/bin/synopkg $1 Plex\ Media\ Server"
                        ;;
                    adm)
                        ssh "${dst_User}@${dst_IP}" -p "$dst_SshPort" \
                            "sudo /usr/local/AppCentral/plexmediaserver/CONTROL/start-stop.sh $1"
                        ;;
                    linux)
                        # UNTESTED
                        #ssh "${dst_User}@${dst_IP}" -p "$dst_SshPort" "sudo systemctl $1 plexmediaserver"
                        ssh "${dst_User}@${dst_IP}" -p "$dst_SshPort" "sudo service plexmediaserver $1"
                        ;;
                    *)
                        echo "Unknown remote OS type. Cannot $1 Plex." |& tee -a "$Log"
                        exit 1
                        ;;
                esac
            fi
        else
            echo "Invalid parameter #2: $2" |& tee -a "$Log"
            exit 1
        fi
        if [[ $1 == "stop" ]]; then
            sleep 5  # Give sockets a moment to close
        fi
    else
        echo "Invalid parameter #1: $1" |& tee -a "$Log"
        exit 1
    fi
    return
}


#-----------------------------------------------------
# Stop both Plex servers

echo "Stopping Plex on $src_IP" |& tee -a "$Log"
PlexControl stop local |& tee -a "$Log"
echo -e "\nStopping Plex on $dst_IP" |& tee -a "$Log"
PlexControl stop remote |& tee -a "$Log"
echo >> "$Log"


#-----------------------------------------------------
# Check both servers have stopped

# not the best way to get Plex status but other ways are OS dependant

abort=
if [[ $(PlexVersion "$src_IP") ]]; then
    echo "Source Plex $src_IP is still running!" |& tee -a "$Log"
    abort=1
fi
if [[ $(PlexVersion "$dst_IP" remote) ]]; then
    echo "Destination Plex $dst_IP is still running!" |& tee -a "$Log"
    abort=1
fi
if [[ $abort ]]; then
    echo "Aborting!" |& tee -a "$Log"
    exit 1
fi


#-----------------------------------------------------
# Backup destination Preferences.xml

# Backup Preferences.xml to Preferences.bak
ssh "${dst_User}@${dst_IP}" -p "$dst_SshPort" \
    "cp -u '${dst_Directory}/Preferences.xml' '${dst_Directory}/Preferences.bak'" |& tee -a "$Log"


#-----------------------------------------------------
# Sync source to destination with rsync

cd / || { echo "cd / failed!" |& tee -a "$Log"; exit 1; }
echo ""

# ------ rsync flags used ------
# --rsh destination shell to use
# -r recursive
# -l copy symlinks as symlinks
# -h human readable
# -p preserver permissions <-- FAILED to set permissions. Operation not permitted. Need to test more.
# -t preserve modification times
# -O don't keep directory's mtime (with -t)
# --progress              show progress during transfer
# --stats give some file-transfer stats
#
# ------ optional rsync flags ------
# --delete        delete extraneous files from destination dirs
# -n, --dry-run   perform a trial run with no changes made


# Unset any existing arguments
while [[ $1 ]]; do shift; done

if [[ ${DryRun,,} == yes ]]; then
    # Set --dry-run flag for rsync
    set -- "$@" "--dry-run"
    echo Running an rsync dry-run test |& tee -a "$Log"
fi
if [[ ${Delete,,} == yes ]]; then
    # Set --delete flag for rsync
    set -- "$@" "--delete"
    echo Running rsync with delete flag |& tee -a "$Log"
fi

# --delete doesn't delete if you have * wildcard after source directory path
rsync --rsh="ssh -p$dst_SshPort" -rlhtO "$@" --progress --stats \
    --exclude-from="$Exclude_File" "$src_Directory/" "$dst_IP":"$dst_Directory" |& tee -a "$Log"


#-----------------------------------------------------
# Restore unique IDs to destination's Preferences.xml

echo -e "\nCopying edit_preferences.sh to destination" |& tee -a "$Log"

if [[ $src_OS == DSM7 ]]; then
    # -O flag is required if DSM7 is the source or SCP defaults to SFTP
    sudo -u "$src_User" scp -O -P "$dst_SshPort" "$(dirname "$0")/edit_preferences.sh" \
        "$dst_User"@"$dst_IP":"'${dst_Directory}/'" |& tee -a "$Log"
else
    # Prepend spaces in destination path with \\ 
    spath=$(dirname "$0")
    sudo -u "$src_User" scp -P "$dst_SshPort" "${spath}/edit_preferences.sh" \
        "$dst_User"@"$dst_IP":"${dst_Directory// /\\ }/" |& tee -a "$Log"
fi

echo -e "\nRunning $dst_Directory/edit_preferences.sh" |& tee -a "$Log"
ssh "${dst_User}@${dst_IP}" -p "$dst_SshPort" "'${dst_Directory}/edit_preferences.sh'" |& tee -a "$Log"


#-----------------------------------------------------
# Start both Plex servers

echo -e "\nStarting Plex on $src_IP" |& tee -a "$Log"
PlexControl start local |& tee -a "$Log"
echo -e "\nStarting Plex on $dst_IP" |& tee -a "$Log"
PlexControl start remote |& tee -a "$Log"


#-----------------------------------------------------
# Check if there errors from rsync, scp or cp

if [[ -f $Log ]]; then
    tmp=$(awk '/^(rsync|cp|scp|\*\*\*|IO error).*/' "$Log")
    if [[ -n $tmp ]]; then
        echo "$tmp" >> "$ErrLog"
    fi
fi
if [[ -f $ErrLog ]]; then
    echo -e "\n${CYAN}Some errors occurred!${WHITE} See:"  # shell only
    echo -e "\nSome errors occurred! See:" >> "$Log"       # log only
    echo "$ErrLog" |& tee -a "$Log"
fi


#--------------------------------------------------------------------------
# Append the time taken to stdout

# End Time and Date
Finished=$( date )

# bash timer variable to log time taken
end="${SECONDS}"

# Elapsed time in seconds
Runtime=$(( end - start ))

# Append start and end date/time and runtime
echo -e "\nPlex Sync Started: " "${Started}" |& tee -a "$Log"
echo "Plex Sync Finished:" "${Finished}" |& tee -a "$Log"
# Append days, hours, minutes and seconds from $Runtime
printf "Plex Sync Duration: " |& tee -a "$Log"
printf '%dd:%02dh:%02dm:%02ds\n' \
    $((Runtime/86400)) $((Runtime%86400/3600)) $((Runtime%3600/60)) $((Runtime%60)) |& tee -a "$Log"
echo "" |& tee -a "$Log"


exit

