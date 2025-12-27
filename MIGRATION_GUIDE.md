# Migration Guide - Dependency Updates

**Date:** 2025-12-27
**Related:** See [DEPENDENCY_AUDIT.md](DEPENDENCY_AUDIT.md) for full audit details

## Overview

This guide helps you migrate from the old dependencies to the updated versions. These changes address critical security vulnerabilities and deprecated packages.

## Prerequisites

Before starting the migration:

1. **Python Version:** Ensure Python 3.10 or higher is installed
   ```bash
   python3 --version  # Should show 3.10+
   ```

2. **Backup:** Create a backup of your current environment
   ```bash
   pip freeze > backup-requirements.txt
   ```

3. **Virtual Environment:** Use a clean virtual environment
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

## Step-by-Step Migration

### Step 1: Uninstall Deprecated Packages

**IMPORTANT:** Remove old molecule plugins before installing new ones to avoid conflicts.

```bash
pip uninstall -y molecule-docker molecule-vagrant
```

### Step 2: Install Updated Dependencies

```bash
# Install from updated requirements file
pip install -r requirements-dev.txt

# Or upgrade individual packages:
pip install --upgrade \
  ansible>=11.0.0 \
  molecule>=25.0.0 \
  'molecule-plugins[docker]>=25.8.0' \
  'molecule-plugins[vagrant]>=25.8.0' \
  pytest>=9.0.0 \
  ansible-lint>=25.0.0
```

### Step 3: Update Ansible Collections

```bash
# Install/upgrade collections
ansible-galaxy collection install -r requirements.yml --upgrade

# Verify installations
ansible-galaxy collection list
```

Expected output should show:
- `community.general` >= 12.0.0
- `community.docker` >= 4.7.0
- `community.crypto` >= 3.0.0

### Step 4: Verify Installation

```bash
# Check versions
ansible --version
molecule --version
ansible-lint --version
pytest --version

# Verify molecule plugins are available
molecule drivers
```

Expected molecule drivers output should include:
- `delegated`
- `docker`
- `podman`
- `vagrant`

### Step 5: Test Your Setup

```bash
# Run linting
yamllint .
ansible-lint

# Run molecule tests
molecule test -s default

# If you use Vagrant
molecule test -s vagrant
```

## Breaking Changes & Compatibility

### Ansible 2.9 → 11.0

**Major Changes:**
- Python 2.7 support dropped (requires Python 3.10+)
- Many deprecated modules removed
- Stricter YAML parsing
- ansible-core 2.17+ required for updated collections

**Action Required:**
- Review playbooks for deprecated syntax
- Test all tasks thoroughly
- Update any custom modules if needed

**Reference:** [Ansible Porting Guide](https://docs.ansible.com/ansible/latest/porting_guides/porting_guides.html)

### community.docker 3.x → 4.7+

**Changes:**
- Docker SDK 2.0.0+ required
- Some parameter names changed
- New modules available

**Action Required:**
- Review docker tasks
- Check docker_container and docker_volume configurations
- Update deprecated parameters if any

**Reference:** [community.docker Changelog](https://github.com/ansible-collections/community.docker/blob/main/CHANGELOG.rst)

### community.crypto 2.x → 3.x

**Changes:**
- Requires ansible-core 2.17+
- cryptography library 3.3+ required
- Module behavior changes for certificate generation

**Action Required:**
- Test SSL certificate generation workflows
- Verify self-signed certificates still work
- Check Let's Encrypt integration

**Reference:** [community.crypto Changelog](https://github.com/ansible-collections/community.crypto/blob/main/CHANGELOG.rst)

### Molecule 6.x → 25.x

**Changes:**
- Standalone driver packages deprecated
- Unified plugin system
- Python 3.10+ required
- New configuration options

**Action Required:**
- Verify molecule.yml configurations
- Test all scenarios
- Check driver-specific options

**Reference:** [Molecule Documentation](https://docs.ansible.com/projects/molecule/)

## Troubleshooting

### Issue: "No module named 'molecule_docker'"

**Cause:** Old standalone package not uninstalled

**Solution:**
```bash
pip uninstall molecule-docker molecule-vagrant
pip install 'molecule-plugins[docker,vagrant]'
```

### Issue: "Collection requires ansible-core >=2.17"

**Cause:** Ansible version too old

**Solution:**
```bash
pip install --upgrade ansible>=11.0.0
ansible --version  # Verify ansible-core 2.17+
```

### Issue: Molecule tests fail with "cryptography" errors

**Cause:** cryptography library version incompatible

**Solution:**
```bash
pip install --upgrade cryptography>=3.3
```

### Issue: CI pipeline fails with import errors

**Cause:** Cached dependencies in CI

**Solution:**
- Clear GitHub Actions cache
- Force rebuild: Push with `[rebuild]` in commit message
- Check CI uses `pip install -r requirements-dev.txt`

### Issue: Ansible-lint reports new errors

**Cause:** Newer ansible-lint has stricter rules

**Solution:**
```bash
# Review new rules
ansible-lint --list-rules

# Disable specific rules if needed in .ansible-lint
# Or fix the issues (recommended)
```

## Rollback Plan

If you encounter critical issues:

### Quick Rollback

```bash
# Restore from backup
pip uninstall ansible molecule molecule-plugins pytest ansible-lint
pip install -r backup-requirements.txt
ansible-galaxy collection install community.general:7.0.0
ansible-galaxy collection install community.docker:3.0.0
ansible-galaxy collection install community.crypto:2.0.0
```

### Report Issues

If rollback is necessary, please:
1. Document the issue
2. Open a GitHub issue with:
   - Error messages
   - Python version
   - OS/Platform details
   - Steps to reproduce

## Testing Checklist

Before considering migration complete:

- [ ] `ansible --version` shows 11.0+ (with ansible-core 2.17+)
- [ ] `molecule --version` shows 25.0+
- [ ] `ansible-lint --version` shows 25.0+
- [ ] `pytest --version` shows 9.0+
- [ ] `yamllint .` passes without errors
- [ ] `ansible-lint` passes without errors
- [ ] `molecule test -s default` completes successfully
- [ ] All Docker tasks work correctly
- [ ] SSL certificate generation works
- [ ] Firewall configuration applies correctly
- [ ] Rancher container deploys successfully
- [ ] CI pipeline passes on GitHub Actions

## Performance Notes

### Faster Installation

Use pip cache to speed up repeated installations:
```bash
pip install -r requirements-dev.txt --cache-dir ~/.pip/cache
```

### Molecule Test Optimization

Run specific scenarios:
```bash
molecule test -s default  # Docker only
molecule test -s vagrant  # Vagrant only
```

Skip destroy to iterate faster:
```bash
molecule converge
molecule verify
# ... make changes ...
molecule converge
molecule verify
```

## Additional Resources

- [DEPENDENCY_AUDIT.md](DEPENDENCY_AUDIT.md) - Full audit report
- [Ansible Release Notes](https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html)
- [Molecule Documentation](https://docs.ansible.com/projects/molecule/)
- [ansible-lint Rules](https://ansible-lint.readthedocs.io/rules/)
- [pytest Documentation](https://docs.pytest.org/)

## Questions?

If you have questions about the migration:
1. Review [DEPENDENCY_AUDIT.md](DEPENDENCY_AUDIT.md) for rationale
2. Check the Troubleshooting section above
3. Open a GitHub issue with the `question` label

---

**Migration Status:** ✓ Files updated, ready for testing
**Next Steps:** Run testing checklist above
