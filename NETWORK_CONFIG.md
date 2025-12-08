# Network configuration for Vagrant tests

## Default configuration

By default, the Vagrant VM uses a fixed IP on a VirtualBox private network:

```ruby
RANCHER_IP = "192.168.56.15"
RANCHER_PASSWORD = "admin123456789"
```

### Advantages of fixed IP

✅ No need to search for the VM's IP
✅ Direct access from your browser
✅ Predictable IP for tests
✅ No VirtualBox NAT to traverse

## Access to Rancher

After `vagrant up`, access directly to:

**URL:** https://192.168.56.15:8443
**Username:** admin
**Password:** admin123456789

## Customize network configuration

### Change IP

**Important:** You must modify **two files** to keep everything synchronized.

#### 1. Vagrantfile

```ruby
# Line 7
RANCHER_IP = "192.168.56.20"  # Your new IP
```

#### 2. test_vars.yml

```yaml
rancher_public_ip: "192.168.56.20"  # Same IP
```

**Important:** The IP must be in the `192.168.56.0/24` range which is VirtualBox's default host-only network.

### Change password

**Important:** You must modify **two files** to keep everything synchronized.

#### 1. Vagrantfile

```ruby
# Line 8
RANCHER_PASSWORD = "YourPassword123!"  # Min 12 chars + 1 digit
```

#### 2. test_vars.yml

```yaml
rancher_bootstrap_password: "YourPassword123!"  # Same password
```

### Use DHCP instead of fixed IP

If you prefer DHCP (not recommended for tests):

```ruby
# In Vagrantfile, line 15
config.vm.network "private_network", type: "dhcp"
```

Then get the IP with:
```bash
vagrant ssh -c "ip -4 addr show eth1 | grep inet"
```

## VirtualBox network types

### 1. NAT (default)
- IP: 10.0.2.15
- Internet access: ✅
- Access from host: ❌ (only via port forwarding)
- **Not used** because difficult to access Rancher

### 2. Host-Only / Private Network (USED)
- IP: 192.168.56.x
- Internet access: ❌
- Access from host: ✅
- **Perfect for tests**

### 3. Bridged
- IP: Same network as host
- Internet access: ✅
- Access from host: ✅
- **Too exposed for tests**

## Current configuration

```ruby
Vagrant.configure("2") do |config|
  # Ubuntu 22.04 box
  config.vm.box = "bento/ubuntu-22.04"

  # VM name
  config.vm.hostname = "rancher-test"

  # Private network with fixed IP
  config.vm.network "private_network", ip: RANCHER_IP

  # Resources
  config.vm.provider "virtualbox" do |vb|
    vb.name = "rancher-test-vm"
    vb.memory = "4096"
    vb.cpus = 2
  end
end
```

## Port forwarding (alternative)

If you don't want to use a private network:

```ruby
# Replace the network line with:
config.vm.network "forwarded_port", guest: 8443, host: 8443
config.vm.network "forwarded_port", guest: 8080, host: 8080

# Access via:
# https://localhost:8443
```

**Drawback:** Conflict if port 8443 is already in use on the host.

## Verify network configuration

### From the host

```bash
# Ping the VM
ping 192.168.56.15

# Test Rancher API
curl -k https://192.168.56.15:8443/ping
```

### From the VM

```bash
# Connect
vagrant ssh

# See all interfaces
ip addr show

# See only the private network (eth1)
ip addr show eth1

# Test API locally
curl -k https://localhost:8443/ping
```

## Troubleshooting

### IP is not accessible

```bash
# Check VirtualBox networks
vboxmanage list hostonlyifs

# If no 192.168.56.0/24 network, create it:
vboxmanage hostonlyif create
vboxmanage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1
```

### IP conflict

If another VM is already using 192.168.56.15:

```bash
# List active VMs
vboxmanage list runningvms

# Change IP in Vagrantfile
RANCHER_IP = "192.168.56.20"

# Recreate VM
vagrant destroy -f
vagrant up
```

### No Internet access in VM

This is normal with a host-only network. If you need Internet:

```ruby
# Add in Vagrantfile
config.vm.network "private_network", ip: RANCHER_IP
# The default NAT remains active for Internet
```

The VM will then have 2 interfaces:
- eth0: NAT (Internet)
- eth1: Private (192.168.56.15)

## Useful commands

```bash
# See Vagrant network configuration
vagrant ssh -c "ip addr"

# Test connectivity from host
curl -k https://192.168.56.15:8443/ping

# See VirtualBox network logs
vboxmanage showvminfo rancher-test-vm | grep NIC
```

## Recommendation

For local tests, **keep the default configuration**:
- Fixed IP: 192.168.56.15
- Host-only private network
- Direct access from browser

This is the simplest and most reliable configuration for testing Rancher!
