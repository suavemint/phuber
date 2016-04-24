class AddLocationAndSearchToClScrape < ActiveRecord::Migration
  def change
    add_column :craigslist_scrapes, :location_string, :string
    add_column :craigslist_scrapes, :search_string, :string
  end
end
