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
require 'openshift-sdk/model/user'
require 'openshift-sdk/model/application'
require 'openshift-sdk/model/component_instance'
require 'openshift-sdk/model/cartridge'

module Openshift::SDK::Utils
  
  class HookNotFoundException < Exception
  end
  
  def self.get_application
    gid = Process::GID.eid
    app_guid = Openshift::SDK::Model::GidApplicationMap.find(gid).app_guid
    unless app_guid
      print "Unable to find application owned by this user.\n"
      return -404
    end
    app = Openshift::SDK::Model::Application.find(app_guid,gid.to_s)
  end

  def self.run_hook(app, component_path, hook_name, args)
    # check if application has its descriptor resolved
    if app.component_instance_map.length == 0
      app.resolve_references
    end

    # get application from current user name if user is not root
    ENV["OPENSHIFT_CONFIG_DIR"] = "/etc/openshift"  # default
    ENV["OPENSHIFT_PROFILE"] = "express" # `cat /etc/openshift/platform.conf` #  express|flex

    # App/Cartridge specific:
    ENV["OPENSHIFT_APP_GUID"] = app.guid
    hook_context = ENV["OPENSHIFT_HOOK_CONTEXT"]
    begin
      hook_context, cartridge = resolve_component_context(app, hook_context, component_path)
    rescue Exception => ex
      Openshift::SDK.log.error ex.message
      Openshift::SDK.log.error ex.backtrace.join("\n")
      err = "ERROR : Component '#{component_path}' not found.\n"
      raise HookNotFoundException.new(err)
    end

    hook_cmd = cartridge.package_path + "/openshift/hooks/" + hook_name
    if cartridge.hooks.include? hook_cmd
      fork do
        ENV["OPENSHIFT_HOOK_CONTEXT"] = hook_context
        ENV["OPENSHIFT_APP_HOME_DIR"] = app.package_root  #  ${HOME}/
        ENV["OPENSHIFT_APP_DEV_DIR"] = app.package_root + "/development"        #  ${HOME}/development/
        ENV["OPENSHIFT_APP_REPO_DIR"] = app.package_root + "/repository"        #  ${HOME}/repository/
        ENV["OPENSHIFT_APP_PROD_DIR"] = app.package_root + "/production"        #  ${HOME}/production/
        `hook_cmd #{app.name} #{args}`
        exit
      end
      pid = Process.wait
    else
      err = "Hook '#{hook_name}' not found in component '#{component_path}' which resolves to '#{cartridge.name}', where available hooks are : \n"
      cartridge.hooks.each { |hook|
        err += "\t#{hook}\n"
      }
      raise HookNotFoundException.new(err)
    end
  end

  def self.resolve_component_context(app, hook_context, component_path)
    # remove the application path from hook_context
    if not hook_context
      hook_context = app.package_path + "/openshift"
      if component_path.nil? or component_path==""
        return hook_context, app
      end
    end
    hook_context = hook_context.squeeze('/')
    base_path, current_component_path = hook_context.split("/openshift")
    if current_component_path.nil?
      current_component_path = "" 
      full_path_s = component_path
    else
      full_path_s = current_component_path + "/" + component_path
    end
    map_obj = get_inst_from_map(app, full_path_s)
    if not map_obj
      raise
      # FIXME : if component instance_map is broken (does not collapse auto-delimiters such as profile names)
      #  search the path in the application's resolved descriptor
      #  This could also result in multiple cartridges
    end
    
    component_dir_path = component_path.gsub('.', '/')
    hook_context = hook_context + "/" + component_dir_path
    hook_context = hook_context.squeeze('/')
    cartridge = nil
    case map_obj
      when Openshift::SDK::Model::ComponentInstance
        cartridge = map_obj.parent_group.profile.parent_descriptor.parent_cartridge
      when Openshift::SDK::Model::Cartridge
        cartridge = map_obj
      when Openshift::SDK::Model::Application
        cartridge = map_obj
    end
    
    return hook_context, cartridge
  end

  def self.get_inst_from_map(app, path)
    if not path
      return app
    end
    cur_path = path
    cur_path = cur_path.gsub('/', '.')
    cur_path = cur_path.squeeze('.')
    cur_path = cur_path.gsub(/^\.|\.$/, '')
    cur_inst = app.component_instance_map[cur_path]
    if not cur_inst
      key = app.component_instance_map.keys.sort.find(cur_path).next
      cur_inst = app.component_instance_map[key] if key
    end
    return cur_inst
  end

  def self.resolve_feature_path(app, component_path, cur_inst_or_path)
    cur_inst = nil
    case cur_inst_or_path
      when NilClass
        cur_inst = app
      when String
        base, cur_path = cur_inst_or_path.split("/openshift/")
        cur_inst = get_inst_from_map(cur_path)
      else
        cur_inst = cur_inst_or_path
    end

    case cur_inst
      when Openshift::SDK::Model::ComponentInstance
        cur_inst = cur_inst_or_path
      when Openshift::SDK::Model::CartridgeInstance
        cur_inst = cur_inst_or_path
      when Openshift::SDK::Model::Cartridge
        cur_inst = cur_inst_or_path
      when Openshift::SDK::Model::Application
        cur_inst = cur_inst_or_path
      else
        raise "Cannot resolve component"
    end

  end
end
