class ScraperBase
  require 'open-uri'

  attr_reader :url, :scrape

  # Precondition: Start with a user's URL on Meetup.
  def initialize( url )
    @url = url
  end

  def scrape
    # Before scraping, wait.
    sleep wait_time
    # Now, scrape.
    test_call = open( @url, "User-Agent" => user_agent )
    puts "Status code: #{test_call.status.first}"
    @scrape ||= Nokogiri::HTML( test_call, nil, "UTF-8" )
  end

  def save_scrape_contents!
    # Only save as astring.
    self.scrape_contents = @scrape.to_html
    self.save!
  end

  # Choose randomly from a list of user-agent strings, which
  # will be sent in the GET header.
  # Currently, assume only one Mac and a handful of iOS devices.
  def user_agent
    user_agents = [
      "Mozilla/5.0 (iPhone; U; CPU OS 9_0 like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1A543 Safari/601.1",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/601.4.4 (KHTML, like Gecko) Version/9.0.3 Safari/601.4.4",
      "Mozilla/5.0 (iPad; CPU OS 9_0 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13A344 Safari/601.1"
    ]
    user_agents.sample
  end

  # Choose randomly from a range of times in seconds, to be used
  # by the ActiveJob which is running multiple enqueued Scrapers.
  def wait_time
    if Rails.env.production?
      # Use a weight of 50% more likely to choose between [30, 60] (seconds).
      t = ( (1...30).to_a + (30..60).to_a * 2).sample
      puts "Waiting for #{t} seconds before scraping."
      t
    else
      puts "No waiting before scraping; in development or production mode."
      0
    end
  end
end

class MeetupMemberScraper < ScraperBase
  attr_reader :user_id

  def initialize( url )
    super
    @user_id = url.split("/").last
  end

  def first_name_and_last_initial
    scrape.xpath("//title").first.text.split("-").first.strip.split
  end

  def first_name
    first_name_and_last_initial.first
  end

  def last_name
    first_name_and_last_initial.second
  end

  # For a given Meetup URL, retrieve the first name and last initial.
  #def set_first_name_and_last_initial!
  def create_or_update_person!
    person = Person.find_or_create!( :email_address => @email )
    person.update_attributes( :first_name    => first_name,
                              :last_name     => last_name,
                              :meetup_id     => @user_id )
  end

  def user_groups
    scrape.xpath("//div[@class='figureset-figure']/a[@class='omnCamp omngj_pswg4']") 
  end

  def user_groups_urls
    user_groups.map do |element|
      element.attribute("href").text
    end
  end

  def create_groups_from_users_groups!
    user_groups_urls.each do |url_and_name|
      Group.create!( :name => url_and_name.first,
                     :url => url_and_name.second )
    end
  end
end

class GoogleScraper < ScraperBase
  # def initialize( search_term, domain="linkedin.com" )
  def initialize( domain, pattern )
    # Recommended to use the email address in concert with LinkedIn.
    @search_term = search_term.gsub(".", "%40")
    @domain      = domain
    @url         = get_search_url
    @results     = 100
    @google_scrape = scrape
    @scraped_urls  = urls
  end

  # TODO add ?results=100 to URL.
  def search_url
    "https://www.google.com/search?results=#{@results}?q=\"#{@search_term}\"%20site%3A#{@domain}\""
  end

  # Keep scrapes memoized!
  def scrape
    @scrape ||= Nokogiri::HTML( open( search_url) )
  end

  # Extract URLs from Google response.
  def urls
    # FIXME TODO
    scrape.xpath()
  end

  # Currently, just grab the first result's title (which works ~well for
  # LinkedIn. Need to expand this to all entries, else save entire scrape
  # for future mining.
  def get_first_and_last_name
    scrape.xpath("//h3[@class='r']").first.split
  end

  def persist_scraped_urls_contents!
    @scraped_urls.each do |url|
      # Offload chance of getting denied from spamming frequency.
      ScraperJob.perform_later( url )      
    end
  end
end

