# Complete Tests for Rancher Role - Quick Guide

## ✅ Final solution: Vagrant + Ansible (without Molecule)

To avoid compatibility issues with `molecule-vagrant`, we use **Vagrant directly** with Ansible provisioning.

## 🚀 Run the COMPLETE test now

```bash
cd /home/ansible/roles/rancher

# Check that Vagrant and VirtualBox are installed
vagrant version
vboxmanage --version

# Run the complete test
make test
```

## What happens during the test

1. **VM Creation** (~2 min)
   - Ubuntu 22.04
   - 4 GB RAM, 2 CPUs
   - DHCP private network

2. **Ansible Provisioning** (~8 min)
   - Docker installation
   - Rancher deployment
   - API wait (K3s init)

3. **Verification** (~1 min)
   - Docker running
   - Rancher container active
   - API responds on /ping
   - Web interface accessible

## Available commands

```bash
# Complete test (create + deploy + verify)
make test

# Create and deploy only
make converge-vagrant
# OR
vagrant up

# Verify after deployment
make verify-vagrant

# Connect to the VM
vagrant ssh

# See Rancher logs
vagrant ssh -c "docker logs rancher"

# Destroy the VM
make destroy-vagrant
# OR
vagrant destroy -f

# Clean everything
make clean
```

## Access Rancher after the test

The address is displayed at the end of the test, but by default:

```bash
# Open in a browser
https://192.168.56.15:8443

# Credentials:
Username: admin
Password: admin123456789
```

**Note:** Accept the self-signed certificate in your browser.

### Customize IP and password

You must modify **two files** to keep everything synchronized:

#### 1. Vagrantfile (for VM creation)

```ruby
# Lines 7-8
RANCHER_IP = "192.168.56.15"  # Change this IP
RANCHER_PASSWORD = "admin123456789"  # Change this password
```

#### 2. test_vars.yml (for verification)

```yaml
rancher_bootstrap_password: "admin123456789"  # Same password
rancher_public_ip: "192.168.56.15"  # Same IP
```

**Important:** Values must be identical in both files!

Then relaunch:
```bash
vagrant destroy -f
vagrant up
```

## Test files created

```
roles/rancher/
├── Vagrantfile              # Vagrant configuration
├── test_playbook.yml        # Deployment playbook
├── test_verify.yml          # Verification playbook
└── Makefile                 # Convenient commands
```

## Test structure

### Vagrantfile
- Defines the VM (Ubuntu 22.04, 4GB RAM, 2 CPUs)
- Configures Ansible provisioning
- Passes test variables

### test_playbook.yml
- Applies the `rancher` role
- Displays access information

### test_verify.yml
- Verifies Docker
- Verifies Rancher container
- Tests Rancher API
- Displays result

## Advantages of this approach

✅ **No Molecule** - Avoids compatibility issues
✅ **Complete test** - Really deploys Rancher with K3s
✅ **Simple** - Uses only Vagrant + Ansible
✅ **Fast** - No abstraction layers
✅ **Debuggable** - `vagrant ssh` to access the VM

## Alternative: Test with Molecule + Docker (quick)

To test only the infrastructure (without Rancher):

```bash
make test-quick
```

This test validates:
- ✅ Docker installation
- ✅ System configuration
- ✅ Volume created
- ⏭️ Skip Rancher container (Docker-in-Docker limitation)

**Duration:** 3-5 minutes instead of 10-15

## Troubleshooting

### Vagrant: VM won't boot

```bash
# Check VirtualBox
vboxmanage list vms

# Relaunch
vagrant destroy -f
vagrant up
```

### Vagrant: Network error

```bash
# Check VirtualBox networks
vboxmanage list hostonlyifs

# If problem, recreate
vagrant destroy -f
vagrant up
```

### Rancher: API timeout

This is normal on first boot. K3s takes 5-7 minutes to initialize.

```bash
# Check logs
vagrant ssh
docker logs rancher -f

# Wait to see:
# "Rancher is running"
# "Listening on :443"
```

### SSH access

```bash
# Connect
vagrant ssh

# Verify Rancher
docker ps
docker logs rancher | tail -50
curl -k https://localhost:8443/ping
```

## Cleanup

```bash
# Destroy the VM
vagrant destroy -f

# Complete cleanup
make clean

# Delete downloaded boxes
vagrant box list
vagrant box remove bento/ubuntu-22.04
```

## Next steps

After test validation:

1. ✅ The role works perfectly
2. ✅ Deploy on a real test server
3. ✅ Configure backups
4. ✅ Deploy in production

## Support

- Complete documentation: [README.md](README.md)
- Test guide: [TESTING.md](TESTING.md)
- Quick start: [QUICKSTART.md](QUICKSTART.md)
