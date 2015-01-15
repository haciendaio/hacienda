# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|

  config.vm.define :haciendavm do |server|
    server.vm.box       = 'ubuntu/trusty64'
    server.vm.host_name = 'haciendavm'

    server.vm.forward_port 22, 2200
    server.vm.forward_port 80, 8080
    server.vm.network :hostonly, "192.168.33.14"
  end

  config.vm.provision "shell", path: "vagrant_setup.sh", args: [ENV['TOKEN']]
end
