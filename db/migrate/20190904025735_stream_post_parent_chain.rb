class StreamPostParentChain < ActiveRecord::Migration[5.2]
  def change
    add_column :stream_posts, :parent_chain, :bigint, array: true, default: []
    add_index :stream_posts, :parent_chain, using: 'gin'
  end
end
