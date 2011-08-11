require 'rubygems'
require 'json'

module Vostok
  module SDK
    module JSONEncodable
      def to_map
        map = Hash.new
        map['json_class'] = self.class.name
        self.instance_variables.each {|m| 
          map[m[1..-1]]= self.instance_variable_get m
        }
        map
      end

      def to_json(*a)
        to_map.to_json(*a)
      end
    end
  end
end
