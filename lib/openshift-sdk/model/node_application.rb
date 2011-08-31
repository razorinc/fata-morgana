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

module Openshift::SDK::Model
  class NodeApplication  < OpenshiftModel
    ds_attr_accessor :state, :primary_user_id, :user_group_id, :deleted, :app_guid, :app_name, :app_repo_dir, :app_prod_dir, :app_prod_repo_dir, :app_dev_dir
    
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
      
      self.deleted = "false"
      @app_name = app.name
      @primary_user_id = app.users.first
      config = Openshift::SDK::Config.instance
      primary_user = Openshift::SDK::Model::User.find(@primary_user_id)
      @app_repo_dir = "#{config.get("app_repository_dir_prefix")}/#{@app_guid}"
      @app_prod_repo_dir = "#{config.get("app_production_dir_prefix")}/#{@app_guid}/repo"
      @app_prod_dir = "#{config.get("app_production_dir_prefix")}/#{@app_guid}/app"
      @app_dev_dir = "#{primary_user.homedir}/development/#{app_name}"
      @user_group_id = app_user_group_id
    end

    def delete!
      super
    end
    
    def save!
      super(self.user_group_id) unless self.deleted == "true"
    end
    
    def remove_app
      self.deleted = "true"
      config = Openshift::SDK::Config.instance
      primary_user = Openshift::SDK::Model::User.find(@primary_user_id)      
      FileUtils.rm_rf @app_repo_dir
      FileUtils.rm_rf @app_prod_dir
      FileUtils.rm_rf "#{config.get("app_production_dir_prefix")}/#{@app_guid}"
      FileUtils.rm_rf @app_dev_dir
      
      app = Model::Application.find(@app_guid,@user_group_id)
      app.users.each do |user_guid|
        user = Model::User.find(user_guid)
        user.remove!
      end
    end

    def create_app_directories
      user = Openshift::SDK::Model::User.find(@primary_user_id)
      config = Openshift::SDK::Config.instance
      
      FileUtils.mkdir_p @app_repo_dir
      FileUtils.mkdir_p "#{@app_prod_repo_dir}"
      FileUtils.mkdir_p "#{@app_prod_dir}"
      FileUtils.mkdir_p "#{@app_dev_dir}"

      FileUtils.chown_R user.name, @user_group_id, @app_repo_dir
      FileUtils.chown_R user.name, @user_group_id, @app_prod_repo_dir
      FileUtils.chown_R user.name, @user_group_id, @app_prod_dir
      FileUtils.chown_R user.name, @user_group_id, @app_dev_dir

      FileUtils.chmod 0o1760,@app_repo_dir, :verbose => true
      FileUtils.chmod 0o1760,@app_prod_repo_dir, :verbose => true
      FileUtils.chmod 0o1760,@app_prod_dir, :verbose => true
      FileUtils.chmod 0o1760,@app_dev_dir, :verbose => true
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
      app.package_root = "#{config.get("app_production_dir_prefix")}"
      app.package_path = @app_prod_dir
      app.save!
    end
    
    def setup_app_development
      app = Openshift::SDK::Model::Application.find self.app_guid
      base_repo = Openshift::SDK::Utils::VersionControl.new(@app_repo_dir)      
      dev_repo = Openshift::SDK::Utils::VersionControl.new(@app_dev_dir)
      dev_repo.create_from base_repo
    end  

    def setup_app_scaffold
      #app = Openshift::SDK::Model::Application.find self.app_guid
      #primary_user = Openshift::SDK::Model::User.find(@primary_user_id)
      #config = Openshift::SDK::Config.instance
      #prod_repo = Openshift::SDK::Utils::VersionControl.new(@app_prod_dir, @app_prod_repo_dir)
      #
      #app.package_root = "#{config.get("app_production_dir_prefix")}"
      #app.package_path = @app_prod_dir
      #app.save!
      #
      #os_dir = "#{@app_prod_dir}/openshift"
      #FileUtils.mkdir_p os_dir
      #
      ## check and create control file
      #if not File.exist?("#{os_dir}/control.spec")
      #    app.version = "0.0"
      #    app.summary = "Placeholder control spec"
      #    app.native_name = app.name
      #    app.provides_feature = [app.name]
      #    cfile = File.new(os_dir + "/control.spec", "w")
      #    cfile.write(app.to_s)
      #    cfile.close
      #end
      #prod_repo.add("#{os_dir}/control.spec")
      #
      ## check and create descriptor file
      #if not File.exist?("#{os_dir}/descriptor.json")
      #    des_file = File.new("#{os_dir}/descriptor.json", "w")
      #    des_file.write("{}")
      #    des_file.close
      #end
      #prod_repo.add("#{os_dir}/descriptor.json")
      #prod_repo.commit
    end
  end
end