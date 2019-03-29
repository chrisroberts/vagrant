module Vagrant
  module Config
    module V2
      # This is a configuration object that can have anything done
      # to it. Anything, and it just appears to keep working.
      class DummyConfig
        def initialize
          @_c = {}
        end

        def method_missing(name, *args, &block)
          name = name.to_s
          if name.end_with?("=")
            name = name[0...-1]
            @_c[name] = args.first
            return args.first
          end
          if !@_c.key?(name)
            @_c[name] = DummyConfig.new
          end
          if block_given?
            puts "YIELDING"
            yield @_c[name]
          end
          @_c[name]
        end

        def to_json(*args)
          @_c.to_json(*args)
        end
      end
    end
  end
end
