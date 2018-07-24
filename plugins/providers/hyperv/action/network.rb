module VagrantPlugins
  module HyperV
    module Action
      class Network
        include Vagrant::Util::NetworkIP
        include Vagrant::Util::ScopedHashOverride

        CORE_NETWORK_NAME = "VagrantCore".freeze
        TRANSPARENT_NETWORK_NAME = "VagrantTransparent".freeze

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::plugins::hyperv::network")
        end

        def call(env)
          env[:ui].output("Configuring guest networks...")
          machine = env[:machine]

          host_networks = core_setup!(machine)
          vm_adapters = machine.provider.driver.execute(:get_vm_network_adapters, "VMID" => machine.id)

          networks = []

          env[:machine].config.vm.networks.each_with_index do |net_args, idx|
            idx = idx + 1
            type, options = net_args
            next if type != :private_network && type != :public_network && type != :internal_network

            options = scoped_hash_override(options, :hyperv)
            opts = {}

            if type == :private_network && options[:intnet]
              type = :internal_network
            end

            if options[:ip]
              net_ip = IPAddr.new(options[:ip])
            end

            network_id = options[:switch]

            if !options[:auto_config] && net_ip && type != :public_network
              raise "Address not private!" if !net_ip.private?
              matching_network = host_networks.detect do |hnet|
                h_addr = IPAddr.new(hnet["Subnets"].first["AddressPrefix"])
                h_addr.include?(net_ip)
              end
              if matching_network
                network_id = matching_network["ID"]
              else
                prefix, gateway = generate_network_address(net_ip)
                network_id = create_network(prefix, gateway, type, machine)
              end
            else
              if type == :public_network
                network_id = host_networks.detect{|hnet| hnet["Name"] == TRANSPARENT_NETWORK_NAME}["ID"]
              else
                network_id = host_networks.detect{|hnet| hnet["Name"] == CORE_NETWORK_NAME}["ID"]
              end
            end
            adapter_name = options.fetch(:adapter, "VagrantAdapter#{idx}")
            adapter = vm_adapters.detect{|va| va["Name"] == adapter_name}
            if adapter
              adapter_name = adapter["Name"]
            else
              machine.provider.driver.execute(:add_vm_network_adapter,
                "VMID" => machine.id,
                "AdapterName" => adapter_name
              )
            end

            machine.provider.driver.execute(:connect_network,
              "NetworkID" => network_id,
              "AdapterName" => adapter_name)

            networks << {
              auto_config: true,
              interface: idx,
              type: :dhcp
            }
          end
          @app.call(env)

          if !networks.empty?
            env[:ui].info "Configuring network interfaces"
            env[:machine].guest.capability(:configure_networks, networks)
          end
        end

        # Checks for VagrantCoreNet ICS network and
        # creates it if is not available
        def core_setup!(machine)
          host_networks = machine.provider.driver.execute(:get_networks)
          refresh = false
          if host_networks.none?{|n| n["Name"] == CORE_NETWORK_NAME }
            @logger.info("creating required core vagrant network: #{CORE_NETWORK_NAME}")
            machine.provider.driver.execute(:create_network,
              "Name" => CORE_NETWORK_NAME,
              "Type" => "ICS",
              "AddressPrefix" => "172.20.11.0/24",
              "Gateway" => "172.20.11.1"
            )
            refresh = true
          end
          if host_networks.none?{|n| n["Name"] == TRANSPARENT_NETWORK_NAME }
            @logger.info("creating required transparent network: #{TRANSPARENT_NETWORK_NAME}")
            machine.provider.driver.execute(:create_network,
              "Name" => TRANSPARENT_NETWORK_NAME,
              "Type" => "Transparent"
            )
            refresh = true
          end
          if refresh
            machine.provider.driver.execute(:get_networks)
          else
            host_networks
          end
        end
      end
    end
  end
end
