# Performance Analysis Report
## Ansible Role: rancher

**Analysis Date:** 2025-12-26 (Updated: 2025-12-29)
**Analysis Type:** Performance Anti-patterns, N+1 Queries, Inefficient Algorithms
**Status:** ✅ All critical issues resolved

---

## Executive Summary

This Ansible role for Rancher deployment contains several performance anti-patterns that can impact execution time, especially on slower networks or hardware. The most critical issues involve sequential API polling, redundant package cache updates, and inefficient loop constructs.

**Severity Levels:**
- 🔴 **HIGH**: Significant performance impact (>30s potential savings)
- 🟡 **MEDIUM**: Moderate impact (10-30s potential savings)
- 🟢 **LOW**: Minor impact (<10s potential savings)

---

## Critical Performance Issues

### 🔴 1. Inefficient Loop-Based Stability Checks
**Location:** `tasks/deploy.yml:52-62`

```yaml
- name: Verify API stability (check multiple times to avoid K3s restarts)
  ansible.builtin.uri:
    url: "https://localhost:{{ rancher_port }}/ping"
    validate_certs: false
    status_code: 200
    follow_redirects: none
  register: stability_check
  failed_when: false
  loop: "{{ range(1, 4) | list }}"
  delay: 5
```

**Problem:**
- Using `loop` with `delay` doesn't actually delay between iterations in Ansible
- The `delay` parameter in a loop context is ignored; it only works with `until`/`retries`
- This creates 3 rapid-fire API calls instead of spaced checks
- Misleading code that doesn't achieve its stated purpose

**Impact:** Medium (functional issue masquerading as performance issue)

**Recommendation:**
```yaml
- name: Verify API stability with proper delays
  ansible.builtin.uri:
    url: "https://localhost:{{ rancher_port }}/ping"
    validate_certs: false
    status_code: 200
    follow_redirects: none
  register: stability_check
  until: stability_check.status == 200
  retries: 3
  delay: 5
  when: not (rancher_skip_container_deploy | default(false) | bool)
```

---

### 🔴 2. Redundant APT Cache Updates
**Location:** `tasks/docker-debian.yml:16` and `tasks/docker-debian.yml:55`

```yaml
# Line 5-16: First package installation
- name: Install system dependencies and NTP (Debian/Ubuntu)
  ansible.builtin.package:
    name: [...]
    state: present
    update_cache: true  # ← Cache update #1

# Line 46-55: Second package installation
- name: Install Docker CE (Debian/Ubuntu)
  ansible.builtin.package:
    name: [...]
    state: present
    update_cache: true  # ← Cache update #2 (redundant)
```

**Problem:**
- APT cache is updated twice unnecessarily
- Each `apt update` can take 5-30 seconds depending on mirror speed
- Cache from first update is still valid for second package installation

**Impact:** High (10-30 seconds wasted on every run)

**Recommendation:**
```yaml
# Option 1: Single update at the beginning
- name: Update apt cache
  ansible.builtin.apt:
    update_cache: true
    cache_valid_time: 3600  # Only update if older than 1 hour

- name: Install system dependencies and NTP (Debian/Ubuntu)
  ansible.builtin.package:
    name: [...]
    state: present
    # No update_cache needed

- name: Install Docker CE (Debian/Ubuntu)
  ansible.builtin.package:
    name: [...]
    state: present
    # No update_cache needed
```

---

### 🟡 3. Serial Firewall Rule Creation
**Location:** `tasks/firewall-debian.yml:10-17`

```yaml
- name: Configure UFW - Allow Rancher ports
  community.general.ufw:
    rule: allow
    port: "{{ item }}"
    proto: tcp
  loop:
    - "{{ rancher_http_port }}"
    - "{{ rancher_port }}"
```

**Problem:**
- Each UFW rule triggers a separate iptables update
- UFW module doesn't support batch operations
- Two separate syscalls to modify firewall rules

**Impact:** Medium (2-5 seconds on slower systems)

**Recommendation:**
```yaml
# This is acceptable, but could be optimized with a custom script
# For only 2 ports, the current approach is reasonable
# Consider batching only if managing 10+ ports

# Alternative (if many ports):
- name: Configure UFW - Allow Rancher ports (batch)
  ansible.builtin.shell: |
    {% for port in [rancher_http_port, rancher_port] %}
    ufw allow {{ port }}/tcp
    {% endfor %}
  args:
    executable: /bin/bash
  changed_when: false
```

**Note:** Current implementation is acceptable for 2 ports. Only optimize if port list grows significantly.

---

### 🟡 4. Shell Command for Docker Exec
**Location:** `tasks/deploy.yml:107-121`

```yaml
- name: Verify K3s API Aggregation is ready
  ansible.builtin.shell: |
    set -o pipefail
    docker exec {{ rancher_container_name }} kubectl get apiservices \
      -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.conditions[?(@.type=="Available")].status}{"\n"}{end}' 2>/dev/null | \
    awk '{if ($2 != "True") {print $1 " not available (status: " $2 ")"; exit 1}}'
```

