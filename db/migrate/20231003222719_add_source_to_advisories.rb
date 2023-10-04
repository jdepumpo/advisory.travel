class AddSourceToAdvisories < ActiveRecord::Migration[7.0]
  def change
    add_column :advisories, :source, :string
    add_column :advisories, :summary, :string
  end
end
