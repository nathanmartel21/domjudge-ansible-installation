# DOMjudge DOMserver role installation

<table><tr><td style="vertical-align: top; width: 70%;"><blockquote><strong>NOTE</strong><br>
      This ansible role automates the <b>installation</b> of the DOMjudge <b>domserver</b> on a remote machine, with a default setup suitable for most use cases.
      </blockquote></td><td style="text-align: right;"><img src="img/DOMjudgelogo.svg" alt="DOMjudge Logo" height="140"></td></tr></table>

## Remote access requirements

> [!IMPORTANT]
> For the installation to work:
> - The user you connect with **must have sudo privileges** on the target machine.
> - You must have copied your SSH public key to the remote machine using:
>
> ```bash
> ssh-copy-id <user>@<host>
> ```
>
> > Make sure you have configured both the SSH user and the SSH private key for ansible by setting these options in your `ansible.cfg` file:
> > ```ini
> > [defaults]
> > remote_user = <user>
> > private_key_file = /path/privatekey/...
> > ```
> > Replace `<user>` with your actual username and update the private key path accordingly.  
> > These should match the user and key you used for `ssh-copy-id`.

---

## Default installation

- **Web server**: `nginx` is used by default (can be changed).
- **No demo/test data** is imported by default on the domserver.
- **No functional configuration** of DOMjudge (only technical installation).

---

## Customizable variables

You can change the following variables as needed:

```yaml
db_root_password: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  ...
  ...
install_demo_contest: false # or true
webserver: nginx # or apache
server_baseurl: "http://localhost" # change as needed
```

- **db_root_password**: The MariaDB root password for the database hosting DOMjudge's data.  
  
  > [!NOTE]
  > **This password must be encrypted using ansible Vault.**  
  > To generate an encrypted password, use:
  > ```bash
  > ansible-vault encrypt_string 'password_for_db' --name 'db_root_password'
  > ```
  > Remember to create the file `passwords/vault-pass.txt` with the password used to encrypt the string.

- **install_demo_contest**: Whether to import (`true`) or skip (`false`) demo/test data on the domserver.

- **webserver**: Choice of web server (`nginx` by default, or `apache`).

- **server_baseurl**: The base URL for accessing the domserver (change as needed for your setup).

---

## How to modify variables

- **In the role**:  
  Edit the file:
  ```
  roles/domserver/defaults/main.yml
  ```
- **At playbook execution** (overrides defaults):  
  Use the `-e` option:
  ```bash
  ansible-playbook playbooks/domserver.yml -e "webserver=apache install_demo_contest=true" --ask-become-pass
  ```

---

## Running the playbook

> [!NOTE]
> The inventory is already specified in the `ansible.cfg` file.

To launch the domserver installation:

```bash
ansible-playbook playbooks/domserver.yml --ask-become-pass
```

---

## Notes

- **No functional configuration of DOMjudge is performed** (no contests, users, problems, etc.).
- This role only manages the technical installation of the domserver.

---
 
