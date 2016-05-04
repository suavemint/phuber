class CreateProxies < ActiveRecord::Migration
  def change
    create_table :proxies do |t|
      t.string :protocol
      t.string :ip_address
      t.string :port
      t.boolean :bad
      t.integer :bad_count
      t.integer :good_count

      t.timestamps null: false
    end
  end
end
