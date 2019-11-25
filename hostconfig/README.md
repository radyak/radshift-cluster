# _RadShift_ - Host Set-Up

## SSH

- [Hardening SSH, _Jason Rigden_](https://medium.com/@jasonrigden/hardening-ssh-1bcb99cd4cef):

  - Key-Authentication:
    - If necessary, generate a SSH keypair with `ssh-keygen`
    - copy it to the host: `ssh-copy-id pirate@black-pearl`
  - `sshd_config`:
    - Changes:
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
      KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hel$
      MACs umac-128-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
      Ciphers chacha20-poly1305@openssh.com,aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.$
      HostKey /etc/ssh/ssh_host_rsa_key
      HostKey /etc/ssh/ssh_host_ed25519_key
      ```
    - Test: `sshd -t`
    - Reload: `sudo systemctl reload sshd`
  - Check Config with SSH Audit (`python ssh-audit.py -p 2294 black-pearl`)
  - Not covered:
    - Fail2Ban
    - Multi-factor-authentication
    - Banners
    - Regenerate Moduli

- [Secure the SSH server on Ubuntu, Hitesh Jethva](https://devops.profitbricks.com/tutorials/secure-the-ssh-server-on-ubuntu/)
  - `sshd_config`:
    - Changes:
      ```config
      PrintLastLog no
      IgnoreRhosts yes
      RhostsAuthentication no
      RSAAuthentication yes
      HostbasedAuthentication no
      LoginGraceTime 60
      MaxStartups 2
      AllowTcpForwarding no
      X11Forwarding no
      PermitEmptyPasswords no
      ```
