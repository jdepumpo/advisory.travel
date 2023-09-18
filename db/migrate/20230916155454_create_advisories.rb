class CreateAdvisories < ActiveRecord::Migration[7.0]
  def change
    create_table :advisories do |t|
      t.references :country, null: false, foreign_key: true
      t.references :issuer, null: false, foreign_key: true
      t.integer :level
      t.text :body

      t.timestamps
    end
  end
end
