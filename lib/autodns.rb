require 'httparty'
require 'yaml'

require 'autodns/auth'
require 'autodns/client'
require 'autodns/dns/zone'
require 'autodns/dns/zone_record'
require 'autodns/errors'
require 'autodns/settings'
require 'autodns/version'

module AutoDNS

  ## Configuration defaults
  # SOA Levels provided by AutoDNS. (pg. 159)
  # soa_levels = {
  #     recommended: {
  #         level: 1,
  #         refresh: 43200,
  #         retry: 7200,
  #         expire: 1209600,
  #         ttl: 86400
  #     },
  #     high_reliability: {
  #         level: 2,
  #         refresh: 43200,
  #         retry: 7200,
  #         expire: 1209600,
  #         ttl: 43200
  #     },
  #     fast: {
  #         level: 3,
  #         refresh: 43200,
  #         retry: 7200,
  #         expire: 1209600,
  #         ttl: 600
  #     },
  # }
  #
  @config = {
              endpoint: 'https://gateway.autodns.com',
              nameservers: %w(ns1.auto-dns.com ns2.auto-dns.com ns3.autodns.nl ns4.autodns.nl),
              master_ns: 'ns1.auto-dns.com',
              ns_ttl: 86400,
              soa_email: 'dns@usr.cloud',
              soa_level: 2
            }

  @valid_config_keys = @config.keys

  # Configure through hash
  def self.configure(opts = {})
    opts.each {|k,v| @config[k.to_sym] = v if @valid_config_keys.include? k.to_sym}
  end

  # Configure through yaml file
  def self.configure_with(path_to_yaml_file)
    begin
      config = YAML::load(IO.read(path_to_yaml_file))
    rescue Errno::ENOENT
      log(:warning, "YAML configuration file couldn't be found. Using defaults."); return
    rescue Psych::SyntaxError
      log(:warning, "YAML configuration file contains invalid syntax. Using defaults."); return
    end
    configure(config)
  end

  def self.config
    @config
  end

  ## Define the type of module.
  # Possible values are:
  # FULL: Cloud provisioning, DNS
  # DNS: DNS Only
  # PAYMENT: Payment gateway
  def self.module_kind
    'DNS'
  end
end
