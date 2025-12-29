# Ansible Role: Rancher

[![CI](https://github.com/astigmata/ansible-role-rancher/actions/workflows/ci.yml/badge.svg)](https://github.com/astigmata/ansible-role-rancher/actions/workflows/ci.yml)
[![Ansible Role](https://img.shields.io/badge/ansible--galaxy-astigmata.rancher-blue.svg)](https://galaxy.ansible.com/astigmata/rancher)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Deploy Rancher Server in single-node mode with Docker.

## Requirements

| Component | Version |
|-----------|---------|
| Ansible | >= 2.17 |
| Python | >= 3.10 |

**Supported Operating Systems:**

| Distribution | Versions |
|--------------|----------|
| Ubuntu | 20.04, 22.04, 24.04 |
| Debian | 11 (Bullseye), 12 (Bookworm), 13 (Trixie) |

**Hardware Requirements:**
- 2+ vCPUs
- 4+ GB RAM (3.5 GB minimum)

**Required Collections:**
- `community.general` >= 12.0.0
- `community.docker` >= 4.7.0
- `community.crypto` >= 3.0.0

## Installing dependencies

```bash
# Install required Ansible collections
ansible-galaxy collection install -r requirements.yml

# Required collections:
# - community.general >= 7.0.0
# - community.docker >= 3.0.0
# - community.crypto >= 2.0.0 (for certificate management)
```

## Role variables

### Default variables (defaults/main.yml)

| Variable | Default | Description |
|----------|---------|-------------|
| `rancher_version` | `stable` | Rancher version to deploy (pin to specific version in production) |
| `rancher_data_volume` | `rancher_data` | Docker volume name for data |
| `rancher_container_name` | `rancher` | Rancher container name |
| `rancher_port` | `8443` | HTTPS port for Rancher |
| `rancher_http_port` | `8080` | HTTP port for Rancher |
| `rancher_min_vcpus` | `2` | Minimum required vCPUs |
| `rancher_min_memory_mb` | `3500` | Minimum required RAM (MB) |
| `rancher_api_wait_retries` | `10` | API availability retries (tunable for slower hardware) |
| `rancher_api_wait_delay` | `10` | Delay between retries (seconds) |
| `rancher_port_wait_timeout` | `300` | Max time to wait for port (seconds) |
| `rancher_full_init_retries` | `60` | K3s initialization retries |
| `rancher_full_init_delay` | `10` | K3s initialization delay (seconds) |
| `rancher_configure_firewall` | `true` | Configure UFW firewall automatically |

### Required variables

| Variable | Description |
|----------|-------------|
| `rancher_bootstrap_password` | Initial admin password (min 12 chars + 1 digit) |

### Optional variables

| Variable | Description |
|----------|-------------|
| `rancher_public_ip` | Public IP for display (default: ansible_default_ipv4.address) |

## Usage

### Simple playbook

```yaml
---
- name: Deploy Rancher
  hosts: rancher_servers
  become: true

  vars_prompt:
    - name: rancher_bootstrap_password
      prompt: "Rancher admin password"
      private: true

  roles:
    - role: rancher
```

### Playbook with custom variables

```yaml
---
- name: Deploy Rancher with custom settings
  hosts: rancher_servers
  become: true

  vars:
    rancher_version: "v2.8.0"
    rancher_port: 9443
    rancher_bootstrap_password: "MySecurePassword123!"
    rancher_configure_firewall: false

  roles:
    - role: rancher
```

### Execution

```bash
# With vars_prompt
ansible-playbook deploy_rancher_role.yml

# With command-line variable
ansible-playbook deploy_rancher_role.yml -e "rancher_bootstrap_password=SecurePass123!"
```

## Available tags

| Tag | Description |
|-----|-------------|
| `rancher` | All role tasks |
| `validate` | Hardware and password validation |
| `docker` | Docker installation |
| `firewall` | UFW configuration |
| `deploy` | Rancher deployment |

### Tag usage examples

```bash
# Only validate without deploying
ansible-playbook deploy_rancher_role.yml --tags validate

# Deploy without configuring firewall
ansible-playbook deploy_rancher_role.yml --skip-tags firewall

# Only install Docker
ansible-playbook deploy_rancher_role.yml --tags docker
```

## Testing with Molecule

This role provides **two test scenarios**:

### 🚀 COMPLETE tests with Vagrant (RECOMMENDED)
Uses VirtualBox/Vagrant to create a real VM and test **complete Rancher deployment**.

```bash
cd roles/rancher

# Install prerequisites
sudo apt install virtualbox vagrant  # Ubuntu/Debian
make install

# Run complete tests
make test
# OR
molecule test -s vagrant
```

**Duration:** 10-15 minutes | **Tests:** Infrastructure + Rancher + API + Web interface

### ⚡ QUICK tests with Docker (infrastructure only)
Quick validation of infrastructure without Rancher deployment (Docker-in-Docker limitation).

```bash
cd roles/rancher

# Install prerequisites
make install

# Run quick tests
make test-quick
# OR
molecule test -s default
```

**Duration:** 3-5 minutes | **Tests:** Infrastructure + Docker (skip Rancher container)

For more details, see [TESTING.md](TESTING.md).

## Important Notes

### ⚠️ Version Management

The role defaults to **`stable`** which points to the latest stable release tested by Rancher. While this provides maximum compatibility, **production environments should pin to a specific version**.

**Version options:**

```yaml
# Default: Stable tag (tested by Rancher, but can change)
rancher_version: "stable"

# Recommended for production: Pin to specific version
rancher_version: "v2.9.3"   # LTS version
rancher_version: "v2.10.2"  # Specific stable version

# Latest (bleeding edge, not recommended)
rancher_version: "latest"
```

**Find available versions:**
- Docker Hub tags: https://hub.docker.com/r/rancher/rancher/tags
- GitHub releases: https://github.com/rancher/rancher/releases
- **Note:** GitHub release versions may differ from Docker Hub tags

**Benefits of version pinning:**
- Predictable deployments
- Control over upgrades
- Avoid unexpected breaking changes
- Easier rollback if needed

Check available versions at: https://github.com/rancher/rancher/releases

### 🔄 Upgrading Rancher

**IMPORTANT:** Rancher upgrades should be planned carefully. Always:
1. **Read the release notes** for breaking changes
2. **Backup your data volume** before upgrading
3. **Test in a non-production environment first**

#### Upgrade Process

**Step 1: Backup the current installation**

```bash
# Stop Rancher container
docker stop rancher

# Backup the data volume
docker run --rm -v rancher_data:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/rancher-backup-$(date +%Y%m%d).tar.gz /data

# Restart Rancher (if needed)
docker start rancher
```

**Step 2: Update the version variable**

```yaml
# In your playbook or inventory
rancher_version: "v2.9.3"  # Your target version
```

**Step 3: Run the role to upgrade**

```bash
ansible-playbook deploy_rancher.yml
```

The role will:
- Pull the new Rancher image
- Stop the current container
- Start a new container with the updated version
- Rancher will automatically migrate the database on first start

**Step 4: Verify the upgrade**

```bash
# Check Rancher version
docker exec rancher rancher --version

# Check logs for migration progress
docker logs -f rancher
```

#### Upgrade Path Considerations

- **Minor upgrades** (e.g., v2.9.1 → v2.9.3): Generally safe, low risk
- **Major upgrades** (e.g., v2.8.x → v2.9.x): Review [upgrade guides](https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/install-upgrade-on-a-kubernetes-cluster/upgrades)
- **Multi-version jumps**: May require intermediate upgrades (e.g., v2.7 → v2.8 → v2.9)

#### Rollback Procedure

If something goes wrong:

```bash
# Stop the new version
docker stop rancher
docker rm rancher

# Restore from backup
docker run --rm -v rancher_data:/data -v $(pwd):/backup \
  ubuntu tar xzf /backup/rancher-backup-YYYYMMDD.tar.gz -C /

# Revert to previous version in your playbook
rancher_version: "v2.9.1"  # Previous working version

# Redeploy
ansible-playbook deploy_rancher.yml
```

#### Upgrade Resources

- **Official upgrade docs**: https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade
- **Known issues**: https://github.com/rancher/rancher/releases
- **Support matrix**: https://www.suse.com/suse-rancher/support-matrix/all-supported-versions/

## Features

### SSL/TLS Certificate Management

The role supports three certificate modes:

1. **Self-signed** (default) - Perfect for testing
2. **Provided** - Use your own certificates
3. **Let's Encrypt** - Free and automatic certificates

```yaml
# Self-signed (default)
rancher_ssl_mode: "selfsigned"

# Provided certificates
rancher_ssl_mode: "provided"
rancher_ssl_cert_path: "files/cert.pem"
rancher_ssl_key_path: "files/key.pem"

# Let's Encrypt
rancher_ssl_mode: "letsencrypt"
rancher_letsencrypt_email: "admin@example.com"
rancher_letsencrypt_domain: "rancher.example.com"
```

See [SSL_CERTIFICATES.md](SSL_CERTIFICATES.md) for the complete guide.

### Automatic validation

The role automatically validates:
- Minimum hardware configuration (CPU, RAM)
- Password complexity (12 chars min + 1 digit)
- Certificate validity (if `provided` mode)

### Docker installation

- Docker CE installation from official repository
- Docker service configuration
- User addition to docker group
- docker-compose installation

### Network security

- UFW configuration (optional)
- Opening Rancher ports only
- SSH lockout protection

### Rancher deployment

- Rancher container with restart policy
- Persistent volume for data
- API availability wait
- Startup verification

## Architecture

```
tasks/
├── main.yml        # Entry point
├── validate.yml    # Validations
├── docker.yml      # Docker installation
├── firewall.yml    # UFW configuration
└── deploy.yml      # Rancher deployment
```

## Troubleshooting

### Container won't start

```bash
# Check logs
docker logs rancher

# Check status
docker ps -a | grep rancher
```

### API not responding

The internal K3s cluster initialization can take 2-5 minutes. Please wait and refresh the page.

### Docker permission issues

```bash
# Re-login or
newgrp docker
```

### UFW blocking access

```bash
# Check rules
sudo ufw status verbose

# Check Rancher ports
sudo ufw allow 8443/tcp
sudo ufw allow 8080/tcp
```

## Known Limitations

### RHEL-Family Distributions (Rocky Linux, AlmaLinux, CentOS)

This role does **not support** RHEL-family distributions (Rocky Linux 8/9, AlmaLinux 8/9, CentOS Stream 8/9). This is due to fundamental incompatibilities with Rancher's embedded K3s cluster:

**Root Cause:**
- Rancher uses an embedded K3s cluster for its internal operations
- K3s has known compatibility issues with cgroup v2 (default on RHEL 9+)
- The K3s process crashes with `exit status 1` shortly after startup
- This occurs even with SELinux in permissive mode

**Symptoms observed:**
```
rancher | The embedded K3s cluster failed to initialize
rancher | Error: exit status 1
```

**Workarounds attempted (all failed):**
1. SELinux permissive mode
2. Manual cgroup v1 configuration
3. Docker cgroup driver changes
4. K3s-specific environment variables

**Recommended alternatives for RHEL-family:**
- Use RKE2 (Rancher Kubernetes Engine) instead of single-node Docker
- Deploy Rancher on a Kubernetes cluster with Helm
- Use Ubuntu/Debian for single-node Docker deployments

For more information, see:
- [K3s Known Issues](https://docs.k3s.io/known-issues)
- [Rancher Requirements](https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/installation-requirements)

## License

MIT

## Author

astigmata
