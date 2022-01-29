#!/bin/bash

# sudo askpass
# [ ! -x "$(command -v cifs-utils)" ] && sudo apt install cifs-utils
# [ ! -x "$(command -v smbclient)" ] && sudo apt install smbclient
# [ ! -x "$(command -v zenity)" ] && sudo apt install zenity

SMB_CREDS="$HOME/.smb-credentials"
SERVER_IP=$(zenity --title="Select Server" --list --column="Servers" "192.168.100.2" "192.168.200.2")
MOUNT_DIR="$HOME/Desktop/Synology"

if ! [ -f $SMB_CREDS ]; then
    echo 'username='"$(zenity --entry --text="Synology user name:")" > $SMB_CREDS
    echo 'password='"$(zenity --password --text="Synology user password:")" >> $SMB_CREDS
fi

SHARED_DIRS=$(smbclient -L $SERVER_IP -A $SMB_CREDS | grep "Disk" | cut -d' ' -f1 | tr -d "[:blank:]" | tr "\n" " ")
IFS=' ' read -r -a SHARED_DIRS_LIST <<< "$SHARED_DIRS"

SHARED_DIR=$(zenity --title="Shared folders" --text="Select shared folder" --list --column="Folders" "${SHARED_DIRS_LIST[@]}")

[ ! -d "$MOUNT_DIR/$SHARED_DIR" ] && mkdir -p "$MOUNT_DIR/$SHARED_DIR"

if ! grep -q "$SERVER_IP/$SHARED_DIR" /etc/fstab; then
    export SUDO_ASKPASS="/tmp/askpass.sh"
    echo -e '#!/bin/bash\nzenity --password --title="Linux Authentication"' > $SUDO_ASKPASS
    chmod +x $SUDO_ASKPASS
    sudo -A tee -a /etc/fstab > /dev/null << EOF
//$SERVER_IP/$SHARED_DIR $MOUNT_DIR/$SHARED_DIR cifs noauto,users,vers=2.0,credentials=$SMB_CREDS  0 0
EOF
fi

mount "$MOUNT_DIR/$SHARED_DIR"
# mount -t cifs -o vers=2.0,credentials=$SMB_CREDS //$SERVER_IP/$SHARED_DIR "$MOUNT_DIR/$SHARED_DIR"
