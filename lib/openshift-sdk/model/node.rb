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
require 'active_model'
require 'json'
require 'state_machine'

module Openshift
  module SDK
    module Model
      class Node < OpenshiftModel
        ds_attr_accessor :group_guid, :state, :is_responding, :last_updated, :cluster, :node_application_map
        ds_attr_accessor :provate_ip, :public_ip
         
        state_machine :state, :initial => :not_created, :action => :save! do
          transition :standalone => :joining, :on => :join
          transition :joining => :joined,     :on => :join_complete
          transition :joining => :standalone, :on => :join_error
          
          transition :joined => :syncing, :on => :sync
          transition :syncing => :synced, :on => :sync_complete
          transition :syncing => :joined, :on => :sync_error
          
          transition :joined => :unjoining,     :on => :unjoin
          transition :unjoining => :standalone, :on => :unjoin_complete
          transition :unjoining => :joined,     :on => :unjoin_error
        end
        
        state_machine :run_state, :initial => :running, :action => :save! do
          transition :running   => :rebooting, :on => :reboot
          transition :rebooting => :running,   :on => :reboot_complete
          transition :running   => :shutdown,  :on => :shutdown
        end
      end
    end
  end
end