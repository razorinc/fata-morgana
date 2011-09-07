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
        ds_attr_accessor :group_guid, :state, :is_responding, :last_updated
        ds_attr_accessor :provate_ip, :public_ip
        
        def self.bucket
          "admin"
        end
        
        @@this_node = nil
        def self.this_node
          if @@this_node
            @@this_node 
          else
            n = Node.new
            n.gen_uuid
            n.save!
            @@this_node = n
          end
        end
        
        state_machine :state, :initial => :not_created, :action => :save! do
          event(:join) { transition :standalone => :joining }
          event(:join_complete) { transition :joining => :joined }
          event(:join_error) { transition :joining => :standalone }
          
          event(:sync) { transition :joined => :syncing }
          event(:sync_complete) { transition :syncing => :synced }
          event(:sync_error) { transition :syncing => :joined }
          
          event(:unjoin) { transition :joined => :unjoining }
          event(:unjoin_complete) { transition :unjoining => :standalone } 
          event(:unjoin_error) { transition :unjoining => :joined }
        end
      end
    end
  end
end
