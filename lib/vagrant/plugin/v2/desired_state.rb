module Vagrant
  module Plugin
    module V2
      # This is the base class for a desired state for the V2 API. A desired state
      # is responsible for providing a desired state of the environment executing
      # environment
      class DesiredState

        def initialize(env, opts={})
          @env = env
          @options = opts || {}
          @logger = Log4r::Logger.new("vagrant::plugin::v2::desired_state::#{self.class.name.downcase}")
        end

        # Is the desired state currently fulfilled
        def fulfilled?
          false
        end

        # Apply actions to reach desired state
        def apply
        end
      end
    end
  end
end
