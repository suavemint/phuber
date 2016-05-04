class AddPostingsUrlsToCraigslistScrape < ActiveRecord::Migration
  def change
    add_column :craigslist_scrapes, :postings_urls, :text
  end
end
