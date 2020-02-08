class DisableTrigramExtension < ActiveRecord::Migration[6.0]
  def up
    execute "DROP EXTENSION IF EXISTS pg_trgm;"
  end

  def down
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
  end
end
