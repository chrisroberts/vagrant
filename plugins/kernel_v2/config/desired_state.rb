require "vagrant"

module VagrantPlugins
  module Kernel_V2
    class DesiredStateConfig < Vagrant.plugin("2", :config)

      # @return [Hash<Symbol, Config>] registered configurations
      attr_reader :items

      # Create new instance
      #
      # @return [self]
      def initialize
        super
        @logger = Log4r::Logger.new("vagrant::config::desired_state")
        @items = {}
        @finalized = false
      end

      # Finalize the configuration
      #
      # @return [NilClass]
      def finalize!
        @logger.debug("finalizing")
        @finalized = true
        nil
      end

      # Merge configuration
      #
      # @param other [Config]
      # @return [self]
      def merge(other)
        if other.respond_to?(:items)
          all_keys = (items.keys + other.items.keys).uniq
          all_keys.each do |item_key|
            if items[item_key] && other.items[item_key]
              items[item_key] = items[item_key].merge(other.items[item_key])
            elsif items[item_key].nil? && other.items[item_key]
              items[item_key] = other.items[item_key]
            end
          end
        end
        self
      end

      # Validate the configuration
      #
      # @param machine [Machine]
      # @return [Hash<String, Array<String>>] errors
      def validate(machine)
        @logger.debug("validating")
        errors = {}.tap do |result|
          items.each do |config_key, config_item|
            validate_result = config_item.validate(machine)
            if validate_result.is_a?(Hash)
              result["DesiredState::#{config_key.capitalize}"] = validate_result.values.flatten
            end
          end
        end
        errors["DesiredState"] = items.map do |config_key, config_value|
          if(config_value.is_a?(Vagrant::Config::V2::DummyConfig))
            I18n.t("vagrant.config.root.bad_key", key: config_key)
          end
        end.compact
        errors
      end

      # Allow lazy configuration registration
      def method_missing(*args, &block)
        lookup = args.first.to_sym
        if @finalized && !items[lookup]
          if !Vagrant.plugin("2").manager.desired_state_configs[lookup]
            raise KeyError.new("Invalid configuration key requested `#{lookup}`")
          else
            nil
          end
        else
          if items[lookup]
            items[lookup]
          elsif Vagrant.plugin("2").manager.desired_state_configs[lookup]
            obj = Vagrant.plugin("2").manager.desired_state_configs[lookup].new
            items[lookup] = obj
            obj
          else
            obj = super
            items[lookup] = obj
            obj
          end
        end
      end

      def to_s
        "DefinedState"
      end

    end
  end
end
