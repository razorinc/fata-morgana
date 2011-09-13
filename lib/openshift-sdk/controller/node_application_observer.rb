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
require 'open3'
require 'openshift-sdk/config'
require 'openshift-sdk/utils/logger'
require 'openshift-sdk/utils/shell_exec'
require 'openshift-sdk/utils/version_control'
require 'openshift-sdk/model/user'
require 'openshift-sdk/model/application'
require 'openshift-sdk/model/node_application'

module Openshift
  module SDK
    module Controller
   
      class InvalidApplicationException < Exception
      end
      
      class AppCreationException < Exception
      end
      
      class AppInstallationException < Exception
      end
      
      class NodeApplicationObserver < ActiveModel::Observer
        include Openshift::SDK::Utils::Logger      
        include Openshift::SDK::Utils::ShellExec  
        observe Model::NodeApplication
        
        def before_transition(napp, transition)
          raise InvalidApplicationException.new("node application object is not valid") unless napp.valid?
        end
        
        def after_transition(napp, transition)
        end
        
        def after_create(napp, transition)
          log.info "Creating application #{napp.app_guid} on node"
          begin
            app = Openshift::SDK::Model::Application.find(napp.app_guid,napp.user_group_id)
            app.users.each do |user_guid|
              user = Model::User.find(user_guid)
              user.create!
            end
            
            user = Openshift::SDK::Model::User.find(napp.primary_user_id)
            napp.create_app_directories
            user.run_as{
              napp.setup_repo
              napp.setup_app_production
              napp.setup_app_development
              napp.save!
            }
            napp.create_complete!          
          rescue Exception => e
            log.error(e.message)
            napp.create_error!
          end
        end
        
        def after_create_error(napp, transition)
          log.info "Error occured while creating application #{napp.app_guid} on node"
          after_destroy(napp,transition)
        end
        
        def after_create_complete(napp, transition)      
          log.info "Application #{napp.app_guid} created on node"
        end
        
        def after_destroy(napp, transition)
          log.info "Destroying application #{napp.app_guid} on node"
          begin
            app = Openshift::SDK::Model::Application.find(napp.app_guid,napp.user_group_id)
            napp.remove_app
            app.users.each do |user_guid|
              user = Openshift::SDK::Model::User.find(user_guid)
              user.remove!
            end
          rescue Exception => e
            log.error(e.message)
          end
          napp.destroy_complete!
        end
        
        def after_destroy_complete(napp, transition)
          log.info "Application #{napp.app_guid} destroyed on node"
          napp.delete!
        end
              
        def after_build(napp, transition)
          log.info "Building application #{napp.app_guid} on node"
          napp.build_complete!
        end
        
        def after_deploy(napp, transition)
          log.info "deploying application #{napp.app_guid} on node"
          application.deploy_complete!        
        end
        
        def after_failure_to_transition(napp, transition)
          print "#{transition} is not valid\n"
        end
      end
    end
  end
end
      
