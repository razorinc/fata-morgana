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
            #Step 1: Create the user
            config = Openshift::SDK::Config.instance
            user = Model::User.new("a#{napp.app_guid[0..7]}", "#{config.get("app_user_home")}")
            cmd = "useradd --base-dir #{user.basedir} --gid 100 -m -K UID_MIN=100 -K UID_MAX=499 #{user.name}"
            out,err,ret = shellCmd(cmd)
            if ret == 0
              napp.user = user
              napp.user.uid = `id -u #{user.name}`
              napp.user.homedir = "#{user.basedir}/#{user.name}"
              napp.save!
            else
              raise AppCreationException.new("Unable to create user #{error_data.join("\n")} on node")              
            end
            
            #Step 2: Create the base repository
            napp.app_shared_repo_subdir="#{user.homedir}/#{config.get('app_shared_repo_subdir')}"
            napp.app_prod_repo_subdir="#{user.homedir}/#{config.get('app_prod_repo_subdir')}"
            napp.app_prod_subdir="#{user.homedir}/#{config.get('app_prod_subdir')}"
           
            base_repo = Openshift::SDK::Utils::VersionControl.new(napp.app_shared_repo_subdir)
            base_repo.create(true)
            
            #Step 3: Create the production checkout
            prod_repo = Openshift::SDK::Utils::VersionControl.new(napp.app_prod_subdir, napp.app_prod_repo_subdir)
            prod_repo.create_from base_repo
            napp.save!
            raise AppCreationException.new("Unable to create repository directory at #{napp.repodir} on node") if $?.to_i != 0
          rescue Exception => e
            log.error(e.message)
            napp.create_error!
            raise e            
          end
          napp.create_complete!
        end
        
        def after_create_error(napp, transition)      
          log.info "Error occured while creating application #{napp.app_guid} on node"
          after_destroy(napp,transition)
        end
        
        def after_create_complete(napp, transition)      
          log.info "Application #{napp.app_guid} created on node"
        end
        
        def after_install(napp, transition)
          log.info "Installing application #{napp.app_guid} on node"
          #Step 1: install missing dependencies
          begin
            app = Model::Application.find napp.app_guid
            missing_features = []
            app.requires_feature.each do |feature|
              carts = Model::Cartridge.what_provides feature
              feature_installed = false
              carts.each do |cart|
                feature_installed = cart.installed?
                break if feature_installed
              end
              
              missing_features.push("openshift-feature-#{feature}") unless feature_installed
            end
            
            if missing_features.length > 0
              #check instalpolicy here
              cmd = "yum install -y -q #{missing_features.join(" ")}"
              out,err,ret = shellCmd(cmd)
              raise AppInstallationException.new("Unable to install cartridge for feature #{feature}") unless ret == 0
            end
            
            #Step 2: call configure hook on direct dependencies
            
            #Step 3: connect components
          rescue AppInstallationException => e
            napp.install_error!
            raise e
          rescue Exception => e
            napp.install_error!
            raise AppInstallationException.new(e.message)
          end
          
          napp.install_complete!
        end
        
        def after_start(napp, transition)
          log.info "Starting application #{napp.app_guid} on node"
          napp.start_complete!
        end
        
        def after_stop(napp, transition)
          log.info "Stopping application #{napp.app_guid} on node"
          application.stop_complete!
        end
        
        def after_uninstall(napp, transition)
          log.info "Uninstalling application #{napp.app_guid} on node"
          napp.uninstall_complete!
        end
        
        def after_destroy(napp, transition)
          log.info "Destroying application #{napp.app_guid} on node"
          
          if napp.user
            cmd = "userdel -f -r #{napp.user.name}"
            out,err,ret = shellCmd(cmd)
            napp.user = nil if ret == 0
            napp.save!
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
      