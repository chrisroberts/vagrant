module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class Drive
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env

          all_controllers = env[:machine].provider.driver.read_storage_controllers
          controllers = all_controllers.find_all{|c| c[:name].start_with?("Vagrant") }
          current_attachments = ""
          env[:machine].config.vm.drives.each do |drive|
            next if drive[:disabled]

          end

          # Start up the VM and wait for it to boot.
          env[:ui].info I18n.t("vagrant.actions.vm.boot.booting")
          env[:machine].provider.driver.start(boot_mode)

          @app.call(env)
        end
      end
    end
  end
end
