module VagrantPlugins
  module HyperV
    module Action
      class PackagePrepare
        def initialize(app, env)
          @app = app
          @env = env
        end

        # Disable checkpoints before packaging
        def call(env)
          env[:ui].info("Disabling VM checkpoints...")
          env[:machine].provider.driver.disable_checkpoints
          @app.call(env)
        end
      end
    end
  end
end
