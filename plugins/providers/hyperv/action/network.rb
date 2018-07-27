module VagrantPlugins
  module HyperV
    module Action
      class Network
        include Vagrant::Util::NetworkIP
        include Vagrant::Util::ScopedHashOverride

        PRIVATE_NETWORKS = [
#          IPAddr.new("10.0.0.0/8").freeze,
          IPAddr.new("172.16.0.0/12").freeze,
#          IPAddr.new("192.168.0.0/16").freeze
        ].freeze

        CORE_NETWORK_NAME = "VagrantCore".freeze
        PUBLIC_NETWORK_NAME = "VagrantPublic".freeze

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
                network_id = host_networks.detect{|hnet| hnet["Name"] == PUBLIC_NETWORK_NAME}["ID"]
              else
                network_id = host_networks.detect{|hnet| hnet["Name"] == CORE_NETWORK_NAME}["ID"]
              end
            end
            adapter_name = options.fetch(:adapter, "VagrantAdapter#{idx}")
            adapter = vm_adapters.detect{|va| va["Name"] == adapter_name}
            # if adapter
            #   machine.provider.driver.execute(:connect_vm_adapter,
            #     "AdapterID" => adapter["ID"],
            #     "NetworkID" => network_id
            #   )
            # else
            result = machine.provider.driver.execute(:add_vm_network_adapter,
              "VMID" => machine.id,
              "AdapterName" => adapter_name,
#              "NetworkID" => network_id
            )
            #            end

            endpoint = machine.provider.driver.execute(:connect_network,
              "Name" => "VagrantNetworkAttachment",
              "NetworkID" => network_id,
              "AdapterName" => result["Name"]
            )

            networks << {
              auto_config: true,
              interface: idx,
              type: :static,
              ip: endpoint["IPAddress"],
              netmask: "255.255.255.0"
            }
          end
          @app.call(env)

          if !networks.empty?
            env[:ui].info "Configuring network interfaces"
            env[:machine].guest.capability(:configure_networks, networks)
          end
        end

        # Locate a free subnet of requested size on the host machine
        #
        # @param [String, Integer] mask Netmask of the subnet
        # @param [Vagrant::Machine] machine
        # @return [String, String] AddressPrefix, Gateway
        def locate_free_subnet(mask, machine)
          used_subnets = machine.provider.driver.execute(:get_used_subnets).map do |info|
            IPAddr.new("#{info["Address"]}/#{info["Netmask"]}")
          end
          nets = PRIVATE_NETWORKS.shuffle
          while !nets.empty?
            base = nets.pop
            subnet = IPAddr.new("#{base.to_s}/#{mask}")
            while used_subnets.any?{|u| u.include?(subnet) || subnet.include?(u) } && base.include?(subnet)
              subnet = IPAddr.new("#{subnet.to_range.last.succ}/#{mask}")
            end
            if base.include?(subnet)
              if mask.to_s.include?(".")
                prefix = mask.split(".").map{|m| m.to_i.to_s(2)}.join.count("1")
              else
                prefix = mask
              end
              return "#{subnet.to_s}/#{prefix}", subnet.succ.succ.to_s
            end
          end
          raise "Failed to find open subnet"
        end

        # Checks for VagrantCoreNet ICS network and
        # creates it if is not available
        def core_setup!(machine)
          host_networks = machine.provider.driver.execute(:get_networks)
          host_adapter_info = machine.provider.driver.execute(:get_physical_adapter)
          host_adapter = host_adapter_info["Name"]

          if host_networks.none?{|n| n["Name"] == PUBLIC_NETWORK_NAME }
            host_info = machine.provider.driver.execute(:get_host_subnet)
            addr = IPAddr.new("#{host_info["Address"]}/#{host_info["Netmask"]}").to_s
            mask = host_info["Netmask"].to_s.split(".").map{|m| m.to_i.to_s(2)}.join.count("1")
            @logger.info("creating required public network: #{PUBLIC_NETWORK_NAME}")
            addr, gateway = locate_free_subnet("24", machine)
            public_network = machine.provider.driver.execute(:create_network,
              "Name" => PUBLIC_NETWORK_NAME,
              "Type" => "NAT",
              "AddressPrefix" => "172.84.0.0/24",
              "Gateway" => "172.84.0.1"
              # "Type" => "Transparent",
              # "AddressPrefix" => "#{addr}/#{mask}",
              # "Gateway" => host_info["Gateway"],
              # "AdapterName" => host_adapter
            )
            # @logger.info("creating endpoint for network and attaching to public network")
            # attempts = 0
            # begin
            #   machine.provider.driver.execute(:connect_network,
            #     "Name" => "#{PUBLIC_NETWORK_NAME}Endpoint",
            #     "NetworkID" => public_network["ID"],
            #     "IPAddress" => host_info["Gateway"],
            #     "Gateway" => "0.0.0.0",
            #     "CompartmentID" => "1"
            #   )
            # rescue => e
            #   attempts += 1
            #   if attempts > 10
            #     raise
            #   else
            #     @logger.error("network endpoint connect failed: #{e}")
            #     sleep(5)
            #     @logger.info("retrying connection...")
            #     retry
            #   end
            # end
            sleep(5)
            host_networks = machine.provider.driver.execute(:get_networks)
          end
          if host_networks.none?{|n| n["Name"] == CORE_NETWORK_NAME }
            addr, gateway = locate_free_subnet("24", machine)
            @logger.info("creating required core vagrant network: #{CORE_NETWORK_NAME}")
            begin
              machine.provider.driver.execute(:create_network,
                "Name" => CORE_NETWORK_NAME,
                "Type" => "ICS",
                "AddressPrefix" => addr,
                "Gateway" => gateway,
                "AdapterName" => host_adapter
              )
            rescue => e
              @logger.error("core create failed: #{e}")
              sleep(5)
              @logger.info("retrying core network create")
              retry
            end
            host_networks = machine.provider.driver.execute(:get_networks)
          end
          host_networks
        end
      end
    end
  end
end
