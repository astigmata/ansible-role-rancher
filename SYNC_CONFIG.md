# Test configuration synchronization

## ✅ Solution Implemented - Single Source of Truth

**Good news!** The Vagrantfile now automatically reads configuration from `test_vars.yml`, eliminating the need to maintain values in two places.

## How it works

The Vagrantfile loads configuration from `test_vars.yml` at startup:

```ruby
require 'yaml'
test_vars = YAML.load_file('test_vars.yml')
RANCHER_IP = test_vars['rancher_public_ip']
RANCHER_PASSWORD = test_vars['rancher_bootstrap_password']
```

**You only need to edit `test_vars.yml`** - the Vagrantfile will pick up the changes automatically!

## Configuration

### test_vars.yml (Single Source of Truth)
```yaml
rancher_bootstrap_password: "admin123456789"
rancher_public_ip: "192.168.56.15"
rancher_configure_firewall: false
```

## Benefits

✅ **No duplication** - Edit only `test_vars.yml`
✅ **No synchronization issues** - Vagrantfile reads from the same source
✅ **Simple to maintain** - One file to update
✅ **Error prevention** - Impossible to have mismatched values

## Modify configuration

Simply edit `test_vars.yml`:

```bash
# Edit the configuration file
nano test_vars.yml

# Change the values as needed:
# - rancher_public_ip: "192.168.56.20"
# - rancher_bootstrap_password: "YourPassword123!"

# Recreate VM (Vagrantfile will read the new values)
vagrant destroy -f
vagrant up
```

### Optional: Configuration script

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

## Verify configuration

### View current settings

```bash
# Simply check test_vars.yml (single source of truth)
cat test_vars.yml
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
