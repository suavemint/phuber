class CraigslistScrape < ActiveRecord::Base
  require 'open-uri'

  has_many :craigslist_postings
  has_one  :photographer_list

  serialize :postings_urls, Array

  def wait_time
    t = ( (1..30).to_a + (31..60).to_a * 2 ).sample
    puts "Waiting #{t} seconds before scraping..."
    return t
  end

  def proxy
    Proxy.good_proxies.order( "RANDOM()" ).first.location_string
  end

  def user_agent
    user_agents = [
      # "Mozilla/5.0 (iPhone; U; CPU OS 9_0 like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1A543 Safari/601.1",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/601.4.4 (KHTML, like Gecko) Version/9.0.3 Safari/601.4.4",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.4.4 (KHTML, like Gecko) Version/9.0.3 Safari/601.4.4",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/601.4.4 (KHTML, like Gecko) Version/9.0.3 Safari/601.4.4",
    # "Mozilla/5.0 (iPad; CPU OS 9_0 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13A344 Safari/601.1"
    ]
    user_agents.sample
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
    # @scrape ||= Nokogiri::HTML( open( search_url, "User-Agent" => user_agent, :proxy => proxy ) )
    @scrape ||= Nokogiri::HTML( open( search_url, "User-Agent" => user_agent ) )
  end

  def craigslist_url_class
    a_tags         = scrape.xpath("//a/@class")
    a_tag_classes  = a_tags.collect { |e| e.value }
    # Try to exclude the other 100-count class result, so we can pick out the
    # unique one corresponding to URLs we want.
    classes_counts = a_tag_classes.each_with_object( Hash.new(0) ) do |x, c_hash|
      c_hash[x] += 1 unless x.include?( "gallery")
    end
    classes_counts.each do |klass, count|
      return klass if count == 100
    end
  end

  def get_postings_urls
    urls = scrape.xpath("//a[@class='#{craigslist_url_class}']")
    @urls ||= urls.reject( &:nil? ).collect do |val|
      craigslist_url + val.attribute("href").value
    end
  end

  def save_postings_urls!
    get_postings_urls.each do |url|
      postings_urls << url
    end
    self.save!
  end

  # TODO add reply type: those with reply below text do not require an additional GET.
  # TODO add patterns to extract possible further contact information, regardless of message
  # on reply / reply-below.

  def save_postings!
    # TODO break out this self-altering action.
    self.scrape_contents = scrape.to_html
    get_postings_urls.each do |url|
      # TODO move the randomized wait time to outside this class?
      # sleep wait_time
      posting = CraigslistPosting.new( :url => url,
                                       :base_url => craigslist_url,
                                       :craigslist_scrape_id => self.id )
      self.postings_urls       << url
      self.craigslist_postings << posting
      posting.save!
      posting.get_email_information!
    end
    self.save!
  end

  # TODO add paging capabilities; search results don't all show on first page.

end
