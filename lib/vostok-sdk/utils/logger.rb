# Copyright 2010 Red Hat, Inc.
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'rubygems'
require 'logger'
require 'vostok-sdk/config'

module Vostok
  module SDK
    #create logger
    unless @log
      config = Vostok::SDK::Config.instance
      log_location=config.get("log_location")
      log_aging=config.get("log_aging") || "daily"
      log_level=config.get("log_level") || "DEBUG"        
      case log_location
      when "STDERR"
        @log = Object::Logger.new(STDERR)
      when "STDOUT"
        @log = Object::Logger.new(STDOUT)
      else
        @log = Object::Logger.new(log_location,log_aging)
      end
      @log.level=Logger::SEV_LABEL.index(log_level)
    end
    
    def self.log
      @log
    end
    
    module Utils
      module Logger
        def log
          Vostok::SDK::log
        end
      end
    end
  end
end