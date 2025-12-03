class CreateSiteSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :site_settings do |t|
      t.string :key, null: false
      t.string :category, null: false
      t.json :value, null: false, default: {}
      t.boolean :is_system, null: false, default: false
      t.boolean :is_public, null: false, default: false
      t.text :description
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :site_settings, :key, unique: true
    add_index :site_settings, :category
    add_index :site_settings, :is_public
  end
end
