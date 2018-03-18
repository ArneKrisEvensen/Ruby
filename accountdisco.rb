#!/usr/bin/env ruby
# This is a discovery script which was useful to identify all accounts on a DB that was active and matches a set filter outline in the SQL filter.

require 'mysql2'
require 'pp'

module QuickExport
  class DB
    require 'mysql2'
    attr_reader :db_name, :db_host, :db_user, :db_pass, :conn
    @@dbs_pool = []
    def initialize(params = nil)

      default_opts = {
        db_name: '_config',
        db_host: ENV['__DB_CONFIG'],
        db_user: ENV['__DB_USERNAME'],
        db_pass: ENV['__DB_PASSWORD']
      }
      default_opts.merge!(params) unless params.is_a?(NilClass)
      default_opts.each { |k, v| instance_variable_set("@#{k}", "#{v}") }
      # add this instance to the class variable containing all instances
      @@dbs_pool << self
      @conn = connect
    end

    def self.all_prod_dbs
      @@dbs_pool
    end

    def query(sql)
      res = @conn.query(sql)
      return res.size > 0 ? res : false
    end

    def use(db_name)
      @conn.query("USE #{db_name};")
    end

    private

    def connect
        Mysql2::Client.new(
          host: @db_host,
          username: @db_user,
          password: @db_pass,
          database: @db_name
        )
    end
  end

  class Account
    attr_accessor :licences, :lifecycle, :purpose, :subscriber
    attr_reader   :name, :client_id, :db_host

    def initialize(name)
      @name = name
      @db_config = QuickExport::DB.all_prod_dbs.select { |dbs| dbs.db_host == ENV['__BP_DB_CONFIG'] }[0] || QuickExport::DB.new
      #@db_config = QuickExport::DB.new
      account_meta

      @db_account = QuickExport::DB.all_prod_dbs.select { |dbs| dbs.db_host == @db_host }[0] || QuickExport::DB.new(db_name: @name, db_host: @db_host)
      @db_account.use(@name)
    end

    def query(sql)
      @db_account.query(sql)
    end

    private
    def account_meta
      sql = <<-SQL
                  SELECT db_field
                    FROM db_table
               LEFT JOIN db_another_tabble USING(account_id)
                   WHERE account_name = '#{@name}';
               SQL

      @db_config.query(sql).first.each { |k, v| instance_variable_set("@#{k}", v) unless v.nil? }
    end
  end
end

config_conn = QuickExport::DB.new

accounts = config_conn.query("SELECT db_field FROM db_table WHERE db_field NOT IN ('ARCH','DLTD');").entries.map {|acc| acc['client_db_database']}.sort

sql = <<-SQL
    SELECT database() AS account_id,
       count(*) AS num
FROM db_table
WHERE db_field = 1
  AND db_field2 = 1
ORDER BY NULL;
SQL

accounts.each  do |a|
  acc = QuickExport::Account.new(a)
  res = acc.query(sql)
  res.entries.each {|r| puts r.values.join("\t")} if res
end
