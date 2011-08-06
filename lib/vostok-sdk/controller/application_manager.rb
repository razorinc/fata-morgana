require 'rubygems'
require 'active_model'
require 'json'
require 'state_machine'
require 'vostok-sdk/config'
require 'vostok-sdk/model/application'

module Vostok
  module SDK
    class ApplicationManager < ActiveModel::Observer
      observe "Vostok::SDK::Application"
      
      def after_create(application, transition)
        print "Creating application #{application.guid}\n"
        application.create_complete!
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
        print "Destroying application #{application.guid}\n"
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
      