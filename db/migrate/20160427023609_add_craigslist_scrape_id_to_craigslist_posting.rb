class AddCraigslistScrapeIdToCraigslistPosting < ActiveRecord::Migration
  def change
    add_column :craigslist_postings, :craigslist_scrape_id, :integer
    remove_column :craigslist_scrapes, :craiglist_scrape_id
  end
end
