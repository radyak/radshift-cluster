# Setup

Hardware:
    * Zotac Zbox CI329
    * 2TB SSD (Crucial BX500)
    * 8 GB DDR4 RAM (Crucial CT2K4G4SFS8266)

Don't forget to activate portforwarding for ports 80 and 443 on your firewall / router.

## OS

Ubuntu Server 20.04

Notes on installation:
    * Deactivate secure boot and pure UEFI boot
    * Install with LAN attached, to autoconfigure network devices and download latest installer

## Docker

Docker should not be installed with Ubuntu server (as snap). If done so, remove it:
* [Optional] `snap list`
* `sudo snap remove docker`

Install Docker according to standard (see https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository):
```bash
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

## Check:
docker run hello-world
```

Install Docker-Compose:
```bash
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

## Check (may need a logout, as the snap docker link may still be in the session):
docker-compose --version
```

## Optional

* Copy the `.bashrc` to the default user's home dir: `scp [-P <port>] .bashrc <user>@<host>:.`
* Install dev tools like `make`: `sudo apt-get install build-essential`

## File Structure

### Restore backup

If present, transfer old data from a USB drive to `rs-root`:
* Check USB drives: `sudo blkid`
* Mount the USB drive:
    `sudo mkdir -p /mnt/backup-usb-drive`
    `sudo mount /dev/sda /mnt/backup-usb-drive`
* [Optional] Confirm the mount with `lsblk`
* Copy the files from the USB drive to `rs-root`: `cp -rf /mnt/backup-usb-drive /var/rs-root`
* [Optional] Copy the config to the host:
  * Change to this project's `/run` directory
  * Call the make deploy target: `make deploy`

### Nextcloud DB

Usually, no additional dump and/or import should be required, as the Postgres data should be included in the backup of `/var/rs-root`. However, in cases like migrating from a 32-bit system to 64-bit (e.g. from Raspberry Pi / ARMHF to an Intel or AMD), the data must be transferred with a dump.

* Export the dump on the old system:
  * Connect to the nextcloud-db container: `docker exec -it nextcloud-db sh`
  * Export to a mounted volume (e.g. the mounted data directory): `pg_dump -U {db user name} nextcloud > /var/lib/postgresql/data/dump.sql`
* Import the dump on the new system:
  * Start an empty container on the new system: `docker-compose up -d nextcloud-db` (Important: data directory must be empty!)
  * Transfer the dump file to the new system, into a mounted directory (e.g. the mounted data directory)
  * Connect to the nextcloud-db container: `docker exec -it nextcloud-db sh`
  * Import from the mounted volume: `psql -U {db user name} nextcloud < /var/lib/postgresql/data/dump.sql`


### Set up for apps

1. Optional: set `www-data` as owner of the Nextcloud directory:
   1. `sudo chown -R www-data /var/rs-root/var/nextcloud`
3. Register files not added by nextcloud (e.g. with streamnomorefam): Replace Nextcloud's `config.php` with the provided `config.php`, containing the following additional line:
    ```php
      'filesystem_check_changes' => 0,
    ```


## Automatic backups

1. Set up cronjob (e.g. every 2 weeks, at 1st and 16th of each month at 03:00):
   1. `crontab -e`
   2. Add the line
      * `0 2 1,16 * * /var/rs-root/backup.sh > backup.log 2>&1`