class CreateRegistrationCodes < ActiveRecord::Migration[5.2]
  def change
    create_table :registration_codes do |t|
      t.string :code

      t.timestamps
    end
    add_index :registration_codes, :code, unique: true
  end
end
