# Dependency Audit Report

**Generated:** 2025-12-26
**Project:** ansible-role-rancher
**Branch:** claude/audit-dependencies-mjnhk7cnvrau52dh-z7KYg

## Executive Summary

This audit analyzed all dependencies in the ansible-role-rancher project for outdated packages, security vulnerabilities, and unnecessary bloat. The analysis covers Ansible Galaxy collections, Python development dependencies, and CI/CD configurations.

### Key Findings

**CRITICAL:**
- ⚠️ Ansible 2.9 in `requirements-dev.txt` is **end-of-life since April 2021** and contains unfixed security vulnerabilities
- ⚠️ Ansible Galaxy collection version constraints are significantly outdated

**HIGH PRIORITY:**
- 📦 Multiple Python packages are outdated by 2-4 major versions
- 🔄 Deprecated packages detected: `molecule-docker` and `molecule-vagrant` merged into `molecule-plugins`
- 📌 CI/CD pipeline installs dependencies without version pinning (security risk)

**MODERATE:**
- 🔍 Version inconsistency between `requirements.yml` and `molecule/default/requirements.yml`
- 📝 Redundant collection declarations across multiple files

---

## 1. Ansible Galaxy Collections

### Current Status

| Collection | Current Version | Latest Version | Status | Usage |
|------------|----------------|----------------|---------|-------|
| `community.general` | >=7.0.0 | 12.1.0 | ⚠️ **OUTDATED** | UFW firewall only |
| `community.docker` | >=3.0.0 | 4.7.0+ (5.x available) | ⚠️ **OUTDATED** | Extensive use |
| `community.crypto` | >=2.0.0 | 3.0.5 | ⚠️ **OUTDATED** | SSL certificates |

### Detailed Analysis

#### community.general (>=7.0.0 → 12.1.0)
- **Current:** >=7.0.0 (released ~2023)
- **Latest:** 12.1.0
- **Gap:** 5 major versions behind
- **Usage:** Only `community.general.ufw` module (firewall management)
- **Risk:** Low (limited use, UFW module is stable)
- **Recommendation:** Update to `>=12.0.0`

#### community.docker (>=3.0.0 → 4.7.0+)
- **Current:** >=3.0.0
- **Latest:** 4.7.0 (stable), 5.x (latest with breaking changes)
- **Gap:** 1-2 major versions behind
- **Usage:** Heavy use (docker_container, docker_volume, docker_volume_info, docker_container_info)
- **Risk:** Medium (core functionality depends on this)
- **Note:** Version 5.x requires ansible-core 2.17+ and drops Python 2.7 support
- **Recommendation:** Update to `>=4.7.0`, consider 5.x with Ansible core upgrade

#### community.crypto (>=2.0.0 → 3.0.5)
- **Current:** >=2.0.0
- **Latest:** 3.0.5
- **Gap:** 1 major version behind
- **Usage:** Extensive SSL certificate management (6 different modules)
- **Risk:** Medium-High (certificate security is critical)
- **Note:** Version 3.x requires ansible-core 2.17+ and cryptography library 3.3+
- **Recommendation:** Update to `>=3.0.0` for security improvements

### Version Inconsistency Issue

**Problem:** `requirements.yml` specifies versions, but `molecule/default/requirements.yml` does not:

```yaml
# requirements.yml
collections:
  - name: community.general
    version: ">=7.0.0"  # ✓ versioned

# molecule/default/requirements.yml
collections:
  - name: community.general  # ✗ no version!
```

**Risk:** Different versions could be installed in development vs testing
**Recommendation:** Synchronize version constraints across all files

---

## 2. Python Development Dependencies

### Current Status

| Package | Current Version | Latest Version | Status | Notes |
|---------|----------------|----------------|---------|-------|
| `ansible` | >=2.9 | 11.0.0 | 🚨 **CRITICAL** | EOL since 2021 |
| `molecule` | >=6.0 | 25.12.0 | ⚠️ **OUTDATED** | 19 versions behind |
| `molecule-docker` | >=2.0 | N/A | ⚠️ **DEPRECATED** | Use molecule-plugins |
| `molecule-vagrant` | >=2.0 | N/A | ⚠️ **DEPRECATED** | Use molecule-plugins |
| `python-vagrant` | >=1.0.0 | 1.0.0 | ✓ OK | Current |
| `pytest` | >=7.0 | 9.0.2 | ⚠️ **OUTDATED** | 2 major versions |
| `pytest-testinfra` | >=8.0 | Latest ~10.x | ⚠️ **OUTDATED** | ~2 versions |
| `ansible-lint` | >=6.0 | 25.11.0 | ⚠️ **OUTDATED** | 19 versions behind |
| `yamllint` | >=1.26 | Latest | ⚠️ **OUTDATED** | Check latest |
| `docker` | >=5.0.0 | Latest | ⚠️ **OUTDATED** | Check latest |

