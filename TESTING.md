# Rancher Role Testing Guide

## Three Test Scenarios

This role provides three testing approaches:

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

**Tested distributions:**
- Ubuntu 22.04 LTS (Debian family)
- Rocky Linux 9 (RedHat family)

**Duration:** ~20-30 minutes (both VMs in parallel) | **Prerequisites:** VirtualBox + Vagrant installed

> **Note:** Tests BOTH distributions in parallel with full Rancher deployment

### 🔄 `multi-distro` - Multi-Distribution Tests (Docker)
Tests role compatibility across multiple Linux distributions:
- ✅ Ubuntu 22.04 (Debian family)
- ✅ Rocky Linux 9 (RedHat family)
- ✅ Debian 12 (Debian family)
- ✅ Infrastructure validation on all platforms
- ⏭️ Rancher container deployment (skipped - Docker-in-Docker limitation)

**Duration:** ~8-12 minutes | **Prerequisites:** Docker installed

> **Note:** Validates that the role works correctly across different OS families (Debian vs RedHat)

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
pip install molecule-vagrant python-vagrant
ansible-galaxy collection install -r molecule/default/requirements.yml
```

## Running Tests

### FULL Tests with Vagrant (RECOMMENDED)

```bash
# Full test with actual Rancher deployment
make test

# OR explicitly
make test-full

# OR directly with Vagrant
vagrant up
```

### MULTI-DISTRO Tests (validate across Linux distributions)

```bash
# Test on Ubuntu, Rocky Linux, and Debian
molecule test -s multi-distro

# OR keep instances after test for debugging
molecule test -s multi-distro --destroy=never
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
molecule create -s vagrant     # Create the VM
molecule converge -s vagrant   # Apply the role
molecule verify -s vagrant     # Run the tests
molecule destroy -s vagrant    # Destroy the VM
```

#### With Docker (quick test)
```bash
molecule create -s default     # Create the container
molecule converge -s default   # Apply the role (skip Rancher)
molecule verify -s default     # Run the tests
molecule destroy -s default    # Destroy the container
```

### Idempotence Tests

```bash
# With Vagrant (recommended)
make idempotence

# OR manually
molecule create -s vagrant
molecule converge -s vagrant
molecule idempotence -s vagrant  # Verify that a 2nd execution changes nothing
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
# Create and converge first
molecule converge -s vagrant

# Connect to the VM
molecule login -s vagrant

# Inside the VM:
docker ps
docker logs rancher
curl -k https://localhost:8443/ping

# Access the web interface
# The VM IP is displayed during create
# Open in a browser: https://<VM_IP>:8443
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
# Keep the VM after failure
molecule test -s vagrant --destroy=never

# Connect to the VM
molecule login -s vagrant

# Examine Rancher logs
docker logs rancher
journalctl -u docker -n 100

# Re-converge after modifications
molecule converge -s vagrant

# Destroy when done
molecule destroy -s vagrant
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

### `vagrant` Scenario (full)
```
molecule/vagrant/
├── molecule.yml      # Vagrant config with VirtualBox
├── converge.yml      # Deploy complete role
├── prepare.yml       # VM preparation
└── verify.yml        # Complete tests including Rancher
```

Tests performed:
- ✅ Docker service verification
- ✅ Rancher container status (RUNNING)
- ✅ Docker volumes
- ✅ Exposed ports (80, 443)
- ✅ Rancher API responds to /ping
- ✅ Web interface accessible

### `default` Scenario (quick)
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

# Clean completely (destroy everything)
make clean

# Create a Vagrant VM
molecule create -s vagrant

# Verify after convergence
molecule verify -s vagrant

# Destroy the Vagrant VM
molecule destroy -s vagrant

# Destroy all environments
make destroy
```

## Test Scenarios

### `vagrant` Scenario (RECOMMENDED for full validation)

This scenario tests **EVERYTHING** on BOTH distributions:
1. Creation of 2 VMs in parallel (VirtualBox):
   - Ubuntu 22.04 LTS (Debian family)
   - Rocky Linux 9 (RedHat family)
2. Docker installation on each distribution
3. **Complete Rancher deployment with K3s**
4. **Rancher API verification**
5. **K3s API Aggregation verification**
6. **Web interface access test**
7. Idempotence test

**Prerequisites:** VirtualBox + Vagrant
**Duration:** 20-30 minutes (both VMs tested in parallel)
**Usage:** Complete validation before production deployment

### `multi-distro` Scenario (cross-platform validation)

This scenario validates role compatibility across different Linux distributions:
1. Creation of 3 Docker containers (Ubuntu 22.04, Rocky Linux 8, Debian 12)
2. Docker installation on each distribution
3. Data volume creation
4. Verification that the role works on both Debian and RedHat families
5. ⏭️ Skip Rancher deployment (DinD limitation)

**Prerequisites:** Docker
**Duration:** 8-12 minutes
**Usage:** Validate role compatibility before supporting new distributions

### `default` Scenario (quick for CI/CD)

This scenario tests infrastructure:
1. Creation of Ubuntu 22.04 Docker container
2. Docker installation
3. Data volume creation
4. ⏭️ Skip Rancher deployment (DinD limitation)

**Prerequisites:** Docker
**Duration:** 3-5 minutes
**Usage:** CI/CD, quick validation of infrastructure changes

### Complete Test Sequence

```
dependency     → Install Ansible collections
cleanup        → Cleanup before creation
destroy        → Destroy previous instance
syntax         → Syntax check
create         → Create VM/container
prepare        → Prepare environment
converge       → Apply the role
idempotence    → Idempotence test
verify         → Run tests
cleanup        → Final cleanup
destroy        → Destroy instance
```

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

### Vagrant Scenario (full - 2 VMs in parallel)
- VM creation: ~2-3min (Ubuntu + Rocky)
- Docker installation: ~2min per VM
- Rancher deployment: ~5-7min per VM (K3s init)
- Verification tests: ~1min per VM
- **Total: ~20-30 minutes** (both VMs tested in parallel)

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
