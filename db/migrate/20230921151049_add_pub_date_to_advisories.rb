class AddPubDateToAdvisories < ActiveRecord::Migration[7.0]
  def change
    add_column :advisories, :pub_date, :date
  end
end