**Problem:**
- Using shell with docker exec instead of native modules
- Complex piped shell command reduces readability
- No native Ansible module for docker exec queries
- Shell execution overhead vs potential API-based approach

**Impact:** Medium (performance acceptable, but maintainability concern)

**Recommendation:**
```yaml
# Current approach is acceptable for this use case
# Native alternative would require kubernetes.core collection
# and more complex API authentication

# Alternative (requires kubernetes.core):
- name: Get K3s API services status
  kubernetes.core.k8s_info:
    kind: APIService
    kubeconfig: /etc/rancher/k3s/k3s.yaml  # Would need to extract from container
  register: apiservices
  # ... then filter with json_query
```

**Note:** Shell approach is acceptable here. Native k8s modules would require additional complexity to extract kubeconfig from container.

---

### 🟢 5. Sequential Certificate Stat Operations
**Location:** `tasks/certificates.yml:25-31`

```yaml
- name: Check certificate files exist
  ansible.builtin.stat:
    path: "{{ item }}"
  register: cert_files_check
  loop:
    - "{{ rancher_ssl_cert_dir }}/cert.pem"
    - "{{ rancher_ssl_cert_dir }}/key.pem"
```

**Problem:**
- Two separate stat syscalls
- Minor overhead from loop iteration

**Impact:** Low (<1 second)

**Recommendation:**
```yaml
# Current implementation is fine for 2 files
# Only optimize if checking many files (10+)

# Alternative (not recommended for just 2 files):
- name: Check certificate files exist (combined)
  ansible.builtin.find:
    paths: "{{ rancher_ssl_cert_dir }}"
    patterns: "cert.pem,key.pem"
    file_type: file
  register: cert_files_check
```

**Note:** Current approach is clear and performant. Don't optimize.

---

### 🟢 6. Shell Command for Certificate Concatenation
**Location:** `tasks/certificates-letsencrypt.yml:65-69`

```yaml
- name: Create/Update combined certificate file (regenerate if cert renewed)
  ansible.builtin.shell: >
    cat {{ rancher_ssl_cert_dir }}/cert.pem {{ rancher_ssl_cert_dir }}/key.pem
    > {{ rancher_ssl_cert_dir }}/tls.pem
  when: cert_copy.changed or key_copy.changed
  changed_when: true
```

**Problem:**
- Using shell `cat` instead of native Ansible modules
- Minor performance overhead from shell execution

**Impact:** Low (<1 second)

**Recommendation:**
```yaml
- name: Read certificate content
  ansible.builtin.slurp:
    src: "{{ rancher_ssl_cert_dir }}/cert.pem"
  register: cert_content
  when: cert_copy.changed or key_copy.changed

- name: Read key content
  ansible.builtin.slurp:
    src: "{{ rancher_ssl_cert_dir }}/key.pem"
  register: key_content
  when: cert_copy.changed or key_copy.changed

- name: Create combined certificate file
  ansible.builtin.copy:
    content: |
      {{ cert_content.content | b64decode }}
      {{ key_content.content | b64decode }}
    dest: "{{ rancher_ssl_cert_dir }}/tls.pem"
    mode: '0600'
  when: cert_copy.changed or key_copy.changed
```

**Note:** Native approach is more verbose. Shell command is acceptable here for simplicity.

---

## Architectural Performance Considerations

### 7. Multiple Sequential API Health Checks
**Location:** `tasks/deploy.yml:40-105`

**Current Flow:**
1. Wait for `/ping` endpoint (retries: 90, delay: 10s) = up to 900s
2. Check API stability 3 times (delay: 5s) = 15s
3. Wait for `/healthz` endpoint (retries: 60, delay: 10s) = up to 600s
4. Wait for `/v3-public/authProviders` (retries: 60, delay: 10s) = up to 600s
5. Wait for `/v3/clusters/local` (retries: 60, delay: 10s) = up to 600s
6. Verify K3s API Aggregation (retries: 60, delay: 10s) = up to 600s

**Total Worst Case:** 3,315 seconds (~55 minutes)

**Analysis:**
- Sequential checks are necessary for proper initialization validation
- Each check depends on the previous one succeeding
- Cannot be parallelized without risking false positives
- Timeouts are appropriate for production-grade waiting

**Recommendation:**
✅ **KEEP AS-IS** - This is proper production-ready initialization waiting. The sequential nature ensures stability.

**Potential Minor Optimization:**
```yaml
# Reduce initial delay for ping check since it's just basic availability
- name: Wait for Rancher API availability
  ansible.builtin.uri:
    url: "https://localhost:{{ rancher_port }}/ping"
    validate_certs: false
    status_code: 200
    follow_redirects: none
  register: result
  until: result.status == 200
  retries: 120  # More retries
  delay: 5      # But shorter delays for faster feedback
```

