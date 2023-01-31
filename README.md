# Plex_Server_Sync
Sync main Plex server database &amp; metadata to backup Plex server

<a href="https://github.com/007revad/Plex_Server_Sync/releases"><img src="https://img.shields.io/github/release/007revad/Plex_Server_Sync.svg"></a>
<a href="https://hits.seeyoufarm.com"><img src="https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2F007revad%2FPlex_Server_Sync&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false"/></a>

<p align="center"><img src="plex_server_sync_logo.png"></p>

### Description

Plex_Server_Sync is a bash script to sync one Plex Media Server to another Plex Media Server, **including played status, play progress, posters, metadata, ratings and settings**. The only things not synced are settings specific to each Plex Media Server (like server ID, friendly name, public port etc), and files and folders listed in the plex_rsync_exclude.txt file.

This script was written for those who have a main Plex server and a backup Plex server and want to keep the backup server in sync with the main server. Or for those who have a Plex server at home and a Plex server at their holiday house and want to sync to their holiday house Plex server before leaving home, and then sync back to their home Plex server before leaving the holiday house to return home.
The script needs to run on the source plex server machine.

Tested on Synolgy DSM 7, DSM 6 and Asustor ADM. It should also work on Ubuntu, Debian and any other Linux distro.

#### What the script does

* Gets the Plex version from both Plex servers.
* Stops both the source and destination Plex servers.
* Backs up the destination Plex server's Preferences.xml file.
* Copies all newer data files from the source Plex server to the destination Plex server.
  * Files listed in the exclude file will not be copied.
* Optionally deletes any extra files in the destination Plex server's data folder.
  * Files listed in the exclude file will not be deleted.
* Restores the destination Plex server's machine specific settings in Preferences.xml.
* Starts both Plex servers.

Everything is saved to a log file, and any errors are also saved to an error log file.

#### What the script does NOT do

It does **not** do a 2-way sync. It only syncs one Plex server to another Plex server.

### Requirements

1. **The script needs to run on the source Plex Media Server machine.**

2. **The following files must be in the same folder as plex_server_sync.sh**

   ```YAML
   plex_server_sync.config
   edit_preferences.sh
   plex_rsync_exclude.txt
   ```

3. **Both Plex servers must be running the same Plex Media Server version**

4. **Both Plex servers must have the same library path**

   If the source Plex server accesses it's media libraries at "/volume1/videos" and "/volume1/music" then the destination server also needs to access it's media libraries at "/volume1/videos" and "/volume1/music"

5. **SSH Keys and sudoers**

   If you want to schedule the script to run unattended, as a scheduled cron job, the users need to have sudoers and SSH keys setup so that the SSH, SCP and rsync commands can access the remote server without you entering the user's password. 

**Asustor NAS requirements**

Because the Asustor only has Busybox ash and this script requires bash you'll need to instal bash.

To install bash on your Asustor:

1. First install Entware from App Central. 

2. Then run the following commands via SSH. You can run the commands in "Shell In A Box" from App Central, or use PuTTY.

   ```YAML
   opkg update && opkg upgrade
   opkg install bash
   ```

### Settings

You need to set the source and destination settings in the **plex_server_sync.config** file. There are also a few optional settings in the plex_server_sync.config file.

**For example:**

```YAML
src_IP=192.168.0.70
src_OS=DSM7
src_Directory="/volume1/PlexMediaServer/AppData/Plex Media Server"
src_User=Bob

dst_IP=192.168.0.60
dst_OS=DSM6
dst_Directory="/volume1/Plex/Library/Application Support/Plex Media Server"
dst_User=Bob
dst_SshPort=22

Delete=yes
DryRun=no
LogPath=~/plex_server_sync_logs
```

### Default contents of plex_rsync_exclude.txt

Any files or folders listed in plex_rsync_exclude.txt will **not** be synced. The first 4 files listed must never be synced from one server to another. The folders listed are optional.

**Contents of plex_rsync_exclude.txt**

```YAMLedit_preferences.sh
Preferences.bak
.LocalAdminToken
plexmediaserver.pid
Cache
Codecs
Crash Reports
Diagnostics
Drivers
Logs
Updates
```
