# Performance Analysis - Ansible Role Rancher

## Executive Summary

This document identifies performance anti-patterns, inefficient operations, and optimization opportunities in the ansible-role-rancher codebase. While Ansible roles have different performance characteristics than traditional applications, several inefficiencies can impact deployment time and resource usage.

---

## Critical Issues

### 1. **Multiple APT Cache Updates** (HIGH IMPACT)
**Location:** `tasks/docker-debian.yml`

**Issue:** The role performs multiple `apt update` operations unnecessarily:
- Line 16: `update_cache: true` when installing system dependencies
- Line 55: `update_cache: true` when installing Docker packages

**Impact:**
- Each `apt update` downloads package indexes from all configured repositories
- On slow networks, this can add 30-60 seconds per update
- Completely unnecessary to update cache twice in the same playbook run

**Recommendation:**
```yaml
# Solution: Only update cache once at the beginning
- name: Update APT cache
  ansible.builtin.apt:
    update_cache: true
    cache_valid_time: 3600  # Cache valid for 1 hour

- name: Install system dependencies and NTP (Debian/Ubuntu)
  ansible.builtin.package:
    name:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
      - lsb-release
      - python3-docker
      - ntp
    state: present
    # Remove update_cache: true

- name: Install Docker CE (Debian/Ubuntu)
  ansible.builtin.package:
    name:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-buildx-plugin
      - docker-compose-plugin
    state: present
    # Remove update_cache: true
```

**Estimated Time Savings:** 30-60 seconds per deployment

---

### 2. **Expensive Docker Exec in Retry Loop** (MEDIUM-HIGH IMPACT)
**Location:** `tasks/deploy.yml:107-121`

**Issue:** Executing `kubectl get apiservices` inside the container repeatedly in a retry loop:
```yaml
- name: Verify K3s API Aggregation is ready
  ansible.builtin.shell: |
    set -o pipefail
    docker exec {{ rancher_container_name }} kubectl get apiservices \
      -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.conditions[?(@.type=="Available")].status}{"\n"}{end}' 2>/dev/null | \
    awk '{if ($2 != "True") {print $1 " not available (status: " $2 ")"; exit 1}}'
  retries: "{{ rancher_full_init_retries | default(60) }}"
  delay: "{{ rancher_full_init_delay | default(10) }}"
```

**Problems:**
- `docker exec` spawns a new process for each retry (potentially 60 times)
- JSONPath parsing on the entire apiservices list every time
- AWK processing adds overhead
- Complex shell pipeline that's hard to debug

**Impact:**
- Each iteration spawns multiple processes (docker exec, kubectl, awk)
- Potentially runs 60 times = 60 process spawns
- Inefficient resource usage on host

**Recommendation:**
```yaml
# Alternative: Use docker container logs or a simpler readiness check
# Or reduce complexity by checking a single critical API service
- name: Verify K3s API Aggregation is ready
  ansible.builtin.command:
    cmd: docker exec {{ rancher_container_name }} kubectl get --raw /readyz/aggregator
  register: apiservices_check
  until: apiservices_check.rc == 0
  retries: "{{ rancher_full_init_retries | default(60) }}"
  delay: "{{ rancher_full_init_delay | default(10) }}"
  changed_when: false
  failed_when: false
```

**Estimated Time Savings:** Reduces CPU overhead, no direct time savings but better resource usage

---

### 3. **Sequential Firewall Rule Configuration** (LOW-MEDIUM IMPACT)
**Location:** `tasks/firewall-debian.yml:10-17`

**Issue:** UFW rules are configured one at a time in a loop:
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

**Problems:**
- Each loop iteration potentially reloads UFW rules
- Two separate UFW operations instead of batch configuration
- Unnecessary overhead for just 2 ports

**Impact:**
- UFW may reload after each rule addition
- Minor performance impact (1-2 seconds total)

