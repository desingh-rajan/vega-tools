class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :slug
      t.string :sku
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false
      t.decimal :discounted_price, precision: 10, scale: 2
      t.string :brand
      t.json :specifications, default: {}  # JSON for SQLite, works as JSONB in PostgreSQL
      t.boolean :published, default: false, null: false
      t.references :category, null: true, foreign_key: true  # null: true for uncategorized products

      t.timestamps
    end
    add_index :products, :slug, unique: true
    add_index :products, :sku, unique: true
    add_index :products, :published
    add_index :products, :brand
  end
end
