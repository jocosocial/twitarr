class AddCategoryToSections < ActiveRecord::Migration[6.0]
  def change
    add_column :sections, :category, :string

    Section.update_all(category: :global)

    Section.add(:Kraken_forums, :kraken)
    Section.add(:Kraken_stream, :kraken)
    Section.add(:Kraken_seamail, :kraken)
    Section.add(:Kraken_calendar, :kraken)
    Section.add(:Kraken_deck_plans, :kraken)
    Section.add(:Kraken_games, :kraken)
    Section.add(:Kraken_karaoke, :kraken)
    Section.add(:Kraken_search, :kraken)
    Section.add(:Kraken_registration, :kraken)
    Section.add(:Kraken_user_profile, :kraken)
  end
end
