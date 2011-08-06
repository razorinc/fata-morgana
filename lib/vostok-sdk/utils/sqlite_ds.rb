require 'rubygems'
require 'vostok-sdk/config'
require 'sqlite3'

module Vostok
  module SDK
    class Sqlite
      include Singleton
      attr_reader :db
      
      def initialize
        config = Vostok::SDK::Config.instance
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
      
      def find(type, id)
        @db.execute("select value from data where type=? and id=?", [type, id]) do |row|
          return row[0]
        end
        return nil
      end
      
      def save(type,id,value)
        @db.execute "REPLACE INTO data (type,id,value) VALUES (?,?,?)", [type,id,value]
        find(type,id)
      end
    end
  end
end