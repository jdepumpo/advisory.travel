class CreateCountries < ActiveRecord::Migration[7.0]
  def change
    create_table :countries do |t|
      t.string :name
      t.string :alpha2
      t.string :region

      t.timestamps
    end
  end
end
