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


# Get backup Preferences.bak file's ID values
echo -e "\nBackup File: Preferences.bak"
AnonymousMachineIdentifier=$(grep -oP '(?<=\bAnonymousMachineIdentifier=").*?(?=(" |"/>))' "Preferences.bak")
echo "Back_AnonymousMachineIdentifier = $AnonymousMachineIdentifier"
CertificateUUID=$(grep -oP '(?<=\bCertificateUUID=").*?(?=(" |"/>))' "Preferences.bak")
echo "Back_CertificateUUID            = $CertificateUUID"
FriendlyName=$(grep -oP '(?<=\bFriendlyName=").*?(?=(" |"/>))' "Preferences.bak")
echo "Back_FriendlyName               = $FriendlyName"
LastAutomaticMappedPort=$(grep -oP '(?<=\bLastAutomaticMappedPort=").*?(?=(" |"/>))' "Preferences.bak")
echo "Back_LastAutomaticMappedPort    = $LastAutomaticMappedPort"
MachineIdentifier=$(grep -oP '(?<=\bMachineIdentifier=").*?(?=(" |"/>))' "Preferences.bak")
echo "Back_MachineIdentifier          = $MachineIdentifier"
ManualPortMappingPort=$(grep -oP '(?<=\bManualPortMappingPort=").*?(?=(" |"/>))' "Preferences.bak")
echo "Back_ManualPortMappingPort      = $ManualPortMappingPort"
PlexOnlineToken=$(grep -oP '(?<=\bPlexOnlineToken=").*?(?=(" |"/>))' "Preferences.bak")
echo "Back_PlexOnlineToken            = $PlexOnlineToken"
ProcessedMachineIdentifier=$(grep -oP '(?<=\bProcessedMachineIdentifier=").*?(?=(" |"/>))' "Preferences.bak")
echo "Back_ProcessedMachineIdentifier = $ProcessedMachineIdentifier"
# VaapiDriver
VaapiDriver=$(grep -oP '(?<=\bVaapiDriver=").*?(?=(" |"/>))' "Preferences.bak")
echo -e "Back_VaapiDriver                = $VaapiDriver\n"


# Get synced Preferences.xml file's ID values (so we can replace them)
echo "Main File: Preferences.xml"
Main_AnonymousMachineIdentifier=$(grep -oP '(?<=\bAnonymousMachineIdentifier=").*?(?=(" |"/>))' "Preferences.xml")
echo "Main_AnonymousMachineIdentifier = $Main_AnonymousMachineIdentifier"
Main_CertificateUUID=$(grep -oP '(?<=\bCertificateUUID=").*?(?=(" |"/>))' "Preferences.xml")
echo "Main_CertificateUUID            = $Main_CertificateUUID"
Main_FriendlyName=$(grep -oP '(?<=\bFriendlyName=").*?(?=(" |"/>))' "Preferences.xml")
echo "Main_FriendlyName               = $Main_FriendlyName"
Main_LastAutomaticMappedPort=$(grep -oP '(?<=\bLastAutomaticMappedPort=").*?(?=(" |"/>))' "Preferences.xml")
echo "Main_LastAutomaticMappedPort    = $Main_LastAutomaticMappedPort"
Main_MachineIdentifier=$(grep -oP '(?<=\bMachineIdentifier=").*?(?=(" |"/>))' "Preferences.xml")
echo "Main_MachineIdentifier          = $Main_MachineIdentifier"
Main_ManualPortMappingPort=$(grep -oP '(?<=\bManualPortMappingPort=").*?(?=(" |"/>))' "Preferences.xml")
echo "Main_ManualPortMappingPort      = $Main_ManualPortMappingPort"
Main_PlexOnlineToken=$(grep -oP '(?<=\bPlexOnlineToken=").*?(?=(" |"/>))' "Preferences.xml")
echo "Main_PlexOnlineToken            = $Main_PlexOnlineToken"
Main_ProcessedMachineIdentifier=$(grep -oP '(?<=\bProcessedMachineIdentifier=").*?(?=(" |"/>))' "Preferences.xml")
echo "Main_ProcessedMachineIdentifier = $Main_ProcessedMachineIdentifier"
# VaapiDriver
Main_VaapiDriver=$(grep -oP '(?<=\bVaapiDriver=").*?(?=(" |"/>))' "Preferences.xml")
echo -e "Main_VaapiDriver                = $Main_VaapiDriver\n"



