class CreateIssuers < ActiveRecord::Migration[7.0]
  def change
    create_table :issuers do |t|
      t.string :name

      t.timestamps
    end
  end
end
