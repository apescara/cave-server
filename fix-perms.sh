#!/bin/bash

# --- Your Setup Variables ---
SHARED_UID=1000
SHARED_GID=1000
USER_NAME="dockeruser"
GROUP_NAME="dockerusers"
LXCS=(100 101 102 103 104 105)
# Add the base directory for your docker-compose files to ensure config volumes are covered
MOUNTS=("/lake1t" "/seagate4t" "/lake1t/data/cave-server/docker")

echo "==> 1. Setting up the shared user and group on the Proxmox Host..."

# Check for 'acl' package and install if missing
if ! command -v setfacl &> /dev/null; then
    echo " 'setfacl' command not found. Installing 'acl' package..."
    apt update && apt install -y acl
    if ! command -v setfacl &> /dev/null; then
        echo "ERROR: Failed to install 'acl' package. Please install it manually: apt install acl"
        exit 1
    fi
    echo " 'acl' package installed successfully."
fi

# Create group if it doesn't exist
if ! getent group $GROUP_NAME > /dev/null; then
    groupadd -g $SHARED_GID $GROUP_NAME
    echo "Group '$GROUP_NAME' (GID $SHARED_GID) created."
else
    echo "Group '$GROUP_NAME' (GID $SHARED_GID) already exists, moving on."
fi

# Create user if it doesn't exist
if ! getent passwd $USER_NAME > /dev/null; then
    useradd -u $SHARED_UID -g $SHARED_GID -s /usr/sbin/nologin -M $USER_NAME
    echo "User '$USER_NAME' (UID $SHARED_UID) created."
else
    echo "User '$USER_NAME' (UID $SHARED_UID) already exists, moving on."
fi

echo "==> 2. Configuring ZFS and Folder Permissions..."
for MOUNT in "${MOUNTS[@]}"; do
    # Auto-detect the ZFS dataset name for the mount
    DATASET=$(zfs list -H -o name "$MOUNT" 2>/dev/null)
    if [ -n "$DATASET" ]; then
        CURRENT_ACLTYPE=$(zfs get -H -o value acltype "$DATASET")
        if [ "$CURRENT_ACLTYPE" != "posixacl" ]; then
            echo " - Enabling advanced permissions (ACLs) on ZFS dataset: $DATASET"
            zfs set acltype=posixacl "$DATASET"
        else
            echo " - ZFS dataset $DATASET already has acltype=posixacl."
        fi
    fi

    echo " - Applying magic permissions to $MOUNT..."
    # Ensure the mount point exists before applying permissions
    mkdir -p "$MOUNT"
    chown -R $USER_NAME:$GROUP_NAME "$MOUNT" # Use -R for recursive ownership
    chmod -R 2775 "$MOUNT" # This '2' is the setgid bit that forces inheritance
    
    # Force default Read/Write/Execute for the group on all future files
    setfacl -R -d -m g:$SHARED_GID:rwx "$MOUNT"
    setfacl -R -m g:$SHARED_GID:rwx "$MOUNT"
done

echo "==> 3. Pushing configuration to your LXCs..."
for LXC in "${LXCS[@]}"; do
    # Check if LXC is running (pct exec only works on running containers)
    STATUS=$(pct status $LXC | awk '{print $2}')
    if [ "$STATUS" != "running" ]; then
        echo " - LXC $LXC is OFF. Skipping. (Turn it on and run this script again later!)"
        continue
    fi

    echo " - Setting up LXC $LXC..."
    # Create the group inside the container if it doesn't exist
    pct exec $LXC -- sh -c "getent group $GROUP_NAME > /dev/null || groupadd -g $SHARED_GID $GROUP_NAME"
    # Create the user inside the container if it doesn't exist
    pct exec $LXC -- sh -c "getent passwd $USER_NAME > /dev/null || useradd -u $SHARED_UID -g $SHARED_GID -s /usr/sbin/nologin -M $USER_NAME"
    # Add the container's root user to the group (optional, but good for troubleshooting)
    pct exec $LXC -- usermod -aG $GROUP_NAME root
    # Add the newly created dockeruser to its own group (should be primary group already)
    pct exec $LXC -- usermod -aG $GROUP_NAME $USER_NAME
done

echo "==> All done! Restart your LXCs so the changes take full effect."
echo "    *** IMPORTANT: You still need to configure lxc.idmap for each unprivileged LXC! ***"
echo "    Add the following lines to /etc/pve/lxc/<LXC_ID>.conf for each relevant LXC:"
echo "    lxc.idmap = u 0 100000 1000       "
echo "    lxc.idmap = g 0 100000 1000       "
echo "    lxc.idmap = u 1000 1000 1         "
echo "    lxc.idmap = g 1000 1000 1         "
echo "    lxc.idmap = u 1001 101001 64535   "
echo "    lxc.idmap = g 1001 101001 64535   "
echo "    After modifying .conf files, restart the LXCs."