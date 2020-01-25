# -*- mode: ruby -*-
# vi: set ft=ruby :

IMAGE_NAME = "ubuntu/bionic64"
N = 3

Vagrant.configure("2") do |config|
    config.ssh.insert_key = false
    config.hostmanager.enabled = true
  	config.hostmanager.manage_host = false
  	config.hostmanager.manage_guest = true
  	config.hostmanager.ignore_private_ip = false
  	config.hostmanager.include_offline = true

    config.vm.provider "virtualbox" do |v|
        v.memory = 1024
        v.cpus = 2
    end

    config.vm.define "k8s-master" do |master|
        master.vm.box = IMAGE_NAME
        master.vm.network "private_network", ip: "192.168.50.10"
        master.vm.network "forwarded_port", guest: 8080, host: 8080
        master.vm.hostname = "k8s-master"
        master.vm.provision "ansible_local" do |ansible|
            ansible.playbook = "kubernetes-setup/master-playbook.yml"
            ansible.extra_vars = {
                node_ip: "192.168.50.10",
            }
            ansible.install_mode = 'pip2'
      		#ansible.version = '2.8.2'
      		ansible.compatibility_mode="2.0"
        end
    end

    (1..N).each do |i|
        config.vm.define "node-#{i}" do |node|
            node.vm.box = IMAGE_NAME
            node.vm.network "private_network", ip: "192.168.50.#{i + 10}"
            node.vm.hostname = "node-#{i}"
            node.vm.provision "ansible_local" do |ansible|
                ansible.playbook = "kubernetes-setup/node-playbook.yml"
                ansible.extra_vars = {
                    node_ip: "192.168.50.#{i + 10}",
                }
                ansible.install_mode = 'pip2'
      			#ansible.version = '2.8.2'
      			ansible.compatibility_mode="2.0"
            end
        end
    end
end