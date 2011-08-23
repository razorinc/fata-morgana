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
require 'openshift-sdk/config'
require 'sqlite3'

module Openshift
  module SDK
    module Utils
      class Sqlite
        include Singleton
        attr_reader :db
        
        def initialize
          config = Openshift::SDK::Config.instance
          datasource_location = config.get('datasource_location')
          @db = SQLite3::Database.new datasource_location
          rows = @db.execute <<-SQL
            create table if not exists data (
              type varchar(30),
              id varchar(30),
              value varchar(30)
            );
SQL
        end
        
        def find_all(type)
          return @db.execute("select value from data where type=?", [type]) 
        end
        
        def find_all_ids(type)
          return @db.execute("select id from data where type=?", [type])
        end
        
        def find(type, id)
          rows = @db.execute("select value from data where type=? and id=?", [type, id.to_s]) 
          if rows.length > 0
            return rows[0][0]
          else
            return nil
          end
        end
        
        def save(type,id,value)
          @db.transaction do 
            @db.execute "DELETE FROM data where type=? and id=?", [type, id.to_s]
            @db.execute "INSERT INTO data (type,id,value) VALUES (?,?,?)", [type,id.to_s,value]
          end          
          find(type,id)
        end
        
        def delete(type,id)
          @db.transaction do 
            @db.execute "DELETE FROM data where type=? and id=?", [type, id.to_s]
          end          
        end
      end
    end
  end
end
