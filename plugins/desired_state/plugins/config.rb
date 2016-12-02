module VagrantPlugins
  module DesiredStatePlugins
    class Config < Vagrant.plugin("2", :config)

      attr_reader :required_plugins

      def initialize
        @required_plugins = {}
      end

      def required(*args)
        set = generate_list(args)
        set.each_pair do |name, info|
          if @required_plugins[name]
            @required_plugins[name][:plugin_requirement] = @required_plugins[name][:plugin_requirement].concat(info[:plugin_requirement].as_list)
          else
            @required_plugins[name] = info
          end
        end
        nil
      end

      private

      def generate_list(items)
        flat_items = items.flatten
        idx = 0
        result = {}
        while(idx < flat_items.size)
          name = flat_items[idx]
          if name.is_a?(Hash)
            info = Hash[name.map{|k,v|[k.to_sym, v]}]
            result[info[:name]] = {
              plugin_name: info[:name],
              plugin_requirement: Gem::Requirement.new(info[:version]),
              plugin_sources: info.fetch(:sources, ["https://rubygems.org", "https://gems.hashicorp.com"])
            }
          else
            result[name] = {
              plugin_name: name,
              plugin_requirement: Gem::Requirement.new,
              plugin_sources: ["https://rubygems.org", "https://gems.hashicorp.com"]
            }
            idx += 1
            if idx < flat_items.size
              begin
                requirement = Gem::Requirement.new(flat_items[idx])
                result[name][:plugin_requirement] = requirement
                idx += 1
              rescue Gem::Requirement::BadRequirementError
              end
            end
          end
        end
        result
      end
    end
  end
end
