# Quick Guide - SSL/TLS Certificates

## Quick choice

### I want to test Rancher locally
➡️ **Mode: self-signed** (default)
```yaml
# Nothing to configure, it's automatic!
```

### I already have certificates
➡️ **Mode: provided**
```yaml
rancher_ssl_mode: "provided"
rancher_ssl_cert_path: "files/cert.pem"
rancher_ssl_key_path: "files/key.pem"
```

### I want free and valid certificates
➡️ **Mode: letsencrypt**
```yaml
rancher_ssl_mode: "letsencrypt"
rancher_letsencrypt_email: "admin@example.com"
rancher_letsencrypt_domain: "rancher.example.com"
```

## Deployment in 3 steps

### Self-signed (Test)
```bash
# 1. Create the playbook
cat > deploy.yml <<EOF
---
- hosts: rancher
  become: true
  vars_prompt:
    - name: rancher_bootstrap_password
      prompt: "Password"
      private: true
  roles:
    - rancher
EOF

# 2. Deploy
ansible-playbook -i inventory.yml deploy.yml

# 3. Access (accept the warning)
https://SERVER_IP:8443
```

### Provided certificates (Production)
```bash
# 1. Prepare certificates
mkdir -p files/certs
cp your-cert.pem files/certs/cert.pem
cp your-key.pem files/certs/key.pem

# 2. Create the playbook
cat > deploy.yml <<EOF
---
- hosts: rancher
  become: true
  vars:
    rancher_bootstrap_password: "{{ vault_pass }}"
    rancher_ssl_mode: "provided"
    rancher_ssl_cert_path: "files/certs/cert.pem"
    rancher_ssl_key_path: "files/certs/key.pem"
  roles:
    - rancher
EOF

# 3. Deploy
ansible-playbook -i inventory.yml deploy.yml
```

### Let's Encrypt (Public production)
```bash
# 1. Verify DNS
dig +short rancher.example.com
# Must return your server's IP

# 2. Create the playbook
cat > deploy.yml <<EOF
---
- hosts: rancher
  become: true
  vars:
    rancher_bootstrap_password: "{{ vault_pass }}"
    rancher_ssl_mode: "letsencrypt"
    rancher_letsencrypt_email: "admin@example.com"
    rancher_letsencrypt_domain: "rancher.example.com"
  roles:
    - rancher
EOF

# 3. Deploy
ansible-playbook -i inventory.yml deploy.yml

# Port 80 will be temporarily opened for validation
# then automatically closed
```

## Useful commands

### Verify certificate
```bash
# See details
sudo openssl x509 -in /opt/rancher/ssl/cert.pem -noout -text

# See expiration
sudo openssl x509 -in /opt/rancher/ssl/cert.pem -noout -enddate

# Verify cert and key match
CERT_MD5=$(sudo openssl x509 -noout -modulus -in /opt/rancher/ssl/cert.pem | openssl md5)
KEY_MD5=$(sudo openssl rsa -noout -modulus -in /opt/rancher/ssl/key.pem | openssl md5)
echo "Cert: $CERT_MD5"
echo "Key:  $KEY_MD5"
# Both must be identical
```

### Regenerate a certificate
```bash
# Self-signed
sudo rm -rf /opt/rancher/ssl/*
ansible-playbook deploy.yml --tags certificates
docker restart rancher

# Let's Encrypt (renew)
sudo certbot renew
docker restart rancher
```

### Change mode
```bash
# 1. Modify the playbook (change rancher_ssl_mode)
# 2. Relaunch
ansible-playbook deploy.yml --tags certificates
docker restart rancher
```

## Common problems

### "Certificate and key do not match"
```bash
# Verify files
openssl x509 -noout -modulus -in cert.pem | openssl md5
openssl rsa -noout -modulus -in key.pem | openssl md5
# MD5s must be identical
```

### Let's Encrypt fails
```bash
# 1. Verify DNS
dig +short rancher.example.com

# 2. Verify port 80
sudo netstat -tlnp | grep :80

# 3. See logs
sudo tail -100 /var/log/letsencrypt/letsencrypt.log
```

### Browser warning (self-signed)
This is normal! Options:
1. Click "Advanced" → "Accept risk"
2. Switch to `provided` or `letsencrypt` mode

## Complete examples

See the `examples/` directory:
- `deploy-with-selfsigned.yml`
- `deploy-with-provided-certs.yml`
- `deploy-with-letsencrypt.yml`

## Complete documentation

For more details: [SSL_CERTIFICATES.md](SSL_CERTIFICATES.md)
