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

1. Set `www-data` as owner of the Nextcloud directory:
   1. `sudo chown -R www-data /var/rs-root/var/nextcloud`
2. Add cronjob for updating nextcloud files:
   1. `crontab -e`
   2. Add the line
      * `*/5 * * * * sudo chown -R www-data /var/rs-root/var/nextcloud/data`
3. Replace Nextcloud's `config.php` with the provided `config.php`, containing the following additional line:
    ```php
      'filesystem_check_changes' => 0,
    ```


## External USB drive as main data volume

1. Find the USB drive: `sudo blkid`, e.g.:
   `/dev/sda: LABEL="sundisk-256gb" UUID="f67c21d6-bf43-4663-9b48-52deb77ad77e" TYPE="ext4"`
2. Empty the target directory: `/var/rs-root/`
3. Mount: `sudo mount /dev/sda /var/rs-root`
4. Edit `fstab`: `sudo nano /etc/fstab` and add the line, e.g.:
      `UUDI=f67c21d6-bf43-4663-9b48-52deb77ad77e /var/rs-root ext4 defaults,nofail 0 0`
      *ATTENTION:* In many cases, the PI will not boot without the option `nofail` (or `noauto`)
5. Set the owner of the new directory to `pirate`: `sudo chown -R pirate:pirate /var/rs-root`



## Backup on a second USB drive

Pre-steps:
1. Install `sudo apt-get install rsync ntfs-3g`
2. Format USB drive: `sudo fdisk /dev/sda`
   1. Delete: `d`
   2. Commit/write: `w`
3. Format USB drive: `sudo mkfs.ext4 -L 'PNY-32GB' /dev/sda`

Steps:

1. Find drive: `lsblk`, look for the label
2. Create mount dir: `sudo mkdir /mnt/backup-usb-drive`
3. Mount: `sudo mount /dev/sdd /mnt/backup-usb-drive`
4. Stop all containers: `cd /var/rs-root && docker-compose stop`
5. Also dot files: `shopt -s dotglob`
6. Copy: `sudo rsync -avhAP -delete /var/rs-root /mnt/backup-usb-drive`
   1. Nextcloud recommendation: `rsync -avxA nextcloud/ nextcloud`
   2. `sudo rsync -rPz /var/rs-root /mnt/backup-usb-drive`
   
   - a: archivieren; kombiniert -rlptgoD
   - v: verbos
   - h: output numbers in a human-readable format
   - A: preserve ACLs (implies --perms)
   - x: one filesystem; don't cross filesystem boundaries
   - r: Verzeichnisse rekursiv kopieren
   - P: Progress bar anzeigen
   - z: Daten während Übertragung komprimieren

7. Set up cronjob:
   1. `crontab -e`
   2. Add the line
      * `0 3 * * * /home/pirate/backup.sh > backup.log 2>&1`