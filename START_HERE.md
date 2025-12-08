# 🚀 Ansible Rancher Role - Start here!

## COMPLETE test in 3 commands

```bash
# 1. Position yourself
cd /home/ansible/roles/rancher

# 2. Check prerequisites
vagrant version && vboxmanage --version

# 3. Run the test
make test
```

**Duration:** 10-15 minutes | **Result:** Rancher completely deployed and tested!

## 📚 Documentation

| File | Description |
|------|-------------|
| **[README_TESTS.md](README_TESTS.md)** | ⭐ Quick test guide (START HERE) |
| [README.md](README.md) | Complete role documentation |
| [TESTING.md](TESTING.md) | Detailed test guide |
| [QUICKSTART.md](QUICKSTART.md) | Quick start for production |
| [TEST_SCENARIOS.md](../../TEST_SCENARIOS.md) | Test scenario comparison |

## 🔐 SSL/TLS Certificates

The role supports **three modes** of certificates:

### 1. Self-signed (default)
Perfect for testing, no configuration required.

### 2. Provided certificates
Use your own certificates:
```yaml
rancher_ssl_mode: "provided"
rancher_ssl_cert_path: "files/cert.pem"
rancher_ssl_key_path: "files/key.pem"
```

### 3. Let's Encrypt
Free and automatic certificates:
```yaml
rancher_ssl_mode: "letsencrypt"
rancher_letsencrypt_email: "admin@example.com"
rancher_letsencrypt_domain: "rancher.example.com"
```

**📘 Complete guide:** [SSL_CERTIFICATES.md](SSL_CERTIFICATES.md) | [SSL_QUICKSTART.md](SSL_QUICKSTART.md)

## 🎯 Two testing approaches

### 1. COMPLETE test with Vagrant (RECOMMENDED)

**Tests EVERYTHING, including Rancher deployment!**

```bash
make test  # ~10-15 min
```

What is tested:
- ✅ Docker installation
- ✅ Self-signed SSL certificates
- ✅ Complete Rancher deployment
- ✅ Rancher API functional
- ✅ Web interface accessible
- ✅ K3s cluster initialized

### 2. Quick test with Docker

**Validates infrastructure only (for CI/CD)**

```bash
make test-quick  # ~3-5 min
```

What is tested:
- ✅ Docker installation
- ✅ System configuration
- ⏭️ Skip Rancher (Docker-in-Docker limitation)

## ⚡ Essential commands

```bash
make help              # Display all commands
make test              # Complete test
make test-quick        # Quick test
make converge-vagrant  # Create VM and deploy
make verify-vagrant    # Verify deployment
make destroy-vagrant   # Destroy VM
make clean             # Clean everything
```

## 🛠️ Installing prerequisites

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install virtualbox vagrant

# Verify
vagrant version
vboxmanage --version

# Install Python dependencies (optional for Molecule tests)
make install
```

## 📊 Project structure

```
roles/rancher/
├── START_HERE.md         # ← YOU ARE HERE
├── README_TESTS.md       # Quick test guide
├── README.md             # Complete documentation
├── TESTING.md            # Detailed tests
├── Vagrantfile           # Vagrant config for tests
├── test_playbook.yml     # Test playbook
├── test_verify.yml       # Verifications
├── Makefile              # Convenient commands
├── defaults/
│   └── main.yml          # Configurable variables
├── tasks/
│   ├── main.yml          # Entry point
│   ├── validate.yml      # Validations
│   ├── docker.yml        # Docker installation
│   ├── firewall.yml      # UFW configuration
│   └── deploy.yml        # Rancher deployment
├── handlers/
│   └── main.yml          # Handlers
├── meta/
│   └── main.yml          # Metadata
└── molecule/
    ├── default/          # Quick tests (Docker)
    └── vagrant/          # Complete tests (legacy folder)
```

## 🎬 Recommended workflow

### For developing/testing the role

```bash
# 1. Make modifications in tasks/

# 2. Quick test
make test-quick

# 3. Lint
make lint

# 4. Complete test before commit
make test

# 5. Clean up
make clean
```

### For production use

```bash
# 1. Test the role
cd roles/rancher
make test

# 2. Create your playbook
cd ../../
cp deploy_rancher_role.yml my_deployment.yml

# 3. Adapt to your needs
nano my_deployment.yml

# 4. Deploy
ansible-playbook -i inventory.yml my_deployment.yml
```

## 🐛 Common issues

### Vagrant won't start

```bash
vagrant destroy -f
vagrant up
```

### Molecule fails

Use Vagrant directly:
```bash
make test  # Uses Vagrant, not Molecule
```

### Rancher API timeout

Normal on first boot. K3s takes 5-7 minutes.
```bash
vagrant ssh -c "docker logs rancher | tail -20"
```

## 🎓 Learn more

### Important variables

```yaml
# defaults/main.yml
rancher_version: "stable"          # Rancher version
rancher_port: 8443                 # HTTPS port
rancher_bootstrap_password: "..."  # Admin password
rancher_configure_firewall: true   # Configure UFW
```

### Available tags

```bash
ansible-playbook playbook.yml --tags validate  # Validations only
ansible-playbook playbook.yml --tags docker    # Docker only
ansible-playbook playbook.yml --tags deploy    # Deployment only
ansible-playbook playbook.yml --skip-tags firewall  # Without firewall
```

## 📞 Need help?

1. Read [README_TESTS.md](README_TESTS.md) for tests
2. Read [README.md](README.md) for usage
3. Read [TESTING.md](TESTING.md) for debugging
4. Check logs: `vagrant ssh -c "docker logs rancher"`

## 🎉 First test

Run your first test now:

```bash
make test
```

After 10-15 minutes, you'll have:
- ✅ An Ubuntu VM with Rancher deployed
- ✅ A functional K3s cluster
- ✅ An accessible Rancher API
- ✅ A web interface at **https://192.168.56.15:8443**

**Username:** admin
**Password:** admin123456789

> **Note:** The IP is configured in the Vagrantfile and can be changed if needed

Good luck! 🚀
