# Rancher Role Testing Guide

## Two Test Scenarios

This role provides two testing approaches:

### 🚀 FULL Tests with Vagrant (RECOMMENDED)
Uses VirtualBox/Vagrant to create real VMs and tests **EVERYTHING** :
- ✅ Hardware prerequisites validation
- ✅ Docker installation
- ✅ System configuration
- ✅ Rancher volume creation
- ✅ **Complete Rancher container deployment**
- ✅ **Rancher API verification**
- ✅ **K3s API Aggregation verification**
- ✅ **Web interface access test**

**Tested distribution:**
- Ubuntu 22.04 LTS

**Duration:** ~10-15 minutes | **Prerequisites:** VirtualBox + Vagrant installed

> **Note:** Tests complete Rancher deployment on Ubuntu

### ⚡ `default` - QUICK Tests (infrastructure only)
Uses Docker for quick tests (CI/CD):
- ✅ Hardware prerequisites validation
- ✅ Docker installation
- ✅ System configuration
- ✅ Rancher volume creation
- ⏭️ Rancher container deployment (skipped - Docker-in-Docker limitation)

**Duration:** ~3-5 minutes | **Prerequisites:** Docker installed

> **Note:** Rancher includes K3s with containerd which uses complex overlay mounts incompatible with Docker-in-Docker. The `default` scenario validates infrastructure only.

## Quick Installation

```bash
cd roles/rancher

# 1. Install Python dependencies
make install

# 2. Install VirtualBox (for full tests)
# Ubuntu/Debian:
sudo apt install virtualbox

# 3. Install Vagrant (for full tests)
# Ubuntu/Debian:
sudo apt install vagrant

# OR download from https://www.vagrantup.com/downloads
```

Manual installation:
```bash
pip install -r requirements-dev.txt
ansible-galaxy collection install -r requirements.yml
```

## Running Tests

### FULL Tests with Vagrant (RECOMMENDED)

```bash
# Full test with actual Rancher deployment
make test

# OR explicitly
make test-full

# OR using Vagrant commands directly
make up-ubuntu        # Create and provision
make ssh-ubuntu       # SSH into VM
make destroy-ubuntu   # Destroy VM
```

### QUICK Tests with Docker (infrastructure only)

```bash
# Quick tests without Rancher deployment
make test-quick

# OR
molecule test -s default --destroy=never
```

### Step-by-step Tests

#### With Vagrant (full test)
```bash
make up-ubuntu           # Create and provision the VM
make ssh-ubuntu          # Connect to the VM
make provision-ubuntu    # Re-provision if needed
make destroy-ubuntu      # Destroy the VM
```

#### With Docker (quick test)
```bash
make converge            # Create and provision the container
make verify              # Run verification tests
molecule destroy -s default    # Destroy the container
```

### Idempotence Tests

```bash
# Test idempotence with Vagrant
make idempotence

# This will:
# 1. Provision the VM
# 2. Run provision again
# 3. Verify no changes were made
```

## Linting

```bash
# Run all linters
make lint

# OR separately:
yamllint .
ansible-lint .
```

## Interactive Development

### Connect to the Test VM (Vagrant)

```bash
# Create and provision first
make up-ubuntu

# Connect to the VM
make ssh-ubuntu

# Inside the VM:
docker ps
docker logs rancher
curl -k https://localhost:8443/ping

# Access the web interface from your browser
# https://192.168.56.10:8443
# Login: admin / TestPassword123!
```

### Connect to the Test Container (Docker)

```bash
# Create and converge first
molecule converge -s default

# Connect to the container
molecule login -s default

# Inside the container:
docker ps
docker volume ls
```

### Debug Tests

#### With Vagrant
```bash
# Create VM without destroying on failure
make up-ubuntu

# Connect to the VM
make ssh-ubuntu

# Inside the VM, examine logs:
docker logs rancher
journalctl -u docker -n 100

# Re-provision after modifications
make provision-ubuntu

# Destroy when done
make destroy-ubuntu
```

