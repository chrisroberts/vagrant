require "log4r"

module VagrantPlugins
  module DesiredStatePlugins
    class ActionDesiredState
      def initialize(app, env)
        @app    = app
        @logger = Log4r::Logger.new("vagrant::desired_state")
      end

      def call(env)
        Vagrant.plugin("2").manager.desired_states.each do |type, args|
          @logger.debug("Processing desired state `#{type}` -> #{args}")
          klass, init_opts = args
          instance = klass.new(env, init_opts)
          if instance.fulfilled?
            @logger.debug("No action required for type `#{type}`")
          else
            @logger.info("Applying desired state of type `#{type}`")
            instance.apply
          end
        end

        @app.call(env)
      end
    end
  end
end
