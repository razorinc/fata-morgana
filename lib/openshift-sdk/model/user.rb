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
require 'active_model'
require 'openshift-sdk/model/model'
require 'openshift-sdk/utils/shell_exec'
require 'openshift-sdk/config.rb'

module Openshift::SDK::Model
  class UserCreationException < Exception
  end

  class UserDeletionException < Exception
  end
  
  # == Uid to User map
  # 
  # Reserves a UID for an application and provides capability to lookup an application
  # based on user ID
  class UidUserMap < OpenshiftModel
    ds_attr_accessor :name, :user_guid, :app_guid
    
    def self.bucket
      "admin"
    end
    
    # Reserves a UID and returns a new user for the application.
    # The min,max user id and group id for the created account can be
    # configured using the min_user_id, max_user_id configuration
    # entries.    
    def self.reserve_application_user(app=nil)
      #TODO: execute in distributed lock
            
      config = Openshift::SDK::Config.instance
      min_uid = (config.get("min_user_id") || "100").to_i
      max_uid = (config.get("max_user_id") || "1000").to_i
      uids = UidUserMap.find_all_guids
      uid = nil
      (min_uid..max_uid).each do |id|
        unless uids.include? id.to_s
          uid = id 
          break
        end
      end
      user = User.new app,uid.to_s
      user.gen_uuid
      uum = UidUserMap.new uid,user.name,user.guid,app.guid
      uum.save!
      user.save!
      
      user.guid
    end

    private
    
    def initialize(uid=nil,uname=nil,user_guid=nil,app_guid=nil)
      return unless uid
      guid_will_change!
      user_guid_will_change!
      @guid,@name,@user_guid,@app_guid=uid,uname,user_guid,app_guid
    end
  end
  
  # == Gid to Application Map
  #
  # Reserves a group ID for an application
  class GidApplicationMap < OpenshiftModel
    ds_attr_accessor :name, :app_guid
    
    def self.bucket
      "admin"
    end
    
    # Reserves a group ID for an application    
    # The min,max user id and group id for the created account can be
    # configured using the min_group_id, max_group_id configuration
    # entries.
    def self.reserve_application_group(app)
      #TODO: execute in distributed lock
      
      config = Openshift::SDK::Config.instance
      min_gid = (config.get("min_group_id") || "560").to_i
      max_gid = (config.get("max_group_id") || "1000").to_i
      gids = GidApplicationMap.find_all_guids
      gid = nil
      (min_gid..max_gid).each do |id|
        unless gids.include? id.to_s
          gid = id 
          break
        end
      end
      map_obj = GidApplicationMap.new gid,app.guid,app.guid
      map_obj.save!
      map_obj.guid
    end

    private
    
    def initialize(gid=nil,gname=nil,app_guid=nil)
      return unless gid
      guid_will_change!
      app_guid_will_change!
      @guid,@name,@app_guid=gid,gname,app_guid
    end
  end

  # == System User
  #
  # Represents a user account on the system. This object will keep track of
  # name, home directory, user id.
  class User < OpenshiftModel
    include Openshift::SDK::Utils::ShellExec    
    validates_presence_of :name, :basedir
    ds_attr_accessor :name, :basedir, :uid, :gid, :homedir, :app_guid
    
    def self.bucket
      "admin"
    end

    # Initializes the user object. app object must be provided for username to
    # be selected properly. uid is optional and will automatically select an
    # unused uid if not provided.
    def initialize(app=nil,uid=nil)
      config = Openshift::SDK::Config.instance
      @app_guid, @basedir = app.guid,basedir
      @basedir ||= config.get("app_user_home")
      @guid = @name = "a#{app.guid[0..7]}"
      @uid = uid
      @gid = app.user_group_id
    end

    def homedir
      @homedir ||= "#{basedir}/#{name}"
    end

    # Creates the user account on the system or raises a UserCreationException.
    def create!
      cmd = "groupadd -f -g #{self.gid} g#{self.app_guid[0..7]}"
      out,err,ret = shellCmd(cmd)
      unless ret == 0
        raise UserCreationException.new("Unable to create group for user. Error: #{err}")
      end
            
      uid_str = ""
      FileUtils.mkdir_p self.basedir
      cmd = "useradd --base-dir #{self.basedir} -u #{self.uid} -g #{self.gid} -m #{self.name}"
      out,err,ret = shellCmd(cmd)
      if ret == 0
        self.homedir = "#{self.basedir}/#{self.name}"
      else
        raise UserCreationException.new("Unable to create user. Error: #{err}")
      end
    end
    
    # Deleted the user account on the system.
    def remove!
      cmd = "userdel -f -r #{self.name}"
      out,err,ret = shellCmd(cmd)
      unless ret == 0
        raise UserDeletionException.new("Unable to delete user. Error: #{err}")
      end
      
      cmd = "groupdel #{self.gid}"
      out,err,ret = shellCmd(cmd)
    end    

    def run_as(&block)
      old_gid = Process::GID.eid
      old_uid = Process::UID.eid
      fork{
        fork{
          Process::GID.change_privilege(@gid.to_i)
          Process::UID.change_privilege(@uid.to_i)      
          yield block          
        }
      }
    end
    
    def delete!
      uumap = UidUserMap.find(self.uid)
      uumap.delete!
      super
    end
  end
end
