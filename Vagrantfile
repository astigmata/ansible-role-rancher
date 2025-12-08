# -*- mode: ruby -*-
# vi: set ft=ruby :

# -----------------------------------------------------------------------
# VARIABLES DE CONFIGURATION GLOBALE
# -----------------------------------------------------------------------
RANCHER_IP = "192.168.56.15"
RANCHER_PASSWORD = "admin123456789" # Mot de passe fort pour le bootstrap

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.hostname = "rancher-test"

  # Configuration réseau avec IP fixe
  config.vm.network "private_network", ip: RANCHER_IP

  # Ressources
  config.vm.provider "virtualbox" do |vb|
    vb.name = "rancher-test-vm"
    vb.memory = "4096"
    vb.cpus = 2
    vb.linked_clone = true
  end

  # Provisioning Ansible
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