#### With Docker
```bash
# Keep the container after failure
molecule test -s default --destroy=never

# Connect
molecule login -s default

# Examine the infrastructure
docker ps -a
docker volume ls

# Destroy when done
molecule destroy -s default
```

## Test Structure

### Vagrant Tests (full)
```
Vagrantfile.ubuntu    # Vagrant configuration for Ubuntu 22.04
test_playbook.yml     # Ansible playbook to deploy the role
```

Tests performed:
- ✅ Docker service verification
- ✅ Rancher container status (RUNNING)
- ✅ Docker volumes
- ✅ Exposed ports (80, 443)
- ✅ Rancher API responds to /ping
- ✅ Web interface accessible

### Molecule `default` Scenario (quick)
```
molecule/default/
├── molecule.yml      # Docker config
├── converge.yml      # Deploy role (skip Rancher)
├── prepare.yml       # Container preparation
├── verify.yml        # Infrastructure tests only
└── tests/
    └── test_default.py   # Testinfra tests
```

Tests performed:
- ✅ Docker packages installed
- ✅ Docker service active
- ✅ Docker socket accessible
- ✅ Docker group created
- ✅ Rancher volume created
- ⏭️ Rancher container (skipped)

## Useful Commands

```bash
# Display Makefile help
make help

# List all active instances
make list

# Check status
make status

# Clean completely (destroy everything)
make clean

# Destroy all environments
make destroy
```

## Test Scenarios

### Vagrant (RECOMMENDED for full validation)

This scenario tests **EVERYTHING**:
1. Creation of Ubuntu 22.04 VM (VirtualBox)
2. Docker installation
3. **Complete Rancher deployment with K3s**
4. **Rancher API verification**
5. **K3s API Aggregation verification**
6. **Web interface access test**

**Prerequisites:** VirtualBox + Vagrant
**Duration:** 10-15 minutes
**Command:** `make test` or `make up-ubuntu`
**Usage:** Complete validation before production deployment

### Molecule Default (quick for CI/CD)

This scenario tests infrastructure only:
1. Creation of Ubuntu 22.04 Docker container
2. Docker installation
3. Data volume creation
4. ⏭️ Skip Rancher deployment (DinD limitation)

**Prerequisites:** Docker
**Duration:** 3-5 minutes
**Command:** `make test-quick`
**Usage:** CI/CD, quick validation of infrastructure changes

## Troubleshooting

### Error "Docker daemon not running"

```bash
# Check that Docker is active
sudo systemctl status docker
sudo systemctl start docker
```

### Docker permissions error

```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Timeout waiting for Rancher API

This is normal, K3s startup can take time. Tests have a 5-minute timeout.

### Container remains in "restarting" state

```bash
# Connect to the test container
molecule login

# Check logs
docker logs rancher

# Check resources
docker stats
```

### Complete cleanup

```bash
# Destroy all Molecule instances
molecule destroy

# Clean Docker images
docker system prune -a

# Remove Python cache
make clean
```

## CI/CD

To integrate into a CI/CD pipeline:

```yaml
# GitHub Actions example
- name: Install dependencies
  run: |
    pip install -r roles/rancher/requirements-dev.txt

- name: Run Molecule tests
  run: |
    cd roles/rancher
    molecule test
```

## Test Metrics

### Vagrant Scenario (full Ubuntu test)
- VM creation: ~2-3min
- Docker installation: ~2min
- Rancher deployment: ~5-7min (K3s init)
- Verification tests: ~1min
- **Total: ~10-15 minutes**

### Docker Scenario (quick)
- Container creation: ~30s
- Docker installation: ~2min
- Volume creation: ~10s
- Verification tests: ~30s
- **Total: ~3-5 minutes**

## Next Steps

After test validation:

1. Integrate into Ansible Galaxy
2. Add multi-OS scenarios
3. Add upgrade tests
4. Document advanced use cases
