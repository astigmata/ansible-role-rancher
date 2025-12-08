.PHONY: help install test test-full test-quick lint clean

help: ## Display this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

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
	@vagrant up
	@echo ""
	@echo "✓ VM created and Rancher deployed"
	@echo "Running verification..."
	@ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory test_verify.yml -e @test_vars.yml
	@echo ""
	@echo "✓ Tests completed!"
	@echo "To destroy the VM: make destroy-vagrant"

test-quick: ## Quick tests with Docker (skip Rancher container - infra validation only)
	@echo "⚡ Quick tests with Docker (infrastructure only)"
	@echo "⚠️  Note: Rancher container will not be deployed (Docker-in-Docker limitation)"
	molecule test -s default --destroy=never

converge: ## Create and converge Molecule instance (default scenario)
	molecule converge

converge-vagrant: ## Create and converge with Vagrant
	vagrant up

verify: ## Verify Molecule instance
	molecule verify

verify-vagrant: ## Verify Vagrant instance
	ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory test_verify.yml -e @test_vars.yml

destroy: ## Destroy Molecule instance (all scenarios)
	molecule destroy -s default || true
	vagrant destroy -f || true

destroy-vagrant: ## Destroy only the Vagrant VM
	vagrant destroy -f

clean: ## Clean temporary files
	molecule destroy -s default || true
	vagrant destroy -f || true
	rm -rf .vagrant/
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete

idempotence: ## Test idempotence with Vagrant
	@echo "Testing idempotence..."
	@vagrant up --provision
	@echo "First run completed, launching 2nd run..."
	@ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory test_playbook.yml -e @test_vars.yml --check --diff

list: ## List active Molecule instances
	@echo "=== Molecule instances ==="
	@molecule list -s default || true
	@echo ""
	@echo "=== Vagrant VMs ==="
	@vagrant status || echo "No Vagrant VMs"
