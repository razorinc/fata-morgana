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

module Openshift::SDK::Utils
  class ShellExecutionException < Exception
    attr_accessor :rc
    def initialize(msg, rc=-1)
      super msg
      self.rc = rc 
    end
  end
end

module Openshift::SDK::Utils::ShellExec
  def shellCmd(cmd, pwd=".", ignore_err=false, expected_rc=0)
    Openshift::SDK::Utils::ShellExec.shellCmd(cmd, pwd, ignore_err, expected_rc)
  end
  
  def self.shellCmd(cmd, pwd=".", ignore_err=false, expected_rc=0)
    out = err = rc = nil         
    log = Openshift::SDK::log 
    begin
      log.debug cmd
      rc_file = "/var/tmp/#{Process.pid}.#{rand}"
      log.debug m_cmd = "cd #{pwd}; #{cmd}; echo $? > #{rc_file}"
      stdin, stdout, stderr = Open3.popen3(m_cmd){ |stdin,stdout,stderr,thr|
        stdin.close
        log.debug "--out--"
        log.debug out = stdout.read
        log.debug "--err--"
        log.debug err = stderr.read          
        stdout.close
        stderr.close  
      }
      f_rc_file = File.open(rc_file,"r")
      rc = f_rc_file.read.to_i
      f_rc_file.close
      log.debug `rm -f #{rc_file}`
      log.debug "rc = #{rc}"
    rescue Exception => e
      log.error e.class
      log.error e.message
      raise Openshift::SDK::Utils::ShellExecutionException.new(e.message) unless ignore_err
    end
    
    if !ignore_err and rc != expected_rc 
      raise Openshift::SDK::Utils::ShellExecutionException.new("Shell command '#{cmd}' returned an error. rc=#{rc}", rc)
    end
     
    return [out, err, rc]
  end
end