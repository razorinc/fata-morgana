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

module Vostok::SDK::Model
  class RPM
    attr_accessor :name, :summary, :version, :dependencies, :provides, :descriptor, :control, :hooks

    def initialize
      @dependencies = []
      @provides = []
      @hooks = []
    end

    def self.from_system(name)
      if is_installed?(name)
        rpm = RPM.new
        rpm.name = name
        rpm.parse_info
        rpm.parse_dependencies
        rpm.parse_provides
        rpm.parse_file_data
        rpm
      end
    end

    def self.is_installed?(name)
      ! `rpm -q #{name}`.end_with?("not installed\n")
    end

    def parse_info
      query_info.each do |line|
        if line.start_with?("Summary")
          @summary = line.split(":")[1].strip
        elsif line.start_with?("Version")
          @version = line.split(":")[1].strip
        end
      end
    end

    def parse_dependencies
      query_dependencies.each do |line|
        if /^ *dependency:/ =~ line
          @dependencies << line.split("dependency:")[1].strip
        end
      end
    end

    def parse_provides
      query_provides.each do |line|
        @provides << line.strip
      end
    end

    def parse_file_data
      query_file_data.each do |line|
        if /\/descriptor.json$/ =~ line
          @descriptor = line.strip
        elsif /\/control.spec$/ =~ line
          @control = line.strip
        elsif /\/hooks\// =~ line
          @hooks << line.strip
        end
      end
    end

    def query_info
      `repoquery --info #{name}`.split("\n")
    end

    def query_dependencies
      `yum deplist #{name}`.split("\n")
    end

    def query_provides
      `repoquery --provides #{name}`.split("\n")
    end

    def query_file_data
      `rpm -ql #{name}`.split("\n")
    end
  end
end