---

### 8. No Async Task Execution
**Location:** Multiple locations

**Observation:**
Long-running tasks execute synchronously:
- Docker installation (`docker-debian.yml`)
- Package installations
- Docker container startup

**Analysis:**
- Ansible async mode could parallelize some operations
- However, most tasks have dependencies that prevent parallelization
- Package installation must complete before Docker usage
- Docker must be installed before container deployment

**Recommendation:**
✅ **KEEP AS-IS** - Dependencies make async unnecessary and potentially dangerous.

---

### 9. No Gather Facts Control
**Location:** Implicit in all playbooks

**Observation:**
- Role doesn't explicitly control fact gathering
- Facts are gathered by default on every playbook run
- Fact gathering can take 2-5 seconds per host

**Analysis:**
- Role heavily uses facts: `ansible_os_family`, `ansible_architecture`, `ansible_default_ipv4`, etc.
- Facts are necessary for dynamic configuration
- Gathering time is acceptable overhead

**Recommendation:**
```yaml
# In playbooks using this role, consider:
- name: Deploy Rancher
  hosts: all
  gather_facts: true
  gather_subset:
    - '!all'
    - '!min'
    - hardware
    - network
    - virtual
    - distribution
  roles:
    - role: rancher
```

**Impact:** Could save 1-3 seconds by gathering only needed fact subsets.

---

## Non-Issues (Good Practices Identified)

### ✅ Proper Use of `when` Conditions
All tasks properly use conditional execution to avoid unnecessary work:
- `tasks/main.yml:16` - Firewall tasks only when configured
- `tasks/docker.yml:32` - Docker group only for non-root users
- `tasks/certificates.yml:14,18,22` - SSL mode-specific tasks

### ✅ Idempotent Task Design
Most tasks are properly idempotent:
- Certificate generation checks for existing files
- Docker installation checks package state
- Container deployment uses desired state

### ✅ Efficient Use of Native Modules
Good use of native Ansible modules:
- `community.docker.docker_container` instead of `docker` command
- `community.crypto.*` modules for certificate operations
- `ansible.builtin.package` for cross-distro compatibility

---

## Quantified Performance Impact

### Current Role Execution Time (Estimated)
Based on typical execution on a 2 vCPU, 4GB RAM VM:

| Phase | Time | Bottleneck |
|-------|------|------------|
| Validation | 1-2s | Fact gathering |
| Docker Installation | 30-90s | Network (package download) |
| Certificate Generation | 5-10s | Crypto operations |
| Firewall Configuration | 2-5s | UFW rule application |
| Container Deployment | 10-20s | Docker image pull |
| API Initialization Wait | 120-600s | K3s cluster startup |
| **Total** | **170-730s** | **Primarily API wait** |

### Optimized Execution Time (After Fixes)
Applying HIGH and MEDIUM priority fixes:

| Optimization | Time Saved |
|--------------|------------|
| Fix stability check loop | 0s (functional fix) |
| Remove redundant apt update | 10-30s |
| ~~Batch firewall rules~~ | ~~2-4s~~ (not worth complexity) |
| **Total Savings** | **10-30s** |

**New Total:** 160-700s (6-14% improvement)

---

## Recommendations Priority

### Must Fix (🔴 HIGH)
1. **Remove redundant apt cache update** - Easy fix, significant impact
2. **Fix stability check loop** - Functional issue that needs correction

### Should Fix (🟡 MEDIUM)
3. **Consider caching optimizations** - If role is run frequently

### Nice to Have (🟢 LOW)
4. Everything else - Current implementation is acceptable

---

## Implementation Checklist

- [x] ~~Remove `update_cache: true` from second package task in `docker-debian.yml:55`~~ ✅ Fixed: Using `cache_valid_time: 3600`
- [x] ~~Add `cache_valid_time: 3600` to first package task in `docker-debian.yml:16`~~ ✅ Fixed
- [x] ~~Replace stability check loop with proper `retries`/`delay` in `deploy.yml:52-62`~~ ✅ Fixed: Consolidated to single task with `until`/`retries`
- [x] Document why sequential API checks are necessary (not a performance issue) ✅ Documented above
- [ ] Consider fact gathering optimization in example playbooks (optional)

---

## Conclusion

This Ansible role is generally well-written with good use of native modules and idempotent patterns. The main performance issues are:

1. **Redundant package cache updates** - Easy fix with significant impact
2. **Broken stability check loop** - More of a functional bug than performance issue

The long execution time (up to 12+ minutes) is primarily due to **necessary waiting for Rancher/K3s initialization**, not performance anti-patterns. This is expected and appropriate for production deployments.

**Overall Assessment:** 🟢 Good performance profile with minor optimizations needed.
