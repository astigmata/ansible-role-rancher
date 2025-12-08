# SSL/TLS Certificate Management Guide for Rancher

This role supports three SSL/TLS certificate management modes:

1. **Self-signed** - Default, for testing
2. **Provided** - Certificates you already own
3. **Let's Encrypt** - Free and automatic certificates

## Quick Configuration

### Mode 1: Self-signed Certificates (default)

No configuration required! The role automatically generates a self-signed certificate.

```yaml
# No configuration needed, this is the default mode
rancher_ssl_mode: "selfsigned"
```

**Advantages:**
- ✅ No configuration needed
- ✅ Works immediately
- ✅ Perfect for testing

**Disadvantages:**
- ⚠️ Security warning in browser
- ⚠️ Do not use in public production

### Mode 2: Provided Certificates

To use your own certificates (purchased or from an internal CA):

```yaml
rancher_ssl_mode: "provided"
rancher_ssl_cert_path: "/path/to/your/certificate.pem"
rancher_ssl_key_path: "/path/to/your/private-key.pem"
rancher_ssl_chain_path: "/path/to/your/ca-chain.pem"  # Optional
```

**Advantages:**
- ✅ Trusted certificates
- ✅ No browser warning
- ✅ Full control

**Prerequisites:**
- Files must exist on the Ansible Controller server
- Certificate must match the private key
- Domain must match the certificate

### Mode 3: Let's Encrypt

To obtain a free and automatically valid certificate:

```yaml
rancher_ssl_mode: "letsencrypt"
rancher_letsencrypt_email: "admin@example.com"
rancher_letsencrypt_domain: "rancher.example.com"
```

**Advantages:**
- ✅ Valid and free certificate
- ✅ Automatic renewal
- ✅ No cost

**Prerequisites:**
- DNS domain pointing to the server
- Port 80 accessible from the Internet (for validation)
- Valid email address

## Usage Examples

### Example 1: Local testing with self-signed

```yaml
---
- name: Deploy Rancher for testing
  hosts: rancher_test
  become: true

  vars:
    rancher_bootstrap_password: "TestPassword123!"
    # rancher_ssl_mode is already "selfsigned" by default

  roles:
    - rancher
```

### Example 2: Production with provided certificates

```yaml
---
- name: Deploy Rancher with corporate certificates
  hosts: rancher_prod
  become: true

  vars:
    rancher_bootstrap_password: "{{ vault_rancher_password }}"
    rancher_ssl_mode: "provided"
    rancher_ssl_cert_path: "files/certificates/rancher.example.com.crt"
    rancher_ssl_key_path: "files/certificates/rancher.example.com.key"
    rancher_ssl_chain_path: "files/certificates/ca-bundle.crt"

  roles:
    - rancher
```

File structure:
```
playbook.yml
files/
  certificates/
    rancher.example.com.crt
    rancher.example.com.key
    ca-bundle.crt
```

### Example 3: Production with Let's Encrypt

```yaml
---
- name: Deploy Rancher with Let's Encrypt
  hosts: rancher_prod
  become: true

  vars:
    rancher_bootstrap_password: "{{ vault_rancher_password }}"
    rancher_ssl_mode: "letsencrypt"
    rancher_letsencrypt_email: "admin@example.com"
    rancher_letsencrypt_domain: "rancher.example.com"

  roles:
    - rancher
```

**Before running:**
1. Make sure `rancher.example.com` points to your server
2. Open port 80 in your firewall (temporarily for validation)
3. Port 443 must also be open

## Configuration Variables

### Common Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `rancher_ssl_mode` | `selfsigned` | Certificate mode: `selfsigned`, `provided`, `letsencrypt` |
| `rancher_ssl_cert_dir` | `/opt/rancher/ssl` | Certificate storage directory |

