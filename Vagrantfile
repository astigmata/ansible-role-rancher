# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

# -----------------------------------------------------------------------
# SINGLE SOURCE OF TRUTH - Configuration loaded from test_vars.yml
# -----------------------------------------------------------------------
# This eliminates the need to maintain configuration in two places
begin
  test_vars = YAML.load_file('test_vars.yml')
  RANCHER_IP = test_vars['rancher_public_ip']
  RANCHER_PASSWORD = test_vars['rancher_bootstrap_password']
rescue Errno::ENOENT
  puts "ERROR: test_vars.yml not found!"
  puts "Please create test_vars.yml with rancher_public_ip and rancher_bootstrap_password"
  exit 1
rescue => e
  puts "ERROR: Failed to load test_vars.yml: #{e.message}"
  exit 1
end

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.hostname = "rancher-test"

  # Network configuration with fixed IP
  config.vm.network "private_network", ip: RANCHER_IP

  # VM Resources
  config.vm.provider "virtualbox" do |vb|
    vb.name = "rancher-test-vm"
    vb.memory = "4096"
    vb.cpus = 2
    vb.linked_clone = true
  end

  # Ansible Provisioning
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "test_playbook.yml"
    ansible.verbose = "v"
    ansible.extra_vars = {
      rancher_bootstrap_password: RANCHER_PASSWORD,
      rancher_public_ip: RANCHER_IP,
      rancher_configure_firewall: false,
      ansible_python_interpreter: "/usr/bin/python3"
    }
  end
end
