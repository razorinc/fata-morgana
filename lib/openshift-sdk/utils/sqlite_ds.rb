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
require 'sqlite3'
require 'open3'
require 'openshift-sdk/config'
require 'openshift-sdk/utils/logger'

module Openshift
  module SDK
    module Utils
      class Sqlite
        include Singleton
        include Openshift::SDK::Utils::Logger

        attr_reader :buckets
        def initialize
          @buckets = {}
        end
        
        def db_file(bucket)
          config = Openshift::SDK::Config.instance
          datasource_location = config.get('datasource_location')
          file = "#{datasource_location}/#{bucket}_db.db"
          `touch #{file}`
          `chgrp #{bucket} #{file}`
          `chmod 770 #{file}`
          file
        end
        
        def db(bucket)
          return buckets[bucket] if buckets[bucket]
          
          db = SQLite3::Database.new db_file(bucket)
          begin
            log.info "Creating DB #{bucket}_db.db"
            init_db db
          rescue Exception => e
            #ignore
          end
          buckets[bucket] = db
        end
        
        def init_db(db)
          rows = db.execute <<-SQL
                create table if not exists data (
                  type varchar(30),
                  id varchar(30),
                  value varchar(30)
                )
SQL
        end
        
        def find_all(type,bucket)
          return db(bucket).execute("select value from data where type=?", [type]) 
        end
        
        def find_all_ids(type,bucket)
          rows = db(bucket).execute("select id from data where type=?", [type])
          rows.flatten
        end
        
        def find(type, id, bucket)
          rows = db(bucket).execute("select value from data where type=? and id=?", [type, id.to_s]) 
          if rows.length > 0
            return rows[0][0]
          else
            return nil
          end
        end
        
        def save(type,id,value,bucket)
          d = db(bucket)
          d.transaction do 
            d.execute "DELETE FROM data where type=? and id=?", [type, id.to_s]
            d.execute "INSERT INTO data (type,id,value) VALUES (?,?,?)", [type,id.to_s,value]
          end
          find(type,id,bucket)
        end
        
        def delete(type,id,bucket)
          d = db(bucket)
          d.transaction do 
            d.execute "DELETE FROM data where type=? and id=?", [type, id.to_s]
          end          
        end
      end
    end
  end
end
