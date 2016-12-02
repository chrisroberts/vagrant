require "vagrant"

module VagrantPlugins
  module DesiredStatePlugins
    class Plugin < Vagrant.plugin("2")
      name "Desired State Plugins"
      description <<-DESC
      Desired plugins to be available.
      DESC

      config(:plugins, :desired_state) do
        require_relative "config"
        Config
      end

      desired_state(:plugins) do
        require_relative "plugins"
        Plugins
      end

      action_hook(:desired_state, :environment_load) do |hook|
        require_relative "action_desired_state"
        hook.append(ActionDesiredState)
      end
    end
  end
end
