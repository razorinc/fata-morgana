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

module Openshift::SDK::Model
  class UserCreationException < Exception
  end

  class UserDeletionException < Exception
  end

  # == System User
  #
  # Represents a user account on the system. This object will keep track of
  # name, home directory, user id.
  class User < OpenshiftModel
    include Openshift::SDK::Utils::ShellExec
    validates_presence_of :name, :basedir
    ds_attr_accessor :name, :basedir, :uid, :homedir, :app

    # Initializes the user object. app object must be provided for username to
    # be selected properly. uid is optional and will automatically select an
    # unused uid if not provided.
    def initialize(app=nil,uid=nil)
      config = Openshift::SDK::Config.instance
      @app, @basedir = app,basedir
      @basedir ||= config.get("app_user_home")
      @guid = @name = "a#{app.guid[0..7]}"
      @uid = uid
    end

    # Creates the user account on the system or raises a UserCreationException.
    # The min,max user id and group id for the created account can be
    # configured using the min_user_id, max_user_id, group_id configuration
    # entries.
    def create!
      config = Openshift::SDK::Config.instance
      min_uid = config.get("min_user_id") || "100"
      max_uid = config.get("max_user_id") || "1000"
      uid_str = "-u #{self.uid}" if self.uid
      FileUtils.mkdir_p self.basedir
      cmd = "useradd --base-dir #{self.basedir} #{uid_str} -m -K UID_MIN=#{min_uid} -K UID_MAX=#{max_uid} #{self.name}"
      out,err,ret = shellCmd(cmd)
      if ret == 0
        self.uid ||= get_uid
        self.homedir = "#{self.basedir}/#{self.name}"
      else
        raise UserCreationException.new("Unable to create user. Error: #{err}")
      end
    end

    def setup_app_territory 
        config = Openshift::SDK::Config.instance
        prod_dir ||= config.get("app_prod_dir")
        shared_dir ||= config.get("app_shared_dir")
        prod_dir = prod_dir + "/" + self.name
        shared_dir = shared_dir + "/" + self.name
        FileUtils.mkdir_p prod_dir
        FileUtils.mkdir_p shared_dir

        FileUtils.chown_R self.name, get_group, prod_dir
        FileUtils.chown_R self.name, get_group, shared_dir

        FileUtils.chmod 1760,prod_dir
        FileUtils.chmod 1760,shared_dir
    end

    def get_uid
      `id -u #{self.name}`
    end

    def get_group
        g = `id -g #{self.name}`
        Integer(g)
    end

    def switch_privileges
        Process::GID.change_privilege(Integer(`id -g #{self.name}`))
        Process::UID.change_privilege(Integer(`id -u #{self.name}`))
    end

    # Deleted the user account on the system.
    def delete!
      cmd = "userdel -f -r #{self.name}"
      out,err,ret = shellCmd(cmd)
      unless ret == 0
        raise UserDeletionException.new("Unable to delete user. Error: #{err}")
      end
    end
  end
end