### Self-signed Certificate Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `rancher_ssl_selfsigned_common_name` | Server IP | Certificate CN (IP or domain) |
| `rancher_ssl_selfsigned_days` | `365` | Validity period (days) |
| `rancher_ssl_selfsigned_country` | `FR` | Country code (2 letters) |
| `rancher_ssl_selfsigned_state` | `Ile-de-France` | State/Region |
| `rancher_ssl_selfsigned_locality` | `Paris` | City |
| `rancher_ssl_selfsigned_organization` | `Rancher` | Organization |

### Provided Certificate Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `rancher_ssl_cert_path` | ✅ | Path to certificate file (.pem or .crt) |
| `rancher_ssl_key_path` | ✅ | Path to private key (.pem or .key) |
| `rancher_ssl_chain_path` | ❌ | Path to CA chain (optional) |

### Let's Encrypt Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `rancher_letsencrypt_email` | ✅ | Email for notifications |
| `rancher_letsencrypt_domain` | ✅ | Full domain name (FQDN) |
| `rancher_letsencrypt_staging` | ❌ | `true` for testing (invalid certificate) |

## Certificate Management

### Check current certificate

```bash
# On the Rancher server
sudo openssl x509 -in /opt/rancher/ssl/cert.pem -noout -text

# View validity dates
sudo openssl x509 -in /opt/rancher/ssl/cert.pem -noout -dates

# View subject
sudo openssl x509 -in /opt/rancher/ssl/cert.pem -noout -subject
```

### Renew a self-signed certificate

```bash
# Method 1: Delete and re-run Ansible
sudo rm -rf /opt/rancher/ssl/*
ansible-playbook deploy_rancher.yml --tags certificates

# Method 2: Generate manually
sudo openssl genrsa -out /opt/rancher/ssl/key.pem 2048
sudo openssl req -new -key /opt/rancher/ssl/key.pem -out /opt/rancher/ssl/csr.pem
sudo openssl x509 -req -in /opt/rancher/ssl/csr.pem -signkey /opt/rancher/ssl/key.pem -out /opt/rancher/ssl/cert.pem -days 365

# Restart Rancher
docker restart rancher
```

### Renew Let's Encrypt

Renewal is automatic (weekly cron). To force:

```bash
sudo certbot renew --force-renewal
docker restart rancher
```

### Replace a certificate

```bash
# 1. Place new files
sudo cp /path/to/new-cert.pem /opt/rancher/ssl/cert.pem
sudo cp /path/to/new-key.pem /opt/rancher/ssl/key.pem

# 2. Verify permissions
sudo chmod 644 /opt/rancher/ssl/cert.pem
sudo chmod 600 /opt/rancher/ssl/key.pem

# 3. Restart Rancher
docker restart rancher
```

## Certificate Formats

### Supported Formats

The role accepts the following formats:
- PEM (`.pem`) - Recommended
- CRT (`.crt`)
- KEY (`.key`)

### Format Conversion

If you have certificates in other formats:

```bash
# PKCS#12 (.pfx, .p12) to PEM
openssl pkcs12 -in certificate.pfx -out cert.pem -clcerts -nokeys
openssl pkcs12 -in certificate.pfx -out key.pem -nocerts -nodes

# DER to PEM
openssl x509 -inform der -in certificate.cer -out cert.pem
openssl rsa -inform der -in private.key -out key.pem
```

## Security

### File Permissions

The role automatically configures:
- Certificate: `0644` (public read, OK as it is public)
- Private key: `0600` (root read only)
- Directory: `0755`

### Private Key Protection

**IMPORTANT:** Never:
- ❌ Commit the private key to Git
- ❌ Share the private key
- ❌ Send the key by email

Use Ansible Vault for sensitive certificates:

```bash
# Encrypt certificate files
ansible-vault encrypt files/certificates/rancher.key

# Playbook
- name: Copy encrypted certificate
  ansible.builtin.copy:
    src: "{{ rancher_ssl_key_path }}"
    dest: /opt/rancher/ssl/key.pem
    decrypt: true
```

