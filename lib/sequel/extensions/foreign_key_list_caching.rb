# frozen-string-literal: true
#
# The foreign_key_caching extension adds a few methods to Sequel::Database
# that make it easy to dump information about database foreign_key_list to a file,
# and load it from that file.  Loading foreign_key information from a
# dumped file is faster than parsing it from the database, so this
# can save bootup time for applications with large numbers of foreign_key.
#
# Basic usage in application code:
#
#   DB = Sequel.connect('...')
#   DB.extension :foreign_key_caching
#   DB.load_foreign_key_list_cache('/path/to/foreign_key_list_cache.dump')
#
#   # load model files
#
# Then, whenever database indicies are modified, write a new cached
# file.  You can do that with <tt>bin/sequel</tt>'s -X option:
#
#   bin/sequel -X /path/to/foreign_key_list_cache.dump postgres://...
#
# Alternatively, if you don't want to dump the foreign_key information for
# all tables, and you don't worry about race conditions, you can
# choose to use the following in your application code:
#
#   DB = Sequel.connect('...')
#   DB.extension :foreign_key_caching
#   DB.load_foreign_key_list_cache?('/path/to/foreign_key_list_cache.dump')
#
#   # load model files
#
#   DB.dump_foreign_key_list_cache?('/path/to/foreign_key_list_cache.dump')
#
# With this method, you just have to delete the foreign_key dump file if
# the schema is modified, and the application will recreate it for you
# using just the tables that your models use.
#
# Note that it is up to the application to ensure that the dumped
# foreign_key cache reflects the current state of the database.  Sequel
# does no checking to ensure this, as checking would take time and the
# purpose of this code is to take a shortcut.
#
# The foreign_key cache is dumped in Marshal format, since it is the fastest
# and it handles all ruby objects used in the foreign_key_list hash.  Because of this,
# you should not attempt to load from an untrusted file.
#
# Related module: Sequel::ForeignKeyListCaching

#
module Sequel
  module ForeignKeyListCaching
    # Set foreign_key cache to the empty hash.
    def self.extended(db)
      db.instance_variable_set(:@foreign_key_list, {})
    end
    
    # Dump the foreign_key cache to the filename given in Marshal format.
    def dump_foreign_key_list_cache(file)
      File.open(file, 'wb'){|f| f.write(Marshal.dump(@foreign_key_list))}
      nil
    end

    # Dump the foreign_key cache to the filename given unless the file
    # already exists.
    def dump_foreign_key_list_cache?(file)
      dump_foreign_key_list_cache(file) unless File.exist?(file)
    end

    # Replace the foreign_key cache with the data from the given file, which
    # should be in Marshal format.
    def load_foreign_key_list_cache(file)
      @foreign_key_list = Marshal.load(File.read(file))
      nil
    end

    # Replace the foreign_key cache with the data from the given file if the
    # file exists.
    def load_foreign_key_list_cache?(file)
      load_foreign_key_list_cache(file) if File.exist?(file)
    end

    # If no options are provided and there is cached foreign_key information for
    # the table, return the cached information instead of querying the
    # database.
    def foreign_key_list(table, opts=OPTS)
      return super unless opts.empty?

      quoted_name = literal(table)
      if v = Sequel.synchronize{@foreign_key_list[quoted_name]}
        return v
      end

      result = super
      Sequel.synchronize{@foreign_key_list[quoted_name] = result}
      result
    end

    private

    # Remove the foreign_key cache for the given schema name
    def remove_cached_schema(table)
      k = quote_schema_table(table)
      Sequel.synchronize{@foreign_key_list.delete(k)}
      super
    end
  end

  Database.register_extension(:foreign_key_list_caching, ForeignKeyListCaching)
end
