# Test configuration synchronization

## Problem

Vagrant tests use **two configuration files**:

1. **`Vagrantfile`** - To create and provision the VM
2. **`test_vars.yml`** - To verify deployment

These two files must have the **same values** for IP and password.

## Default configuration

### Vagrantfile (lines 7-8)
```ruby
RANCHER_IP = "192.168.56.15"
RANCHER_PASSWORD = "admin123456789"
```

### test_vars.yml
```yaml
rancher_bootstrap_password: "admin123456789"
rancher_public_ip: "192.168.56.15"
rancher_configure_firewall: false
```

## Why two files?

1. **Vagrantfile** is in Ruby and used by Vagrant to:
   - Configure VM network
   - Pass variables to Ansible provisioning

2. **test_vars.yml** is in YAML and used by Ansible to:
   - Verify that Rancher is accessible on the right IP
   - Display the correct password in messages

## Modify configuration

### Option 1: Edit everything manually

```bash
# 1. Edit Vagrantfile
nano Vagrantfile
# Change RANCHER_IP and RANCHER_PASSWORD

# 2. Edit test_vars.yml
nano test_vars.yml
# Change rancher_public_ip and rancher_bootstrap_password

# 3. Verify values match!
grep RANCHER Vagrantfile
grep rancher test_vars.yml

# 4. Recreate VM
vagrant destroy -f
vagrant up
```

### Option 2: Configuration script

Create a `set-test-config.sh` script:

```bash
#!/bin/bash
# Script to configure test IP and password

IP="${1:-192.168.56.15}"
PASSWORD="${2:-admin123456789}"

# Verify password
if [ ${#PASSWORD} -lt 12 ]; then
    echo "❌ Password must be at least 12 characters"
    exit 1
fi

if ! echo "$PASSWORD" | grep -q '[0-9]'; then
    echo "❌ Password must contain at least 1 digit"
    exit 1
fi

# Update Vagrantfile
sed -i "s/RANCHER_IP = .*/RANCHER_IP = \"$IP\"/" Vagrantfile
sed -i "s/RANCHER_PASSWORD = .*/RANCHER_PASSWORD = \"$PASSWORD\"/" Vagrantfile

# Update test_vars.yml
sed -i "s/rancher_public_ip: .*/rancher_public_ip: \"$IP\"/" test_vars.yml
sed -i "s/rancher_bootstrap_password: .*/rancher_bootstrap_password: \"$PASSWORD\"/" test_vars.yml

echo "✓ Configuration updated:"
echo "  IP: $IP"
echo "  Password: ${PASSWORD:0:3}***"
echo ""
echo "Recreate VM with:"
echo "  vagrant destroy -f && vagrant up"
```

Usage:
```bash
chmod +x set-test-config.sh
./set-test-config.sh 192.168.56.20 "MySecurePass123!"
```

## Verify synchronization

### Verification script

```bash
#!/bin/bash
# Verify Vagrantfile and test_vars.yml are synchronized

VAGRANT_IP=$(grep 'RANCHER_IP =' Vagrantfile | cut -d'"' -f2)
VAGRANT_PASS=$(grep 'RANCHER_PASSWORD =' Vagrantfile | cut -d'"' -f2)

YAML_IP=$(grep 'rancher_public_ip:' test_vars.yml | awk '{print $2}' | tr -d '"')
YAML_PASS=$(grep 'rancher_bootstrap_password:' test_vars.yml | awk '{print $2}' | tr -d '"')

if [ "$VAGRANT_IP" = "$YAML_IP" ] && [ "$VAGRANT_PASS" = "$YAML_PASS" ]; then
    echo "✓ Configuration synchronized"
    echo "  IP: $VAGRANT_IP"
    echo "  Password: ${VAGRANT_PASS:0:3}***"
    exit 0
else
    echo "❌ Configuration NOT synchronized!"
    echo ""
    echo "Vagrantfile:"
    echo "  IP: $VAGRANT_IP"
    echo "  Password: ${VAGRANT_PASS:0:3}***"
    echo ""
    echo "test_vars.yml:"
    echo "  IP: $YAML_IP"
    echo "  Password: ${YAML_PASS:0:3}***"
    exit 1
fi
```

## Makefile with verification

Add to Makefile:

```makefile
check-config: ## Verify configuration synchronization
	@echo "Checking configuration..."
	@bash -c 'VAGRANT_IP=$$(grep "RANCHER_IP =" Vagrantfile | cut -d"\"" -f2); \
	VAGRANT_PASS=$$(grep "RANCHER_PASSWORD =" Vagrantfile | cut -d"\"" -f2); \
	YAML_IP=$$(grep "rancher_public_ip:" test_vars.yml | awk "{print \$$2}" | tr -d "\""); \
	YAML_PASS=$$(grep "rancher_bootstrap_password:" test_vars.yml | awk "{print \$$2}" | tr -d "\""); \
	if [ "$$VAGRANT_IP" = "$$YAML_IP" ] && [ "$$VAGRANT_PASS" = "$$YAML_PASS" ]; then \
		echo "✓ Configuration synchronized"; \
		echo "  IP: $$VAGRANT_IP"; \
		echo "  Password: $${VAGRANT_PASS:0:3}***"; \
	else \
		echo "❌ Configuration NOT synchronized!"; \
		echo "Vagrantfile: IP=$$VAGRANT_IP"; \
		echo "test_vars.yml: IP=$$YAML_IP"; \
		exit 1; \
	fi'

test-full: check-config ## Complete test with Vagrant
	# ... rest of test
```

## Useful commands

```bash
# See current configuration
grep RANCHER Vagrantfile
cat test_vars.yml

# Verify synchronization
make check-config  # If added to Makefile

# Modify and recreate
nano Vagrantfile test_vars.yml
vagrant destroy -f
vagrant up
```

## Recommendation

To avoid errors:

1. **Always** verify synchronization before `vagrant up`
2. **Always** modify both files at the same time
3. Use a configuration script to avoid errors
4. Add `check-config` as dependency of `test-full` in Makefile

## Alternative: Single file

If you really want a single configuration file, you can:

1. Create a `config.yml` with all variables
2. Parse this file in Vagrantfile with Ruby
3. Use it directly in Ansible playbooks

Example:
```ruby
# Vagrantfile
require 'yaml'
config_file = YAML.load_file('config.yml')
RANCHER_IP = config_file['rancher_public_ip']
RANCHER_PASSWORD = config_file['rancher_bootstrap_password']
```

But this is more complex and less idiomatic for Vagrant.
