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
require 'openshift-sdk/config'
require 'openshift-sdk/model/application'
require 'openshift-sdk/model/model'
require 'openshift-sdk/model/user'

module Openshift::SDK::Model
  class NodeApplication  < OpenshiftModel
    ds_attr_accessor :state, :primary_user_id, :user_group_id, :app_guid, :app_name, :app_repo_dir, :app_prod_dir, :app_prod_repo_dir, :app_user_dev_dir, :app_user_prod_dir
    
    state_machine :state, :initial => :not_created, :action => :save! do
      event(:create) { transition :not_created => :creating }
      event(:create_complete) { transition :creating => :created }
      event(:create_error) { transition :creating => :destroying }
      
      event(:destroy) { transition :created => :destroying }
      event(:destroy_complete) { transition :destroying => :not_created }
    end
    
    def self.bucket
      `id -g`.strip
    end
      
    def initialize(app_obj=nil, app_user_group_id=nil)
      super()
      app = nil
      if app_obj.class == Application
        self.app_guid = app_obj.guid
      else
        self.app_guid = app_obj            
        app = Openshift::SDK::Model::Application.find(self.app_guid, app_user_group_id)
      end
      
      @app_name = app.name
      @primary_user_id = app.users.first
      config = Openshift::SDK::Config.instance
      primary_user = Openshift::SDK::Model::User.find(@primary_user_id)
      @app_repo_dir = "#{config.get("app_repository_dir_prefix")}/#{@app_guid}"
      @app_prod_repo_dir = "#{config.get("app_production_dir_prefix")}/#{@app_guid}/repo"
      @app_prod_dir = "#{config.get("app_production_dir_prefix")}/#{@app_guid}/app"
      
      @app_user_dev_dir = "#{primary_user.homedir}/#{config.get("app_user_home_development_subdir")}"
      @app_user_prod_dir = "#{primary_user.homedir}/#{config.get("app_user_home_production_subdir")}"
      @user_group_id = app_user_group_id
    end
    
    def save!
      super(self.user_group_id)
      self
    end
    
    def delete!
      super(self.user_group_id)
      self
    end
    
    def remove_app
      config = Openshift::SDK::Config.instance
      primary_user = Openshift::SDK::Model::User.find(@primary_user_id)      
      FileUtils.rm_rf @app_repo_dir
      FileUtils.rm_rf @app_prod_dir
      FileUtils.rm_rf "#{config.get("app_production_dir_prefix")}/#{@app_guid}"
      FileUtils.rm_rf @app_user_dev_dir
      FileUtils.rm_rf @app_user_prod_dir
    end

    def create_app_directories
      user = Openshift::SDK::Model::User.find(@primary_user_id)
      config = Openshift::SDK::Config.instance
      
      FileUtils.mkdir_p @app_repo_dir
      FileUtils.mkdir_p "#{@app_prod_repo_dir}"
      FileUtils.mkdir_p "#{@app_prod_dir}"
      FileUtils.mkdir_p "#{@app_user_dev_dir}"

      FileUtils.chown_R user.name, @user_group_id, @app_repo_dir
      FileUtils.chown_R user.name, @user_group_id, @app_prod_repo_dir
      FileUtils.chown_R user.name, @user_group_id, @app_prod_dir
      FileUtils.chown_R user.name, @user_group_id, @app_user_dev_dir

      FileUtils.chmod 0o1760,@app_repo_dir
      FileUtils.chmod 0o1760,@app_prod_repo_dir
      FileUtils.chmod 0o1760,@app_prod_dir
      FileUtils.chmod 0o1760,@app_user_dev_dir
      
      FileUtils.ln_sf "#{@app_prod_dir}", "#{app_user_prod_dir}"
    end

    def setup_repo
      app = Openshift::SDK::Model::Application.find self.app_guid
      base_repo = Openshift::SDK::Utils::VersionControl.new(@app_repo_dir)
      base_repo.create(true)
    end
    
    def setup_app_production
      app = Openshift::SDK::Model::Application.find self.app_guid
      base_repo = Openshift::SDK::Utils::VersionControl.new(@app_repo_dir)      
      prod_repo = Openshift::SDK::Utils::VersionControl.new(@app_prod_dir, @app_prod_repo_dir)
      prod_repo.create_from base_repo
      config = Openshift::SDK::Config.instance
      app.package_path = @app_prod_dir
      app.save!
    end
    
    def setup_app_development
      app = Openshift::SDK::Model::Application.find self.app_guid
      base_repo = Openshift::SDK::Utils::VersionControl.new(@app_repo_dir)      
      dev_repo = Openshift::SDK::Utils::VersionControl.new(@app_user_dev_dir)
      dev_repo.create_from base_repo
    end
    
    def add_feature(feature, is_native=false)
      #load app descriptor from development space
      FileUtils.mkdir_p "#{@app_user_dev_dir}/openshift"
      manifest_file_path = "#{@app_user_dev_dir}/openshift/manifest.yml"  
      unless File.exists? manifest_file_path
        f = File.open(manifest_file_path,"w")
        f.write "Name: #{app_name}"
        f.close
      end
      app = Openshift::SDK::Model::Application.from_opm("#{@app_user_dev_dir}")
      app.from_manifest_yaml(manifest_file_path)

      app.requires = [] unless app.requires
      app.requires_feature = [] unless app.requires_feature

      #update with feature
      if is_native
        app.requires << feature unless app.requires.include? feature
      else
        app.requires_feature << feature unless app.requires_feature.include? feature
      end

      #save and commit manifest
      manifest = File.open(manifest_file_path, "w")
      manifest.write(app.to_manifest_yaml)
      manifest.close
      dev_repo = Openshift::SDK::Utils::VersionControl.new(@app_user_dev_dir)  
      dev_repo.add manifest_file_path
      dev_repo.commit "Adding feature #{feature} #{"[native]" if is_native}"
    end
    
    def copy_scaffolding
      app = Openshift::SDK::Model::Application.from_opm("#{@app_user_dev_dir}")
      manifest_file_path = "#{@app_user_dev_dir}/openshift/manifest.yml"      
      app.from_manifest_yaml(manifest_file_path)
      app.resolve_references
      
      #create scaffolding directories
      app.component_instance_map.each do |comp_map_key, comp|
        unless File.exists? "#{app_user_dev_dir}/openshift/#{comp_map_key}"
          FileUtils.mkdir_p "#{app_user_dev_dir}/openshift/#{comp_map_key}" 
        end
        comp.cartridge_instances.each do |cpname,cpobj|
          sub_comp_cart = cpobj.cartridge
          unless File.exists? "#{app_user_dev_dir}/openshift/#{comp_map_key}.#{sub_comp_cart.name}" 
            FileUtils.mkdir_p "#{app_user_dev_dir}/openshift/#{comp_map_key}.#{sub_comp_cart.name}" 
          end
          unless File.exists? "#{app_user_dev_dir}/openshift/#{comp_map_key}/#{sub_comp_cart.name}"
            FileUtils.ln_sf "#{app_user_dev_dir}/openshift/#{comp_map_key}.#{sub_comp_cart.name}", "#{app_user_dev_dir}/openshift/#{comp_map_key}/#{sub_comp_cart.name}"
          end
          
          sub_comp_cart.descriptor.profiles[cpobj.profile].groups.each do |gname, group|
            group.resolved_components.each do |sub_comp_name, sub_comp|
              unless File.exists? "#{app_user_dev_dir}/openshift/#{sub_comp.mapped_name}"
                FileUtils.mkdir_p "#{app_user_dev_dir}/openshift/#{comp_map_key}.#{sub_comp_cart.name}/#{sub_comp_name}"
                FileUtils.ln_sf "#{app_user_dev_dir}/openshift/#{comp_map_key}.#{sub_comp_cart.name}/#{sub_comp_name}", "#{app_user_dev_dir}/openshift/#{sub_comp.mapped_name}"
              end
            end
          end
        end
      end
      
      #call scaffold hook in aprox. dependency order
      
    end
  end
end
