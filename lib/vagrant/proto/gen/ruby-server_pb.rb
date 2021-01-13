# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: internal/server/proto/ruby-server.proto

require 'google/protobuf'

require 'google/protobuf/empty_pb'
require 'google/protobuf/any_pb'
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("internal/server/proto/ruby-server.proto", :syntax => :proto3) do
    add_message "hashicorp.vagrant.GetPluginsResponse" do
      repeated :plugins, :message, 1, "hashicorp.vagrant.Plugin"
    end
    add_message "hashicorp.vagrant.Plugin" do
      optional :name, :string, 1
      optional :type, :enum, 2, "hashicorp.vagrant.Plugin.Type"
    end
    add_enum "hashicorp.vagrant.Plugin.Type" do
      value :COMMAND, 0
      value :COMMUNICATOR, 1
      value :GUEST, 2
      value :HOST, 3
      value :PROVIDER, 4
      value :PROVISIONER, 5
      value :SYNCED_FOLDER, 6
    end
    add_message "hashicorp.vagrant.ParseVagrantfileRequest" do
      optional :path, :string, 1
    end
    add_message "hashicorp.vagrant.ParseVagrantfileResponse" do
      optional :vagrantfile, :message, 1, "hashicorp.vagrant.Vagrantfile"
    end
    add_message "hashicorp.vagrant.Provisioner" do
      optional :name, :string, 1
      optional :config, :message, 2, "google.protobuf.Any"
    end
    add_message "hashicorp.vagrant.MachineConfig" do
      optional :name, :string, 1
      optional :box, :string, 2
      repeated :provisioner, :message, 3, "hashicorp.vagrant.Provisioner"
    end
    add_message "hashicorp.vagrant.Vagrantfile" do
      optional :raw, :string, 1
      optional :current_version, :string, 2
      repeated :machine_config, :message, 3, "hashicorp.vagrant.MachineConfig"
    end
  end
end

module Hashicorp
  module Vagrant
    GetPluginsResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("hashicorp.vagrant.GetPluginsResponse").msgclass
    Plugin = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("hashicorp.vagrant.Plugin").msgclass
    Plugin::Type = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("hashicorp.vagrant.Plugin.Type").enummodule
    ParseVagrantfileRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("hashicorp.vagrant.ParseVagrantfileRequest").msgclass
    ParseVagrantfileResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("hashicorp.vagrant.ParseVagrantfileResponse").msgclass
    Provisioner = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("hashicorp.vagrant.Provisioner").msgclass
    MachineConfig = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("hashicorp.vagrant.MachineConfig").msgclass
    Vagrantfile = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("hashicorp.vagrant.Vagrantfile").msgclass
  end
end