### Critical Security Issue: Ansible 2.9

**Status:** 🚨 **END-OF-LIFE since April 2021**

- **Final release:** 2.9.20 (April 12, 2021)
- **Security support ended:** April 26, 2021
- **Current gap:** 4+ years without security patches
- **Known vulnerabilities:** Multiple unfixed CVEs
- **Impact:** HIGH - Core automation framework with unpatched vulnerabilities

**Recommendation:**
```txt
# BEFORE (INSECURE)
ansible>=2.9

# AFTER (SECURE)
ansible>=11.0.0  # or ansible-core>=2.17.0
```

### Deprecated Packages: molecule-docker & molecule-vagrant

**Issue:** These standalone packages have been merged into `molecule-plugins`

**Migration Required:**
```txt
# BEFORE (DEPRECATED)
molecule>=6.0
molecule-docker>=2.0
molecule-vagrant>=2.0

# AFTER (CURRENT)
molecule>=25.0.0
molecule-plugins[docker]>=25.0.0
molecule-plugins[vagrant]>=25.0.0
```

**Important:** Uninstall old packages before installing plugins to avoid entry point conflicts:
```bash
pip uninstall molecule-docker molecule-vagrant
pip install 'molecule-plugins[docker,vagrant]'
```

### Python Version Requirements

Many updated packages require Python 3.10+:
- pytest 9.x requires Python >=3.10
- molecule 25.x requires Python >=3.10
- ansible-lint 25.x likely requires Python >=3.10

**Current CI:** Using Python 3.11 ✓ (Good)

---

## 3. CI/CD Pipeline Issues

### Unpinned Dependencies in `.github/workflows/ci.yml`

**Problem:** Dependencies installed without version pinning:

```yaml
# Line 28 - Lint job
pip install ansible ansible-lint yamllint

# Line 51 - Molecule job
pip install ansible molecule molecule-plugins[docker] docker
```

**Risks:**
1. **Non-reproducible builds:** Different versions installed over time
2. **Breaking changes:** New major versions could break CI unexpectedly
3. **Security:** No control over which versions are used
4. **Debugging difficulty:** Hard to reproduce CI failures locally

**Recommendation:** Pin all versions or use requirements file:

```yaml
# Option 1: Pin versions explicitly
pip install ansible==11.0.0 ansible-lint==25.11.0 yamllint==1.35.1

# Option 2: Use requirements file (PREFERRED)
pip install -r requirements-dev.txt
```

---

## 4. Unnecessary Bloat Analysis

### Collection Usage Efficiency

**Finding:** `community.general` is heavily underutilized

```yaml
# Installed: Entire community.general collection (500+ modules)
# Used: Only 1 module (community.general.ufw)
```

**Impact:**
- Larger installation size
- More dependencies to manage
- Slower collection updates

**Alternatives:**
1. Accept minimal bloat (collection is well-maintained)
2. Consider using `ansible.builtin.ufw` if available
3. Write custom firewall tasks using `ansible.builtin.command`

**Recommendation:** Keep collection (bloat is minimal, UFW module is reliable)

### Redundant Collection Declarations

**Finding:** Collections declared in 3 places:

1. `requirements.yml` (with versions)
2. `meta/main.yml` (without versions)
3. `molecule/default/requirements.yml` (without versions)

**Best Practice:**
- `requirements.yml`: Development/CI installation ✓
- `meta/main.yml`: Runtime dependencies for Galaxy ✓
- `molecule/default/requirements.yml`: Testing only (redundant?)

**Recommendation:** Keep current structure but synchronize versions

### Testing Dependencies

**Analysis:** Both Docker and Vagrant testing supported

**Usage:**
- `molecule-docker`: Active use in CI
- `molecule-vagrant`: Present but CI only uses Docker

**Question:** Is Vagrant testing still needed?

**Options:**
1. Keep both for local testing flexibility
2. Remove Vagrant support if unused
3. Add Vagrant scenario to CI if needed