**Recommendation:**
```yaml
# Option 1: Use with_items inline (cleaner)
- name: Configure UFW - Allow Rancher HTTP port
  community.general.ufw:
    rule: allow
    port: "{{ rancher_http_port }}"
    proto: tcp

- name: Configure UFW - Allow Rancher HTTPS port
  community.general.ufw:
    rule: allow
    port: "{{ rancher_port }}"
    proto: tcp

# Option 2: Use port range if ports are consecutive
# (Only if rancher_http_port and rancher_port are consecutive)
```

**Note:** This is a minor issue. The loop is acceptable for 2 items, but separating them is clearer.

---

### 4. **Inefficient Certificate Concatenation** (LOW IMPACT)
**Location:** `tasks/certificates-letsencrypt.yml:64-69`

**Issue:** Using shell to concatenate certificate files:
```yaml
- name: Create/Update combined certificate file (regenerate if cert renewed)
  ansible.builtin.shell: >
    cat {{ rancher_ssl_cert_dir }}/cert.pem {{ rancher_ssl_cert_dir }}/key.pem
    > {{ rancher_ssl_cert_dir }}/tls.pem
  when: cert_copy.changed or key_copy.changed
  changed_when: true
```

**Problems:**
- Spawns a shell process for a simple file operation
- Using shell instead of native Ansible modules
- Less idempotent (always reports changed when condition is met)

**Impact:** Minimal (< 1 second), but not idiomatic Ansible

**Recommendation:**
```yaml
- name: Create/Update combined certificate file
  ansible.builtin.assemble:
    src: "{{ rancher_ssl_cert_dir }}"
    dest: "{{ rancher_ssl_cert_dir }}/tls.pem"
    regexp: '^(cert|key)\.pem$'
    mode: '0600'
  when: cert_copy.changed or key_copy.changed

# OR use template module with lookup
- name: Create combined certificate file
  ansible.builtin.copy:
    content: |
      {{ lookup('file', rancher_ssl_cert_dir + '/cert.pem') }}
      {{ lookup('file', rancher_ssl_cert_dir + '/key.pem') }}
    dest: "{{ rancher_ssl_cert_dir }}/tls.pem"
    mode: '0600'
  when: cert_copy.changed or key_copy.changed
```

---

### 5. **Redundant File Copy Operation** (LOW IMPACT)
**Location:** `tasks/certificates-provided.yml:82-90`

**Issue:** Copying a file to itself unnecessarily:
```yaml
- name: Use cert as fullchain if no chain provided
  ansible.builtin.copy:
    src: "{{ rancher_ssl_cert_dir }}/cert.pem"
    dest: "{{ rancher_ssl_cert_dir }}/fullchain.pem"
    remote_src: true
    mode: '0644'
```

**Problems:**
- Duplicates file content instead of using a symlink
- Wastes disk space (minimal, but unnecessary)
- Copy operation is slower than symlink

**Impact:** Minimal disk space and time (< 1 second)

**Recommendation:**
```yaml
- name: Symlink cert as fullchain if no chain provided
  ansible.builtin.file:
    src: "{{ rancher_ssl_cert_dir }}/cert.pem"
    dest: "{{ rancher_ssl_cert_dir }}/fullchain.pem"
    state: link
    force: true
  when: rancher_ssl_chain_path is not defined or rancher_ssl_chain_path | length == 0
```

---

## Design Considerations (Not Issues)

### 6. **Multiple Sequential API Polling Tasks**
**Location:** `tasks/deploy.yml:40-105`

**Observation:** The deployment performs multiple sequential health checks:
1. Wait for `/ping` endpoint (line 40-50)
2. Verify API stability with 3 checks (line 52-69)
3. Wait for `/healthz` endpoint (line 71-81)
4. Wait for `/v3-public/authProviders` (line 83-93)
5. Wait for local cluster creation (line 95-105)

**Analysis:** This is **NOT a performance issue** - it's intentional and necessary:
- Each check validates a different initialization stage
- Rancher/K3s initialization is complex and multi-stage
- Waiting for each stage prevents race conditions
- The delays and retries are configurable via variables

