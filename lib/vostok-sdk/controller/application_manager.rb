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
require 'vostok-sdk/config'
require 'vostok-sdk/utils/logger'
require 'vostok-sdk/model/application'
require 'vostok-sdk/model/user'

module Vostok
  module SDK
    class InvalidApplicationException < Exception
    end
    
    class UserCreationException < Exception
    end
    
    class ApplicationManager < ActiveModel::Observer
      observe "Vostok::SDK::Application"
      include Vostok::SDK::Utils::Logger
      
      def before_transition(application, transition)
        raise InvalidApplicationException.new("application object is not valid") unless application.valid?
      end
      
      def after_transition(application, transition)
      end
      
      def after_create(application, transition)
        log.info "Creating application #{application.guid}"
        begin
          config = Vostok::SDK::Config.instance
          user = User.new("a#{application.guid[0..7]}", "#{config.get("app_user_home")}")
          cmd = "useradd --base-dir #{user.basedir} --gid 100 -m -K UID_MIN=100 -K UID_MAX=499 #{user.name}"
          log.debug cmd
          ret = IO.popen(cmd, "r+") do |f|
            f.close_write
            log.debug f.read
          end
          application.user = user if ret
          application.save!
          raise UserCreationException.new("Unable to create user #{error_data.join("\n")}") unless ret
          
          
        rescue Exception => e
          raise e
          log.error(e.message)
          application.create_error!
        end
        application.create_complete!
      end
      
      def after_create_error(application, transition)      
        log.info "Error occured while creating application #{application.guid}"
        after_destroy(application,transition)
      end
      
      def after_create_complete(application, transition)      
        log.info "Application #{application.guid} created"
      end
      
      def after_install(application, transition)
        print "Installing application #{application.guid}\n"
        application.install_complete!
      end
      
      def after_start(application, transition)
        print "Starting application #{application.guid}\n"
        application.start_complete!
      end
      
      def after_stop(application, transition)
        print "Stopping application #{application.guid}\n"
        application.stop_complete!
      end
      
      def after_uninstall(application, transition)
        print "Uninstalling application #{application.guid}\n"
        application.uninstall_complete!
      end
      
      def after_destroy(application, transition)
        log.info "Destroying application #{application.guid}"
        
        if application.user
          cmd = "userdel -f -r #{application.user.name}"
          log.debug cmd
          ret = IO.popen(cmd, "r+") do |f|
            f.close_write
            log.debug f.read
          end
          application.user = nil if ret
          application.save!
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
      
      def after_failure_to_transition(vehicle, transition)
        print "#{transition} is not valid\n"
      end
    end
  end
end
      