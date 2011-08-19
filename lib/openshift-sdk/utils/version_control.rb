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
require 'open3'
require 'openshift-sdk/config'
require 'openshift-sdk/utils/logger'
require 'openshift-sdk/utils/shell_exec'

module Openshift
  module SDK
    module Utils
      class ShellExecutionException < Exception ;
        attr_accessor :rc
        def initialize(msg, rc=-1)
          super msg
          self.rc = rc 
        end
      end
      
      class VersionControl
        attr_accessor :work_tree,:git_dir, :is_bare
        include Openshift::SDK::Utils::Logger
        include Openshift::SDK::Utils::ShellExec
        
        def initialize(work_tree,git_dir=nil)
          self.work_tree = work_tree
          self.git_dir = git_dir || "#{work_tree}/.git"
          out, err = shellCmd("git --work-tree=#{self.work_tree} --git-dir=#{self.git_dir} config --get core.bare", self.work_tree, true)
          @is_bare = (out.strip == "true")
        end
        
        def bare?
          is_bare
        end
        
        def create(bare_repo=false)
          shellCmd("mkdir -p #{self.work_tree}")
          shellCmd("mkdir -p #{self.git_dir}")
          if bare_repo
            shellCmd "git --bare --git-dir=#{self.git_dir} init", self.work_tree
          else
            shellCmd "git --git-dir=#{self.git_dir} init", self.work_tree
          end
          self.is_bare=bare_repo
        end
        
        def create_from(from_repo)
          unless from_repo.bare?
            log.error "Cannot create share repository from non-bare base"
            return false
          end
          create          
          
          ["branches", "hooks", "objects", "info", "packed-refs", "refs"].each do |file|
            shellCmd("cd #{self.git_dir}; rm -rf #{file}; ln -nsf #{from_repo.git_dir}/#{file} #{file}")
          end
          
          begin 
            reset
          rescue ShellExecutionException => ex
            if ex.rc == 128 #empty repository
              shellCmd("touch .gitignore", self.work_tree)
              add(".gitignore")
              commit("Initial commit")
            else
              raise ex
            end
          end
        end
        
        def clone(repo_url)
          shellCmd("git --work-tree=#{self.work_tree} --git-dir=#{self.git_dir} clone #{repo_url} #{repo_path}")
        end
        
        def add_all(subdir_path=".")
          shellCmd("git --work-tree=#{self.work_tree} --git-dir=#{self.git_dir} add -A -- #{subdir_path}",self.work_tree)
        end
        
        def add(file_paths)
          if file_paths.class == 'Array'
            shellCmd("git --work-tree=#{self.work_tree} --git-dir=#{self.git_dir} add -- #{file_paths.join(' ')}", self.work_tree)
          else
            shellCmd("git --work-tree=#{self.work_tree} --git-dir=#{self.git_dir} add -- #{file_paths}", self.work_tree)
          end
        end
        
        def remove(file_paths)
          if file_paths.class == 'Array'
            shellCmd("git --work-tree=#{self.work_tree} --git-dir=#{self.git_dir} rm -r -- #{file_paths.join(' ')}", self.work_tree)
          else
            shellCmd("git --work-tree=#{self.work_tree} --git-dir=#{self.git_dir} rm -r -- #{file_paths}", self.work_tree)
          end
        end
        
        def reset(revision="HEAD",hard=true)
          if hard
            shellCmd "git --work-tree=#{self.work_tree} --git-dir=#{self.git_dir} reset --hard #{revision}", self.work_tree
          else
            shellCmd "git --work-tree=#{self.work_tree} --git-dir=#{self.git_dir} reset #{revision}", self.work_tree
          end
        end
        
        def commit(message="no message provided")
          shellCmd "git --work-tree=#{self.work_tree} --git-dir=#{self.git_dir} commit -m \"#{message}\"", self.work_tree
        end
      end
    end
  end
end