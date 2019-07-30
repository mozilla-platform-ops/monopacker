Vagrant.configure("2") do |config|
  config.vm.define "aws" do |aws|
    aws.vm.box = "packer_amazon-ebs_aws.box"
  end

  config.vm.define "gcp" do |gcp|
    gcp.vm.box = "packer_googlecompute_google.box"
  end
end
