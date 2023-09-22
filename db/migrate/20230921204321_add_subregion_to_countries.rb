class AddSubregionToCountries < ActiveRecord::Migration[7.0]
  def change
    add_column :countries, :subregion, :string
    add_column :countries, :capital, :string
    add_column :countries, :drives_on, :string
    add_column :countries, :population, :integer
    add_column :countries, :landlocked, :boolean
  end
end