**Recommendation:** No change needed. This is proper deployment validation.

---

### 7. **API Stability Check Loop**
**Location:** `tasks/deploy.yml:52-69`

**Current Implementation:**
```yaml
- name: Verify API stability (check multiple times to avoid K3s restarts)
  ansible.builtin.uri:
    url: "https://localhost:{{ rancher_port }}/ping"
    validate_certs: false
    status_code: 200
  register: stability_check
  failed_when: false
  loop: "{{ range(1, 4) | list }}"
  delay: 5
```

**Analysis:** This is acceptable but could be slightly optimized:
- Uses `loop` with `delay` parameter
- Runs 3 checks with 5-second delays between them
- The `failed_when: false` prevents immediate failure

**Minor Optimization:**
```yaml
# More explicit approach with until/retries
- name: Verify API stability (check multiple times to avoid K3s restarts)
  ansible.builtin.uri:
    url: "https://localhost:{{ rancher_port }}/ping"
    validate_certs: false
    status_code: 200
  register: stability_check
  until: stability_check.status == 200
  retries: 3
  delay: 5
  failed_when: stability_check.failed and stability_check.attempts >= 3
```

But the current implementation is fine for tracking all attempts.

---

## No Issues Found

### ✅ **No N+1 Query Problems**
This is an Ansible role (infrastructure as code), not an application with database queries. There are no N+1 database query patterns.

### ✅ **No Unnecessary Re-renders**
Not applicable - this is Ansible (imperative infrastructure provisioning), not a reactive UI framework.

### ✅ **No Algorithmic Inefficiencies**
- No inefficient algorithms detected
- No nested loops causing O(n²) complexity
- Jinja2 filters are used appropriately
- All loops iterate over small, bounded collections

---

## Priority Recommendations

### High Priority
1. **Fix duplicate APT cache updates** in `tasks/docker-debian.yml`
   - Impact: 30-60 seconds saved per deployment
   - Effort: 5 minutes
   - Risk: Low

### Medium Priority
2. **Simplify K3s API check** in `tasks/deploy.yml`
   - Impact: Better resource usage, easier debugging
   - Effort: 15 minutes
   - Risk: Medium (needs testing)

### Low Priority
3. **Use native Ansible modules** instead of shell commands
   - Files: `certificates-letsencrypt.yml`, `certificates-provided.yml`
   - Impact: Cleaner code, better idempotency
   - Effort: 10 minutes each
   - Risk: Low

---

## Performance Metrics

### Current Estimated Deployment Time
- Docker installation: ~2-4 minutes (depends on network)
- Certificate generation: ~5-10 seconds
- Rancher container start: ~30 seconds
- API initialization wait: ~2-10 minutes (depends on hardware)
- **Total: ~5-15 minutes**

### After Optimizations
- Docker installation: **~1.5-3 minutes** (30-60s faster)
- Other tasks: Same or slightly improved
- **Total: ~4-14 minutes**

### Performance by Hardware
Based on `defaults/main.yml` requirements:
- Minimum (2 vCPU, 3.5GB RAM): ~10-15 minutes
- Recommended (4 vCPU, 8GB RAM): ~5-8 minutes
- High-end (8+ vCPU, 16GB+ RAM): ~3-5 minutes

---

## Conclusion

The codebase is generally well-written with appropriate retry mechanisms and health checks. The main performance issue is the **duplicate APT cache updates**, which should be fixed immediately. Other issues are minor optimizations that improve code quality and resource usage but don't significantly impact deployment time.

The multiple sequential API checks in `deploy.yml` are **intentional and correct** - they ensure Rancher is fully initialized before reporting success. This is proper infrastructure provisioning practice.

## Testing Recommendations

After implementing fixes:
1. Test on minimum hardware (2 vCPU, 3.5GB RAM) to ensure timeouts are adequate
2. Verify APT cache optimization doesn't break package installation
3. Test all three SSL modes (selfsigned, provided, letsencrypt)
4. Run molecule tests to ensure no regression
