# _RadShift_ - Host Set-Up

Initial access: `ssh pirate@black-pearl` (Password: `hypriot`)



## Set up SSH

see also:
  * [Hardening SSH, _Jason Rigden_](https://medium.com/@jasonrigden/hardening-ssh-1bcb99cd4cef)
  * [Secure the SSH server on Ubuntu, Hitesh Jethva](https://devops.profitbricks.com/tutorials/secure-the-ssh-server-on-ubuntu/)

1. Add key authentication:
  - If necessary, generate a SSH keypair with `ssh-keygen`
  - copy it to the host: `ssh-copy-id pirate@black-pearl`
2. Adjust `/etc/ssh/sshd_config` with the following values:
    ```config
    Protocol 2
    Port 2294
    AllowUsers pirate
    PermitRootLogin no
    ClientAliveInterval 300
    ClientAliveCountMax 2
    PasswordAuthentication no
    PermitEmptyPasswords no
    X11Forwarding no
    HostKey /etc/ssh/ssh_host_rsa_key
    HostKey /etc/ssh/ssh_host_ed25519_key
    PrintLastLog no
    IgnoreRhosts yes
    HostbasedAuthentication no
    LoginGraceTime 60
    MaxStartups 2
    AllowTcpForwarding no
    ```

    Currently, the following lines are not supported:

    ```config
    KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hel$
    MACs umac-128-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
    Ciphers chacha20-poly1305@openssh.com,aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.$
    ```

    The following options are deprecated:

    ```config
    RhostsAuthentication no
    RSAAuthentication yes
    ```

3. Reload: `sudo systemctl reload sshd`
4. Test: `sshd -t`
5. Development:
   - Check Config with SSH Audit (`python ssh-audit.py -p 2294 black-pearl`)
   - Not covered:
     - Fail2Ban
     - Multi-factor-authentication
     - Banners
     - Regenerate Moduli



## Set up fundamentals:

1. Change password for default user pirate: `passwd`
2. Copy the `.bashrc` to `pirate`'s home dir: `scp -P 2294 .bashrc pirate@black-pearl:.`
3. Install dev tools like `make`: `sudo apt-get install build-essential`
4. Re-establish backupped data:
   1. Copy TAR to host: `scp -P 2294 backup.tar pirate@black-pearl:backup.tar`


## Set up for apps:

1. Add cronjob for updating nextcloud files:
   1. `crontab -e`
   2. Add the lines
      * `*/5 * * * * docker exec -u www-data nextcloud /var/www/html/occ files:scan --all > /home/pirate/nextcloud-cronjob.log`
      * `*/5 * * * * sudo chown -R www-data /var/rs-root/var/nextcloud/data >> /home/pirate/nextcloud-cronjob.log`


## Set up RAID-1

See also [Build a Raspberry Pi RAID NAS Server – Complete DIY Guide](https://www.ricmedia.com/build-raspberry-pi3-raid-nas-server/)

1. Install `mdadm`:
  ```bash
  sudo apt-get update
  sudo apt-get upgrade -y
  sudo apt-get install mdadm -y
  ```
  (May require an intermediate reboot)
2. Find the USB drives: `sudo blkid`
  E.g.:
  ```bash
    ...
    /dev/sda1: LABEL="SanDisk-SSD" UUID="B04C5F094C5EC9AC" TYPE="ntfs" PARTUUID="01a915d1-01"
    /dev/sdb1: LABEL="SanDisk-USB" UUID="843679B23679A5B8" TYPE="ntfs" PARTUUID="f0cb91ee-01"
    ...
  ```
  &rarr; Drives are `/dev/sda1` and `/dev/sdb1`
3. Set up the two drives for RAID-1: `sudo mdadm --create --verbose /dev/md0 --level=mirror --raid-devices=2 /dev/sda1 /dev/sdb1`
4. Confirm the setup: `cat /proc/mdstat` - Displays the current sync status
5. Save the RAID array:
  ```bash
  sudo -i
  mdadm --detail --scan >> /etc/mdadm/mdadm.conf
6. Format the RAID drive with ext4: `sudo mkfs.ext4 -v -m .1 -b 4096 -E stride=32,stripe-width=64 /dev/md0`
7. Mount the drive to the `RS_ROOT` directory:
  ```bash
  mkdir /var/rs-root
  sudo mount /dev/md0 /var/rs-root
  ```
8. Auto-mount the RAID drive:
   1. Find the UUID with `sudo blkid` 
   2. Edit `fstab`: `sudo nano /etc/fstab` and add the line, e.g.:
      `UUDI=4e118f22-b08d-4949-91e4-2d02f9343641 /var/rs-root ext4 defaults 0 0`
9. Set the owner of the new directory to `pirate`: `sudo chown -R pirate:pirate /var/rs-root`

## Development

To pull images from the dev registry, edit `/etc/docker/daemon.json` and add it to the `insecure-registries` entry:
```json
{
  "insecure-registries" : ["rpi-workstation:5000"]
}
```


<!--
## External drives (USB port)

Subject is to use a USB drive with NTFS file system (because it's usable both under Windows and Linux) on the Hypriot Raspberry Pi and make its content accessable to Docker containers.

See also:
* https://jankarres.de/2013/01/raspberry-pi-usb-stick-und-usb-festplatte-einbinden/ [German]
* https://gist.github.com/etes/aa76a6e9c80579872e5f [English]


### Prequel 1: Format test USB drive

Find drive:

```bash
df -h
/dev/sda1       [...]   /media/fvo/SONY USB
```

Format with NTFS (so that it can be used easily under windows, too):

```bash
sudo umount /dev/sda1
sudo mkfs.ntfs -f -L 'myTestDrive' /dev/sda1
#   -L:     Label
#   -f/-Q:  Quick format
#sudo mkfs.ext4 /dev/sda1 for ext4
sudo umount /dev/sda1
```


### Prequel 2: Prepare Raspberry

1. Install filesystem dependencies:
  ```
  sudo apt-get update
  sudo apt-get -y install ntfs-3g hfsutils hfsprogs exfat-fuse
  ```

2. Create mount directory:
  `sudo mkdir /media/usbdrives/default`


### Mount USB drives to Raspberry (manually):

1. List USB devices:
  `sudo blkid -o list -w /dev/null`
  > `/dev/sdb1    ntfs   myTestDrive   77884C3708BDF919`

2. Manually mount USB device:
 `sudo mount -t ntfs-3g -o utf8,uid=pirate,gid=pirate,noatime /dev/sdb1 /media/usbdrives/default`
 (`sudo mount -t ext4 -o defaults /dev/sdb1 /media/usbdrives/default` for ext4)

3. Manually unmount/eject USB device:
 `sudo umount /media/usbdrives/default`


### Mount USB drives to Raspberry (automatically):

Edit the file `/etc/fstab`:
`sudo nano -w /etc/fstab`
`UUID=77884C3708BDF919 /media/usbdrives/default ntfs-3g utf8,uid=pirate,gid=pirate,noatime 0`
Reboot


### Notes:

1. Mounting the `/media/usbdrives/default` directory makes the drive available for Docker containers (or all drives mounted under this directory by mounting `/media/usbdrives`)

2. TODO for automation (preferrably from inside a Docker container, if possible)
   1. Format & name USB drives
   2. Perform the steps above automatically
   3. Duplicate contents of on drive to another for backups (Suggestion: one master USB port, others are slave ports)
   4. Retrieve stats from drives

-->