# Change synced Preferences.xml ID values to backed up ID values
changed=0
if [[ $Main_AnonymousMachineIdentifier ]] && [[ $AnonymousMachineIdentifier ]]; then
    if [[ $Main_AnonymousMachineIdentifier != "$AnonymousMachineIdentifier" ]]; then
        echo "Updating AnonymousMachineIdentifier"
        sed -i "s/ AnonymousMachineIdentifier=\"${Main_AnonymousMachineIdentifier}/ AnonymousMachineIdentifier=\"${AnonymousMachineIdentifier}/g" "Preferences.xml"
        changed=$((changed+1))
    fi
fi
if [[ $Main_CertificateUUID ]] && [[ $CertificateUUID ]]; then
    if [[ $Main_CertificateUUID != "$CertificateUUID" ]]; then
        echo "Updating CertificateUUID"
        sed -i "s/ CertificateUUID=\"${Main_CertificateUUID}/ CertificateUUID=\"${CertificateUUID}/g" "Preferences.xml"
        changed=$((changed+1))
    fi
fi
if [[ $Main_FriendlyName ]] && [[ $FriendlyName ]]; then
    if [[ $Main_FriendlyName != "$FriendlyName" ]]; then
        echo "Updating FriendlyName"
        sed -i "s/ FriendlyName=\"${Main_FriendlyName}/ FriendlyName=\"${FriendlyName}/g" "Preferences.xml"
        changed=$((changed+1))
    fi
fi
if [[ $Main_LastAutomaticMappedPort ]] && [[ $LastAutomaticMappedPort ]]; then
    if [[ $Main_LastAutomaticMappedPort != "$LastAutomaticMappedPort" ]]; then
        echo "Updating LastAutomaticMappedPort"
        sed -i "s/ LastAutomaticMappedPort=\"${Main_LastAutomaticMappedPort}/ LastAutomaticMappedPort=\"${LastAutomaticMappedPort}/g" "Preferences.xml"
        changed=$((changed+1))
    fi
fi
if [[ $Main_MachineIdentifier ]] && [[ $MachineIdentifier ]]; then
    if [[ $Main_MachineIdentifier != "$MachineIdentifier" ]]; then
        echo "Updating MachineIdentifier"
        sed -i "s/ MachineIdentifier=\"${Main_MachineIdentifier}/ MachineIdentifier=\"${MachineIdentifier}/g" "Preferences.xml"
        changed=$((changed+1))
    fi
fi
if [[ $Main_ManualPortMappingPort ]] && [[ $ManualPortMappingPort ]]; then
    if [[ $Main_ManualPortMappingPort != "$ManualPortMappingPort" ]]; then
        echo "Updating ManualPortMappingPort"
        sed -i "s/ ManualPortMappingPort=\"${Main_ManualPortMappingPort}/ ManualPortMappingPort=\"${ManualPortMappingPort}/g" "Preferences.xml"
        changed=$((changed+1))
    fi
fi
if [[ $Main_PlexOnlineToken ]] && [[ $PlexOnlineToken ]]; then
    if [[ $Main_PlexOnlineToken != "$PlexOnlineToken" ]]; then
        echo "Updating PlexOnlineToken"
        sed -i "s/ PlexOnlineToken=\"${Main_PlexOnlineToken}/ PlexOnlineToken=\"${PlexOnlineToken}/g" "Preferences.xml"
        changed=$((changed+1))
    fi
fi
if [[ $Main_ProcessedMachineIdentifier ]] && [[ $ProcessedMachineIdentifier ]]; then
    if [[ $Main_ProcessedMachineIdentifier != "$ProcessedMachineIdentifier" ]]; then
        echo "Updating ProcessedMachineIdentifier"
        sed -i "s/ ProcessedMachineIdentifier=\"${Main_ProcessedMachineIdentifier}/ ProcessedMachineIdentifier=\"${ProcessedMachineIdentifier}/g" "Preferences.xml"
        changed=$((changed+1))
    fi
fi

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

