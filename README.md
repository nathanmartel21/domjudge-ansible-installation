# DOMjudge ansible deployment

<table><tr><td style="vertical-align: top; width: 70%;"><blockquote><strong>NOTE</strong><br>
      This repository provides an <strong>Infrastructure as Code</strong> solution using <strong>ansible</strong> to automate the <strong>installation</strong> of <a href="https://www.domjudge.org/">DOMjudge</a> components: <strong>domserver</strong> and <strong>judgehosts</strong>.<br><br>
      <strong>Only the installation is covered.</strong><br>
      The configuration of DOMjudge (users, contests, problems, etc.) is <strong>not</strong> handled by this project.
      </blockquote></td><td style="text-align: right;"><img src="docs/img/DOMjudgelogo.svg" alt="DOMjudge Logo" height="140"></td></tr></table>

---

<p align="center">
  <a href="https://gitlab.fel.cvut.cz/icpc/one-click-contest/domjudge-ansible-installation/-/commits/main">
    <img alt="pipeline status" src="https://gitlab.fel.cvut.cz/icpc/one-click-contest/domjudge-ansible-installation/badges/main/pipeline.svg" />
  </a>
  <a href="https://gitlab.fel.cvut.cz/icpc/one-click-contest/domjudge-ansible-installation/-/commits/main">
    <img alt="coverage report" src="https://gitlab.fel.cvut.cz/icpc/one-click-contest/domjudge-ansible-installation/badges/main/coverage.svg" />
  </a>
  <a href="https://gitlab.fel.cvut.cz/icpc/one-click-contest/domjudge-ansible-installation/-/commits/main">
    <img src="https://img.shields.io/gitlab/last-commit/icpc/one-click-contest/domjudge-ansible-installation?gitlab_url=https://gitlab.fel.cvut.cz" alt="Last Commit" />
  </a>
  <img src="https://img.shields.io/badge/platform-linux-lightgrey?logo=linux" alt="Linux"/>
  <img src="https://img.shields.io/badge/os-debian-a80030?logo=debian&logoColor=white" alt="Debian"/>
  <img src="https://img.shields.io/badge/db-MariaDB-blue?logo=mariadb" alt="MariaDB"/>
  <img src="https://img.shields.io/badge/webserver-nginx%20%7C%20apache-blue?logo=nginx&logoColor=white" alt="Webserver: Nginx or Apache"/>
  <img src="https://img.shields.io/badge/DOMjudge-Automated%20Install-orange?logo=codeforces" alt="DOMjudge Automated Install"/>
  <img src="https://img.shields.io/badge/component-domserver-blueviolet" alt="DOMserver"/>
  <img src="https://img.shields.io/badge/component-judgehost-darkgreen" alt="Judgehost"/>
</p>


---

## Project Structure

```
.
├── README.md
├── ansible.cfg
├── archives/
│   ├── api-create-judgehost.yml
│   ├── install-dom.yml
│   ├── install-judge.yml
│   ├── manage-restapi-file.yml
│   └── start-service-judgehost.yml
├── inventory/
│   ├── hosts.ini
│   └── hosts.ini.example
├── passwords/
│   ├── vault-pass.example
│   └── vault-pass.txt
├── playbooks/
│   ├── domserver.yml
│   └── judgehost.yml
└── roles/
    ├── domserver/
    │   ├── defaults/
    │   │   └── main.yml
    │   └── tasks/
    │       └── main.yml
    └── judgehost/
        ├── defaults/
        │   └── main.yml
        └── tasks/
            └── main.yml
```

- `roles/domserver`: Role to install and setup the DOMjudge server.
- `roles/judgehost`: Role to install and connect judgehost nodes.
- `playbooks/domserver.yml`: Playbook for installing the domserver.
- `playbooks/judgehost.yml`: Playbook for installing and connecting judgehosts to the domserver.

---

## Documentation

Detailed documentation for each role is available:

- [`docs/README-domserver.md`](docs/README-domserver.md)
- [`docs/README-judgehost.md`](docs/README-judgehost.md)

---

## Usage

> [!IMPORTANT]
> **You must always run the `domserver` playbook _before_ the `judgehost` playbook.**  
> The judgehosts connect to the domserver during their installation. If the domserver is not installed and running, the judgehost playbook will fail.

1. **Customize your inventory**
   - Edit or create `inventory/hosts.ini` to define your target hosts.
   - An example inventory file is available at `inventory/hosts.ini.example`.

2. **Set up your password file**
   - Create a file at `passwords/vault-pass.txt` containing the password used to decrypt the ansible vault.
   - See `passwords/vault-pass.example` for the expected format.
   - This vault password is required to access sensitive variables, such as the `db_root_password` used to configure the MariaDB database on the DOMjudge server.

3. **Adjust variables as needed**
   - You can review and override default variables in:
     - `roles/domserver/defaults/main.yml`
     - `roles/judgehost/defaults/main.yml`

4. **Run the playbooks in order:**

   ```bash
   ansible-playbook playbooks/domserver.yml --ask-become-pass
   ansible-playbook playbooks/judgehost.yml --ask-become-pass
   ```

## Notes

According to the official documentation, the **domserver** and **judgehost** should never run on the same machine. This separation is important for performance reasons.

