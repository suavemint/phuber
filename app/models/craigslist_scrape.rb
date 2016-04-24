class CraigslistScrape < ActiveRecord::Base
  require 'open-uri'

  has_many :craigslist_postings
  has_one  :photographer_list

  def wait_time
    t = ( (1..30).to_a + (31..60).to_a * 2 ).sample
    puts "Waiting #{t} seconds before scraping..."
    return t
  end

  def location
    location_string.tr(" ", "").downcase
  end

  def photographer
    if search_string 
      search_string
    else
      "photographer"
    end
  end

  def craigslist_url
    if location_string
      "http://#{location}.craigslist.org"
    else
      "http://craigslist.org"
    end
  end

  def search_url
    craigslist_url + "/search/bbb?sort=rel&query=#{photographer}"
  end

  def scrape
    # TODO copy and insert time delay and user agent randomization.
    @scrape ||= Nokogiri::HTML( open( search_url ) )
  end

  def postings_urls
    scrape.xpath("//a[@class='i']").collect do |val|
      craigslist_url + val.attribute("href").value
    end
  end

  # TODO add reply type: those with reply below text do not require an additional GET.
  # TODO add patterns to extract possible further contact information, regardless of message
  # on reply / reply-below.

  def save_postings!
    # TODO break out this self-altering action.
    self.scrape_contents = scrape.text
    postings_urls.each do |url|
      # TODO move the randomized wait time to outside this class?
      # sleep wait_time
      posting = CraigslistPosting.new( :url => url, :base_url => craigslist_url )
      self.craigslist_postings << posting
      posting.get_email_information!
    end 
    self.save!
  end

  # TODO add paging capabilities; search results don't all show on first page.

end
