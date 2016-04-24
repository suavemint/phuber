class AddTables < ActiveRecord::Migration
  def up
    create_table :photographer_lists do |t|
      t.string :name
      t.string :url
      t.text   :scrape_contents
    end

    create_table :craigslist_postings do |t|
      t.string :url
      t.string :reply_type
      t.text   :scrape_contents
    end

    create_table :craigslist_scrapes do |t|
      t.string :url
      t.text   :scrape_contents
    end
  end

  def down
    drop_table :photographer_lists
    drop_table :craigslist_postings
    drop_table :craigslist_scrapes
  end
end
