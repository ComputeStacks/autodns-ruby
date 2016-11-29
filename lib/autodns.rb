require 'json'
require 'httparty'

require 'autodns/auth'
require 'autodns/client'
require 'autodns/dns/zone'
require 'autodns/dns/zone_record'
require 'autodns/errors'
require 'autodns/response'
require 'autodns/settings'
require "autodns/version"

module Autodns
  ## Configuration defaults
  # zone_type: Native, Master, or Slave
  # masters: Array of master NS'.
  #
  @config = {
              zone_type: nil, # Not in use
              masters: [],
              nameservers: [] # Not in use.
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
