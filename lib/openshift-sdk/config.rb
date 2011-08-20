#--
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
#++

require 'rubygems'
require 'singleton'
require 'parseconfig'

module Openshift::SDK
  # == Openshift Config
  #
  # Allows access to openshift config file.
  #
  # Reads config entried for the sdk from /etc/openshift/openshift.conf and if
  # that is not available then it will read it from conf/openshift.conf within
  # the ruby gem.
  class Config
    include Object::Singleton

    @@conf_name = 'openshift.conf'
    def initialize()
      _linux_cfg = '/etc/openshift/' + @@conf_name
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
end
