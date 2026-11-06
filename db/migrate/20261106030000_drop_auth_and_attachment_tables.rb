# Auth (Devise), articles, Action Text and Active Storage were removed from the
# app. This drops their tables and the data in them, so it can't be rolled back.
class DropAuthAndAttachmentTables < ActiveRecord::Migration[8.1]
  def up
    # Children before the blobs table they reference
    drop_table :active_storage_variant_records, if_exists: true
    drop_table :active_storage_attachments, if_exists: true
    drop_table :active_storage_blobs, if_exists: true
    drop_table :action_text_rich_texts, if_exists: true
    drop_table :articles, if_exists: true
    drop_table :users, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