## Troubleshooting

### Error: "Certificate and key do not match"

The certificate and key do not match.

```bash
# Check certificate modulus
openssl x509 -noout -modulus -in cert.pem | openssl md5

# Check key modulus
openssl rsa -noout -modulus -in key.pem | openssl md5

# The two MD5 hashes must be identical
```

### Let's Encrypt Error: "Challenge failed"

The Let's Encrypt server cannot validate your domain.

**Checks:**
```bash
# 1. DNS points to the server
dig +short rancher.example.com

# 2. Port 80 is open
sudo netstat -tlnp | grep :80

# 3. Firewall allows port 80
sudo ufw status | grep 80
```

### "NET::ERR_CERT_AUTHORITY_INVALID" Warning

Normal with a self-signed certificate. Options:

1. **Accept temporarily** (click "Advanced" → "Proceed")
2. **Import certificate** into your OS keychain
3. **Switch to `provided` or `letsencrypt` mode**

### Expired Certificate

```bash
# Check expiration
openssl x509 -in /opt/rancher/ssl/cert.pem -noout -enddate

# Self-signed: regenerate
sudo rm /opt/rancher/ssl/*
ansible-playbook deploy_rancher.yml --tags certificates

# Let's Encrypt: renew
sudo certbot renew
docker restart rancher
```

## Ansible Tags

```bash
# Regenerate certificates only
ansible-playbook playbook.yml --tags certificates

# Everything except certificates
ansible-playbook playbook.yml --skip-tags certificates

# Certificates + deployment
ansible-playbook playbook.yml --tags certificates,deploy
```

## Complete Example: Migration to Let's Encrypt

```bash
# 1. Configure DNS
# rancher.example.com → SERVER_IP

# 2. Create playbook
cat > migrate-to-letsencrypt.yml <<EOF
---
- name: Migrate to Let's Encrypt
  hosts: rancher_servers
  become: true

  vars:
    rancher_ssl_mode: "letsencrypt"
    rancher_letsencrypt_email: "admin@example.com"
    rancher_letsencrypt_domain: "rancher.example.com"

  tasks:
    - name: Open port 80 temporarily
      community.general.ufw:
        rule: allow
        port: 80
        proto: tcp

    - name: Import rancher role
      ansible.builtin.include_role:
        name: rancher
        tasks_from: certificates

    - name: Restart Rancher
      community.docker.docker_container:
        name: rancher
        state: started
        restart: true

    - name: Close port 80
      community.general.ufw:
        rule: deny
        port: 80
        proto: tcp
EOF

# 3. Run
ansible-playbook migrate-to-letsencrypt.yml
```

## Best Practices

### For Test Environments
- ✅ Use `selfsigned`
- ✅ Accept the security warning
- ✅ No DNS needed

### For Production
- ✅ Use `letsencrypt` if public domain
- ✅ Use `provided` for internal/purchased certificates
- ✅ Configure automatic renewal
- ✅ Monitor expiration
- ✅ Document the procedure

### For Provided Certificates
- ✅ Store certificates in Ansible Vault
- ✅ Automate deployment
- ✅ Keep a backup copy
- ✅ Document the source (CA, provider)

## Multi-domain Support (SAN)

For a certificate with multiple domains:

```yaml
# Provided mode with SAN
rancher_ssl_mode: "provided"
rancher_ssl_cert_path: "files/rancher-multidomain.crt"
rancher_ssl_key_path: "files/rancher-multidomain.key"

# The certificate must contain:
# Subject Alternative Names:
#   DNS: rancher.example.com
#   DNS: rancher.example.org
#   DNS: rancher-backup.example.com
```

The role will use them directly.

## More Information

- [Documentation Rancher - SSL/TLS](https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/installation-references/tls-settings)
- [Let's Encrypt](https://letsencrypt.org/)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
