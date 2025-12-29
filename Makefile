.PHONY: help install test test-full test-quick lint clean \
	test-ubuntu up-ubuntu ssh-ubuntu destroy-ubuntu reload-ubuntu provision-ubuntu \
	destroy-all status list converge verify idempotence destroy-vm

# Default Vagrantfile (Ubuntu only)
VAGRANT_FILE ?= Vagrantfile.ubuntu
VAGRANT_CMD = VAGRANT_VAGRANTFILE=$(VAGRANT_FILE) vagrant

help: ## Display this help
	@echo ""
	@echo "Ansible Rancher Role - Makefile"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ""

install: ## Install development dependencies
	pip install -r requirements-dev.txt
	pip install molecule-vagrant python-vagrant
	ansible-galaxy collection install -r molecule/default/requirements.yml

lint: ## Run linters (yamllint and ansible-lint)
	yamllint .
	ansible-lint .

test: test-full ## Alias for test-full

test-full: ## COMPLETE test with Vagrant (actually deploys Rancher) - RECOMMENDED
	@echo "🚀 Running complete tests with Vagrant (real VM)"
	@echo "⚠️  Prerequisites: VirtualBox and Vagrant installed"
	@echo "⏱️  Estimated duration: 10-15 minutes"
	@echo "📍 IP Address: 192.168.56.10"
	@echo ""
	@VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu vagrant destroy -f 2>/dev/null || true
	@VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu vagrant up
	@echo ""
	@echo "✅ Test completed successfully!"
	@echo "🌐 Access Rancher: https://192.168.56.10:8443"
	@echo "🔑 Login: admin / TestPassword123!"
	@echo ""
	@echo "To destroy: make destroy-ubuntu"

test-quick: ## Quick tests with Docker (skip Rancher container - infra validation only)
	@echo "⚡ Quick tests with Docker (infrastructure only)"
	@echo "⚠️  Note: Rancher container will not be deployed (Docker-in-Docker limitation)"
	molecule test -s default --destroy=never

converge: ## Create and converge Molecule instance (Docker scenario)
	@echo "Creating and provisioning container with Molecule..."
	molecule converge -s default

verify: ## Verify Molecule instance (Docker scenario)
	@echo "Running verification tests with Molecule..."
	molecule verify -s default

idempotence: ## Test idempotence with Vagrant
	@echo "Testing idempotence with Vagrant..."
	@VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu vagrant up --provision
	@echo ""
	@echo "✅ First run completed"
	@echo "🔄 Running second provision (should show no changes)..."
	@VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu vagrant provision

destroy-vm: ## Destroy test VM
	@echo "Destroying test VM..."
	@VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu vagrant destroy -f

destroy: ## Destroy all VMs and containers
	@echo "Destroying all test environments..."
	@molecule destroy -s default 2>/dev/null || true
	@VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu vagrant destroy -f 2>/dev/null || true

clean: ## Clean temporary files and destroy all VMs
	@echo "🧹 Cleaning up..."
	@molecule destroy -s default 2>/dev/null || true
	@VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu vagrant destroy -f 2>/dev/null || true
	@rm -rf .vagrant/ 2>/dev/null || true
	@rm -rf molecule/*/.vagrant/ 2>/dev/null || true
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "✓ Cleanup complete"

list: ## List active instances
	@echo "=== Molecule (Docker) ==="
	@molecule list -s default 2>/dev/null || echo "No Molecule instances"
	@echo ""
	@echo "=== Vagrant VM (Ubuntu 22.04) ==="
	@VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu vagrant status 2>/dev/null || echo "No Vagrant VM"

# ============================================================================
# Ubuntu 22.04 targets
# ============================================================================

test-ubuntu: ## Complete test on Ubuntu 22.04
	@echo "🐧 Running complete tests on Ubuntu 22.04"
	@echo "⚠️  Prerequisites: VirtualBox and Vagrant installed"
	@echo "⏱️  Estimated duration: 10-15 minutes"
	@echo "📍 IP Address: 192.168.56.10"
	@echo ""
	@VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu vagrant up
	@echo ""
	@echo "✓ Ubuntu VM created and Rancher deployed"
	@echo "Access: https://192.168.56.10:8443"
	@echo "Login: admin / admin123456789"
	@echo ""
	@echo "To destroy: make destroy-ubuntu"

up-ubuntu: ## Create and provision Ubuntu VM
	@echo "🐧 Starting Ubuntu 22.04 VM..."
	@VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu vagrant up
	@echo ""
	@echo "✓ Ubuntu VM ready at https://192.168.56.10:8443"

ssh-ubuntu: ## SSH into Ubuntu VM
	@VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu vagrant ssh

destroy-ubuntu: ## Destroy Ubuntu VM
	@echo "🗑️  Destroying Ubuntu VM..."
	@VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu vagrant destroy -f
	@echo "✓ Ubuntu VM destroyed"

reload-ubuntu: ## Reload Ubuntu VM
	@echo "🔄 Reloading Ubuntu VM..."
	@VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu vagrant reload

provision-ubuntu: ## Re-provision Ubuntu VM
	@echo "⚙️  Re-provisioning Ubuntu VM..."
	@VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu vagrant provision

# ============================================================================
# Combined targets
# ============================================================================

destroy-all: ## Destroy all VMs (Ubuntu and default)
	@echo "Destroying all VMs..."
	@vagrant destroy -f 2>/dev/null || true
	@VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu vagrant destroy -f 2>/dev/null || true
	@echo "All VMs destroyed"

status: ## Show status of all VMs
	@echo "Status:"
	@echo ""
	@echo "=== Molecule (Docker) ==="
	@molecule list -s default 2>/dev/null || echo "No Molecule instances"
	@echo ""
	@echo "=== Vagrant VM (Ubuntu 22.04) ==="
	@VAGRANT_VAGRANTFILE=Vagrantfile.ubuntu vagrant status 2>/dev/null || echo "No Vagrant VM"
