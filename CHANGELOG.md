# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Debian 11/12/13 support
- Multi-platform Molecule testing (Ubuntu + Debian)
- `argument_specs.yml` for Ansible Galaxy documentation
- CI matrix testing multiple Ansible versions
- LICENSE file (MIT)
- This CHANGELOG file

### Changed
- Replaced `ntp` package with `systemd-timesyncd` for modern distributions
- Consolidated API stability checks (6 tasks → 2 tasks)
- Renamed `rancher_skip_container_deploy` to `rancher_test_mode`
- Simplified certificate display using `.values() | list | join()`
- Updated minimum Ansible version to 2.17

### Removed
- Rocky Linux/AlmaLinux support (K3s cgroup v2 incompatibility)
- `ansible.posix` collection dependency (not needed)
- `ntp` package dependency

### Fixed
- Time synchronization on Debian 13 (conditional systemd-timesyncd)

## [1.0.0] - 2025-12-29

### Added
- Initial release
- Single-node Rancher deployment with Docker
- Ubuntu 20.04, 22.04, 24.04 support
- SSL certificate management (self-signed, provided, Let's Encrypt)
- UFW firewall configuration
- Molecule testing with Docker
- Vagrant testing for full deployment
- GitHub Actions CI/CD
- Comprehensive documentation

### Security
- Password complexity validation (12+ chars, 1+ digit)
- SSL/TLS certificate validation
- Secure Docker installation from official repository

[Unreleased]: https://github.com/astigmata/ansible-role-rancher/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/astigmata/ansible-role-rancher/releases/tag/v1.0.0
