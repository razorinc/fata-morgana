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
require 'state_machine'
require 'openshift-sdk/config'
require 'openshift-sdk/utils/logger'
require 'openshift-sdk/controller/node_application_delegate'
require 'openshift-sdk/model/application'
require 'openshift-sdk/model/user'

module Openshift
  module SDK
    module Controller
      class InvalidApplicationException < Exception
      end
      
      class UserCreationException < Exception
      end
      
      class ApplicationObserver < ActiveModel::Observer
        include Openshift::SDK::Utils::Logger
        observe Model::Application
        
        def before_transition(application, transition)
          unless application.valid?
            log.error application.errors
            raise InvalidApplicationException.new("application object is not valid") 
          end
        end
        
        def after_transition(application, transition)
          application.save!
        end
        
        def after_failure_to_transition(application, transition)
          application.save!          
          print "#{transition} is not valid\n"
        end
        
        def after_create(application, transition)
          log.info "Creating application #{application.guid}"
          begin
            #Reserve the group this app will run under
            application.user_group_id = Model::GidApplicationMap.reserve_application_group(application)
            
            #Reserve the first user for the app
            application.users.push(Model::UidUserMap.reserve_application_user(application))
            
            #load empty descriptor
            application.gen_empty_descriptor
            application.active_profile = application.descriptor.profiles.keys.first

            paas_filter = Openshift::SDK.paas_filter
            application.descriptor.profiles[application.active_profile].groups.each do |gname, group|
              group.provisioning_group = paas_filter.map_application_group(group)
            end
            application.save!
            
            NodeApplicationDelegate.instance.create(application)
            application.create_complete!
          rescue Exception => e
            log.error e.message
            logger.error e.backtrace.join("\n")
            application.create_error!
          end
        end
        
        def after_create_error(application, transition)      
          log.info "Error occured while creating application #{application.guid}"
          application.destroy!
        end
        
        def after_create_complete(application, transition)      
          log.info "Application #{application.guid} created"
        end
        
        def after_destroy(application, transition)
          log.info "Destroying application #{application.guid}"
          begin
            napp_delegate = Controller::NodeApplicationDelegate.instance
            napp_delegate.destroy application
            application.users.each do |uguid|
              user = Model::User.find uguid
              user.delete!
            end
            gamap = Model::GidApplicationMap.find application.user_group_id
            gamap.delete!
            agmap = Model::ApplicationGidMap.find application.guid
            agmap.delete!
          rescue Exception => e
            raise e
            log.error(e.message)
          end
          application.destroy_complete!
        end
        
        def after_destroy_complete(application, transition)
          log.info "Application #{application.guid} destroyed"
          application.delete!
        end
              
        def after_build(application, transition)
          print "Building application #{application.guid}\n"
          application.build_complete!
        end
        
        def after_deploy(application, transition)
          print "deploying application #{application.guid}\n"
          application.deploy_complete!        
        end
      end
    end
  end
end
      
