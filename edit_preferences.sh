#!/usr/bin/env bash
#-------------------------------------------------------------------------
# Companion script to Plex_Server_Sync.sh
#
# https://github.com/007revad/Plex_Server_Sync
# Script verified at https://www.shellcheck.net/
#--------------------------------------------------------------------------

cd "$(dirname "$0")" || { echo "cd $(dirname "$0") failed!"; exit 1; }
#echo $PWD  # debug

if [[ ! -f Preferences.bak ]]; then
    echo "Preferences.bak not found! Aborting."
    exit 1
elif [[ ! -f Preferences.xml ]]; then
    echo "Preferences.xml not found! Aborting."
    exit 1
fi


# Assign Pref_keys string array
Pref_keys=("AnonymousMachineIdentifier" "CertificateUUID" "FriendlyName" "LastAutomaticMappedPort")
# Append more elements to the the array
Pref_keys+=("MachineIdentifier" "ManualPortMappingPort" "PlexOnlineToken" "ProcessedMachineIdentifier")

# Padding var for formatting
padding="                          "

# Get length of Pref_keys
Len=${#Pref_keys[@]}

# Get backup Preferences.bak file's ID values
echo -e "\nPreferences.bak"
declare -A Pref_bak
Num="0"
while [[ $Num -lt "$Len" ]]; do
    Pref_bak[$Num]=$(grep -oP "(?<=\b${Pref_keys[$Num]}=\").*?(?=(\" |\"/>))" "Preferences.bak")
    #echo "${Pref_keys[$Num]} = ${Pref_bak[$Num]}"
    echo "${Pref_keys[$Num]}${padding:${#Pref_keys[$Num]}} = ${Pref_bak[$Num]}"
    Num=$((Num +1))
done

# Get synced Preferences.xml file's ID values (so we can replace them)
echo -e "\nPreferences.xml"
declare -A Pref_new
Num="0"
while [[ $Num -lt "$Len" ]]; do
    Pref_new[$Num]=$(grep -oP "(?<=\b${Pref_keys[$Num]}=\").*?(?=(\" |\"/>))" "Preferences.xml")
    #echo "${Pref_keys[$Num]} = ${Pref_new[$Num]}"
    echo "${Pref_keys[$Num]}${padding:${#Pref_keys[$Num]}} = ${Pref_new[$Num]}"
    Num=$((Num +1))
done
echo

# Change synced Preferences.xml ID values to backed up ID values
changed=0
Num="0"
while [[ $Num -lt "$Len" ]]; do
    if [[ ${Pref_new[$Num]} ]] && [[ ${Pref_bak[$Num]} ]]; then
        if [[ ${Pref_new[$Num]} != "${Pref_bak[$Num]}" ]]; then
            echo "Updating ${Pref_keys[$Num]}"
            sed -i "s/ ${Pref_keys[$Num]}=\"${Pref_new[$Num]}/ ${Pref_keys[$Num]}=\"${Pref_bak[$Num]}/g" "Preferences.xml"
            changed=$((changed+1))
        fi
    fi
    Num=$((Num +1))
done


# VaapiDriver in Preferences.bak
VaapiDriver=$(grep -oP '(?<=\bVaapiDriver=").*?(?=(" |"/>))' "Preferences.bak")
echo -e "Back_VaapiDriver                = $VaapiDriver\n"

# VaapiDriver in Preferences.xml
Main_VaapiDriver=$(grep -oP '(?<=\bVaapiDriver=").*?(?=(" |"/>))' "Preferences.xml")
echo -e "Main_VaapiDriver                = $Main_VaapiDriver\n"

# VaapiDriver
if [[ $Main_VaapiDriver ]] && [[ $VaapiDriver ]]; then
    if [[ $Main_VaapiDriver != "$VaapiDriver" ]]; then
        #echo -e "Updating VaapiDriver\n"
        echo "Updating VaapiDriver"
        sed -i "s/ VaapiDriver=\"${Main_VaapiDriver}/ VaapiDriver=\"${VaapiDriver}/g" "Preferences.xml"
        changed=$((changed+1))
    else
        #echo -e "Same VaapiDriver already\n"
        echo "Same VaapiDriver already"
    fi
elif [[ $VaapiDriver ]]; then
    # Insert VaapiDriver="i965" or VaapiDriver="iHD" at the end, before />
    #echo -e "Adding VaapiDriver\n"
    echo "Adding VaapiDriver"
    sed -i "s/\/>/ VaapiDriver=\"${VaapiDriver}\"\/>/g" "Preferences.xml"
    changed=$((changed+1))
elif [[ $Main_VaapiDriver ]]; then
    # Delete VaapiDriver="i965" or VaapiDriver="iHD"
    #echo -e "Deleting VaapiDriver\n"
    echo "Deleting VaapiDriver"
    sed -i "s/ VaapiDriver=\"${Main_VaapiDriver}\"//g" "Preferences.xml"
    changed=$((changed+1))
fi


if [[ $changed -eq "1" ]]; then
    echo -e "\n$changed change made in Preferences.xml"
elif [[ $changed -gt "0" ]]; then
    echo -e "\n$changed changes made in Preferences.xml"
else
    echo -e "\nNo changes needed in Preferences.xml"
fi

exit

