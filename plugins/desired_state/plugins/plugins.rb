module VagrantPlugins
  module DesiredStatePlugins
    class Plugins < Vagrant.plugin("2", :desired_state)

      # @return [TrueClass, FalseClass] is state fulfilled
      def fulfilled?
        if @env[:env].vagrantfile.config.desired_state.plugins
          needed_plugins(@env[:env].vagrantfile.config.desired_state.plugins.required_plugins).empty?
        else
          true
        end
      end

      # Apply any actions to reach desired state
      def apply
        install_plugins = needed_plugins(@env[:env].vagrantfile.config.desired_state.plugins.required_plugins)
        plugin_list = install_plugins.map do |plugin_info|
          "#{plugin_info[:plugin_name]} #{plugin_info[:plugin_version]}"
        end.sort.join("\n")
        @env[:env].ui.warn(I18n.t("vagrant.desired_state.plugins.detected", required_plugins: plugin_list))
        answer = @env[:env].ui.ask(I18n.t("vagrant.desired_state.plugins.confirm_install"))
        if(answer.strip.downcase == 'y')
          @env[:env].ui.info(I18n.t("vagrant.desired_state.plugins.install"))
          install_plugins.each do |plugin_info|
            @env[:env].action_runner.run(CommandPlugin::Action::InstallGem, plugin_info)
          end
          @env[:env].ui.info(I18n.t("vagrant.desired_state.plugins.install_complete"))
        else
          @env[:env].ui.error(I18n.t("vagrant.desired_state.plugins.install_declined"))
          raise Vagrant::Errors::VagrantError.new("Vagrantfile cannot be loaded in current state")
        end
      end

      protected

      # Determine what plugins are not currently installed
      #
      # @param list [Array] list of required plugins
      # @return [Array<Hash>] list of required plugins not installed
      def needed_plugins(list)
        result = []
        plugin_specs = Vagrant::Plugin::Manager.instance.installed_specs
        list.each do |plugin_name, plugin_info|
          plugin_name = plugin_info[:plugin_name]
          plugin_req = plugin_info[:plugin_requirement]
          match_spec = plugin_specs.detect do |spec|
            spec.name == plugin_name
          end
          if match_spec && plugin_req.satisfied_by?(match_spec.version)
            @logger.debug("Required plugin `#{plugin_name} #{plugin_req}` satisfied by `#{match_spec.full_name}`")
          else
            @logger.debug("Required plugin `#{plugin_name} #{plugin_req}` is not satisfied")
            result << plugin_info.dup.merge(plugin_version: plugin_info[:plugin_requirement].as_list.join(", "))
          end
        end
        result
      end

    end
  end
end
