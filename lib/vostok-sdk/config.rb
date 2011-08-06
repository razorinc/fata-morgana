require 'vostok-sdk/controller/application_manager'

module Vostok
  module SDK
    class Config
      include Singleton

      @@conf_name = 'vostok.conf'
      def initialize()
        _linux_cfg = '/etc/vostok/' + @@conf_name
        _gem_cfg = File.join(File.expand_path(File.dirname(__FILE__) + "/../../conf"), @@conf_name)
        @config_path = File.exists?(_linux_cfg) ? _linux_cfg : _gem_cfg

        begin
          @@global_config = ParseConfig.new(@config_path)
        rescue Errno::EACCES => e
          puts "Could not open config file: #{e.message}"
          exit 253
        end
      end

      def get(name)
        val = @@global_config.get_value(name)
        val.gsub!(/\\:/,":") if not val.nil?
        val
      end
    end
    
    #instantiate observers
    ApplicationManager.instance
  end
end
