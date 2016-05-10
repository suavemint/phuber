CraigslistScrapeJob < ActiveJob::Base
  def perform( scrape_id )
    scrape = CraiglistScrape.find scrape_id
    scrape.save_postings!
end
