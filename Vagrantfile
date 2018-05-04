# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|

  # Installs Ubuntu 12.04 (32 Bit)
  config.vm.box = "ubuntu/precise32"

  # Installs Ubuntu 14.04 (32 Bit)
  # config.vm.box = "ubuntu/trusty32"

  # Installs Ubuntu 16.04 (32 Bit)
  # config.vm.box = "ubuntu/xenial32"

  config.vm.provision "file", source: "setup.sh", destination: "~/setup.sh"
end
