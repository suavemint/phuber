CraigslistScrapeJob < ActiveJob::Base
  def perform( scrape_id )
    scrape = Scrape.find scrape_id
    scrape.save_postings!
end
