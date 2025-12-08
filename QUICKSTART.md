# Quick Start Guide - Rancher Role

## Installation and first test (5 minutes)

### 1. Clone/Position in the role
```bash
cd /home/ansible/roles/rancher
```

### 2. Install dependencies
```bash
# Python dependencies
pip install -r requirements-dev.txt
pip install molecule-vagrant python-vagrant

# Ansible collections
ansible-galaxy collection install -r molecule/default/requirements.yml

# OR simply
make install
```

### 3. Install VirtualBox and Vagrant
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install virtualbox vagrant

# Verify installation
vagrant --version
vboxmanage --version
```

### 4. Run the complete test
```bash
# Complete test with real Rancher deployment (10-15 min)
make test

# OR to see details
molecule test -s vagrant
```

## Production usage

### 1. Create your playbook
```bash
cd /home/ansible
nano deploy_rancher_prod.yml
```

```yaml
---
- name: Deploy Rancher on production server
  hosts: rancher_server
  become: true

  vars_prompt:
    - name: rancher_bootstrap_password
      prompt: "Rancher admin password (min 12 chars + 1 number)"
      private: true

  roles:
    - role: rancher
```

### 2. Create your inventory
```bash
nano inventory_prod.ini
```

```ini
[rancher_server]
rancher-prod ansible_host=192.168.1.100 ansible_user=ubuntu
```

### 3. Deploy
```bash
ansible-playbook -i inventory_prod.ini deploy_rancher_prod.yml
```

### 4. Access Rancher
After deployment (5-7 minutes), access:
```
https://<SERVER_IP>:8443
```

Credentials:
- Username: `admin`
- Password: the one you defined

## Advanced options

### Customize ports
```yaml
# In your playbook
vars:
  rancher_port: 9443
  rancher_http_port: 9080
```

### Disable firewall
```yaml
# In your playbook
vars:
  rancher_configure_firewall: false
```

### Specify a Rancher version
```yaml
# In your playbook
vars:
  rancher_version: "v2.8.0"
```

### Use with Ansible Vault
```bash
# Create a vault file
ansible-vault create group_vars/all/vault.yml

# Add the password
# vault_rancher_password: "YourPassword123!"

# In the playbook
vars:
  rancher_bootstrap_password: "{{ vault_rancher_password }}"

# Deploy
ansible-playbook -i inventory_prod.ini deploy_rancher_prod.yml --ask-vault-pass
```

## Useful commands

```bash
# See Makefile help
make help

# Quick tests (without Rancher)
make test-quick

# Lint the code
make lint

# Clean up
make clean

# List active Molecule VMs
make list
```

## Quick troubleshooting

### Vagrant VM won't start
```bash
# Check VirtualBox
vboxmanage list vms

# Restart service
sudo systemctl restart vboxdrv

# Destroy and recreate
molecule destroy -s vagrant
molecule create -s vagrant
```

### Test fails on Rancher API
This is normal on first startup. K3s takes 5-7 minutes to initialize.

### Timeout error
Increase timeouts in `defaults/main.yml`:
```yaml
rancher_api_wait_retries: 90  # instead of 60
```

## Project structure

```
roles/rancher/
├── defaults/main.yml      # Default variables
├── tasks/                 # Ansible tasks
│   ├── main.yml
│   ├── validate.yml
│   ├── docker.yml
│   ├── firewall.yml
│   └── deploy.yml
├── handlers/main.yml      # Handlers
├── molecule/              # Tests
│   ├── default/          # Quick tests (Docker)
│   └── vagrant/          # Complete tests (VM)
├── README.md             # Complete documentation
├── TESTING.md            # Detailed test guide
└── Makefile              # Convenient commands
```

## Next steps

1. ✅ Test the role with `make test`
2. ✅ Read [README.md](README.md) for complete documentation
3. ✅ Read [TESTING.md](TESTING.md) for advanced tests
4. ✅ Deploy on a test server
5. ✅ Configure persistence and backups
6. ✅ Deploy in production

## Support

- Complete documentation: [README.md](README.md)
- Test guide: [TESTING.md](TESTING.md)
- Migration guide: [../MIGRATION_GUIDE.md](../../../MIGRATION_GUIDE.md)