**Recommendation:** Keep both (flexibility > minimal bloat)

---

## 5. Security Vulnerabilities

### Known Issues

1. **Ansible 2.9:** Multiple unfixed CVEs (EOL software)
2. **Outdated collections:** May contain security fixes in newer versions
3. **Unpinned CI dependencies:** Potential supply chain attack vector

### No Critical CVEs Found

**Searched:**
- ansible-lint: ✓ No known vulnerabilities
- pytest: ✓ No known vulnerabilities
- molecule: ✓ No known vulnerabilities
- Collections: ✓ No critical CVEs in used modules

**Note:** This doesn't mean vulnerabilities don't exist, only that none are publicly disclosed at audit time.

---

## Recommendations

### Priority 1: CRITICAL (Immediate Action Required)

#### 1.1 Upgrade Ansible from EOL 2.9
```diff
# requirements-dev.txt
- ansible>=2.9
+ ansible>=11.0.0
```

**Impact:** Security fixes, modern features, community support
**Effort:** Medium (test for compatibility)
**Risk if ignored:** High (unpatched vulnerabilities)

#### 1.2 Pin CI Dependencies
```diff
# .github/workflows/ci.yml
- pip install ansible ansible-lint yamllint
+ pip install -r requirements-dev.txt
```

**Impact:** Reproducible builds, supply chain security
**Effort:** Low
**Risk if ignored:** Medium (unexpected CI failures)

### Priority 2: HIGH (Complete within 1-2 weeks)

#### 2.1 Migrate to molecule-plugins
```diff
# requirements-dev.txt
  ansible>=11.0.0
- molecule>=6.0
- molecule-docker>=2.0
- molecule-vagrant>=2.0
+ molecule>=25.0.0
+ molecule-plugins[docker]>=25.8.0
+ molecule-plugins[vagrant]>=25.8.0
  python-vagrant>=1.0.0
```

**Before installing:** `pip uninstall molecule-docker molecule-vagrant`

#### 2.2 Update Ansible Galaxy Collections
```diff
# requirements.yml
collections:
  - name: community.general
-   version: ">=7.0.0"
+   version: ">=12.0.0"
  - name: community.docker
-   version: ">=3.0.0"
+   version: ">=4.7.0"
  - name: community.crypto
-   version: ">=2.0.0"
+   version: ">=3.0.0"
```

**Note:** community.docker 5.x and community.crypto 3.x require ansible-core 2.17+

#### 2.3 Update Python Testing Tools
```diff
# requirements-dev.txt
- pytest>=7.0
+ pytest>=9.0.0
- pytest-testinfra>=8.0
+ pytest-testinfra>=10.0.0
- ansible-lint>=6.0
+ ansible-lint>=25.0.0
- yamllint>=1.26
+ yamllint>=1.35.0
- docker>=5.0.0
+ docker>=7.0.0
```

### Priority 3: MEDIUM (Complete within 1 month)

#### 3.1 Synchronize Collection Versions
Add version constraints to `molecule/default/requirements.yml`:

```yaml
collections:
  - name: community.general
    version: ">=12.0.0"
  - name: community.docker
    version: ">=4.7.0"
  - name: community.crypto
    version: ">=3.0.0"
```

#### 3.2 Update meta/main.yml

```diff
# meta/main.yml
- min_ansible_version: "2.9"
+ min_ansible_version: "2.17"
```

### Priority 4: LOW (Maintenance)

#### 4.1 Consider Python Version Upgrade
Current CI uses Python 3.11 (good), but consider Python 3.12+ for:
- Performance improvements
- Security enhancements
- Better type hints

#### 4.2 Add Dependabot Configuration
Create `.github/dependabot.yml`:

