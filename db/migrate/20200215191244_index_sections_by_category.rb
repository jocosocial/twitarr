class IndexSectionsByCategory < ActiveRecord::Migration[6.0]
  def change
    add_index :sections, :category

    Section.repopulate_sections
  end
end
