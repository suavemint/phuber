class RemoveScrapesIdFromScrapesAddScrapesIdToPostings < ActiveRecord::Migration
  def change
    add_column :craigslist_postings, :craigslist_scrape_id, :integer
    remove_column :craigslist_scrapes, :craigslist_scrape_id
  end
end