```yaml
version: 2
updates:
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

---

## Implementation Plan

### Phase 1: Critical Security Fixes (Day 1)
1. Update `requirements-dev.txt` with Ansible 11.0+
2. Update CI workflow to use requirements file
3. Test locally: `molecule test`
4. Commit and push

### Phase 2: Dependency Modernization (Week 1)
1. Migrate to molecule-plugins
2. Update all Python packages
3. Update Ansible Galaxy collections
4. Update minimum Ansible version in meta
5. Test all scenarios
6. Update documentation

### Phase 3: CI/CD Hardening (Week 2)
1. Pin all GitHub Actions versions
2. Add dependency scanning
3. Set up Dependabot
4. Document dependency management

### Phase 4: Ongoing Maintenance
1. Review dependencies monthly
2. Monitor security advisories
3. Keep collections updated
4. Test before major version bumps

---

## Testing Checklist

Before merging dependency updates:

- [ ] Run `molecule test -s default` successfully
- [ ] Run `molecule test -s vagrant` if applicable
- [ ] Run `ansible-lint` without errors
- [ ] Run `yamllint .` without errors
- [ ] Test on Ubuntu 22.04 (jammy)
- [ ] Test on Ubuntu 24.04 (noble)
- [ ] Verify SSL certificate generation works
- [ ] Verify Docker container deployment works
- [ ] Verify firewall configuration works
- [ ] Check CI pipeline passes
- [ ] Review breaking changes in changelogs

---

## Resources

### Ansible Galaxy Collections
- [community.general](https://galaxy.ansible.com/community/general) - v12.1.0
- [community.docker](https://galaxy.ansible.com/community/docker) - v4.7.0 / v5.x
- [community.crypto](https://galaxy.ansible.com/community/crypto) - v3.0.5

### Python Packages
- [molecule](https://pypi.org/project/molecule/) - v25.12.0
- [molecule-plugins](https://pypi.org/project/molecule-plugins/) - v25.8.12
- [pytest](https://pypi.org/project/pytest/) - v9.0.2
- [ansible-lint](https://pypi.org/project/ansible-lint/) - v25.11.0

### Documentation
- [Ansible Release Schedule](https://docs.ansible.com/projects/ansible/latest/reference_appendices/release_and_maintenance.html)
- [Molecule Documentation](https://docs.ansible.com/projects/molecule/)
- [Community.Crypto Migration Guide](https://github.com/ansible-collections/community.crypto/blob/main/CHANGELOG.rst)

---

## Appendix A: Current Dependency Tree

```
requirements.yml (Ansible Galaxy Collections)
├── community.general >=7.0.0
├── community.docker >=3.0.0
└── community.crypto >=2.0.0

requirements-dev.txt (Python Packages)
├── ansible >=2.9 [EOL!]
├── molecule >=6.0
├── molecule-docker >=2.0 [DEPRECATED]
├── molecule-vagrant >=2.0 [DEPRECATED]
├── python-vagrant >=1.0.0
├── pytest >=7.0
├── pytest-testinfra >=8.0
├── ansible-lint >=6.0
├── yamllint >=1.26
└── docker >=5.0.0

meta/main.yml
├── min_ansible_version: "2.9" [EOL!]
└── collections: (same as requirements.yml)

CI Pipeline (.github/workflows/ci.yml)
├── Python 3.11
├── unpinned: ansible, ansible-lint, yamllint
└── unpinned: molecule, molecule-plugins[docker], docker
```

---

## Appendix B: Breaking Changes to Watch

### Ansible 2.9 → 11.0
- Python 2.7 dropped
- Many deprecated modules removed
- YAML parsing stricter
- Test with `--syntax-check` first

### community.docker 3.x → 5.x
- Requires ansible-core 2.17+
- Docker SDK 2.0.0+ required
- Some parameter names changed
- Review CHANGELOG before upgrade

### community.crypto 2.x → 3.x
- Requires ansible-core 2.17+
- cryptography library 3.3+ required
- Some module behaviors changed
- Test certificate generation thoroughly

### molecule 6.x → 25.x
- Plugin system redesigned
- Configuration syntax may differ
- Python 3.10+ required
- Review migration guide

---

## Conclusion

This Ansible role has **significant dependency debt** requiring immediate attention:

**Critical Issues:**
- 4-year-old EOL Ansible version with security vulnerabilities
- Collections outdated by 1-5 major versions
- Deprecated packages in use
- Unpinned CI dependencies

**Positive Notes:**
- No unnecessary dependencies found
- All collections are actively used
- Python 3.11 in CI is appropriate
- Test coverage exists

**Estimated Effort:**
- Critical fixes: 2-4 hours
- Full modernization: 1-2 days
- Testing and validation: 1 day
- Total: ~3-4 days of work

**Risk Assessment:**
- Current state: HIGH RISK (EOL software, security vulnerabilities)
- After updates: LOW RISK (modern, maintained dependencies)

**Next Steps:**
1. Review this report with team
2. Schedule dependency update sprint
3. Execute Phase 1 (critical security fixes) immediately
4. Plan Phases 2-4 based on team availability
5. Set up automated dependency monitoring

---

**Report End**
