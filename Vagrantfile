Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.box_download_options = {"ssl-no-revoke" => true}
  config.vm.network :private_network, ip: "10.0.2.15"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "10240"
    vb.cpus = 4
  end
end