class CraigslistPosting < ActiveRecord::Base
  belongs_to :craigslist_scrape

  # before_save do
  #   email_address.gsub!("%40", "@")
  # end

  def normal?
    reply_type == "normal"
  end

  def recaptcha?
    reply_type == "recaptcha"
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

  def proxy
    a = Proxy.good_proxies.order( "RANDOM()" ).first
    puts "Using proxy = #{a.location_string}..."
    a
  end

  def get_response( url, force=false )
    unless force
      @response ||= open( url, "User-Agent" => user_agent )
    else
      @response = open( url, "User-Agent" => user_agent )
    end
  end

  # TODO encapsulate proxy return failure externally.
  def scrape
    # scrape_proxy = proxy
    # puts "Trying to get HTML from url #{url}..."

    # response     = open( url, "User-Agent" => user_agent )
    response = get_response( url )
    # response     = open( url, "User-Agent" => user_agent, :proxy => scrape_proxy.location_string )

    # @scrape ||= Nokogiri::HTML( response )
    return @scrape if @scrape
    sleep (1..30).to_a.sample
    puts "Sleeping in #scrape..."
    @scrape ||= Nokogiri::HTML( response )
  end

  # rescue => e
  #     puts "HTTP error caught; trying request again..."
  #     puts "Error content: #{e.message}"
  #     puts "Response content: #{response}"
  #     scrape_proxy.increment :bad_count
  #     retry
  # end

  def reply_url
    begin
      scrape.xpath("//a[@id='replylink']").try( :attribute, "href").try( :text )
    rescue NoMethodError
      nil
    end
  end

  def reply_url_scrape
    puts "Getting reply info from reply page #{base_url+reply_url}..." if reply_url
    # scrape.xpath("//a[@class='mailapp']").attribute("href").value.split("?")
    # @reply_url_scrape ||= Nokogiri::HTML( open( base_url + reply_url, "User-Agent" => user_agent, :proxy => proxy.location_string ) )
    return @reply_url_scrape if @reply_url_scrape
    puts "Sleeping in #reply_url_scrape..."
    sleep (1..30).to_a.sample
    # @reply_url_scrape ||= Nokogiri::HTML( open( base_url + reply_url, "User-Agent" => user_agent ) )
    @reply_url_scrape = Nokogiri::HTML( open( base_url + reply_url, "User-Agent" => user_agent ) )
  end

  def posting_returned_bad?
    reply_url.nil?
  end

  def reply_info_url_returned_bad?
    reply_content.nil?
  end

  def reply_content
    puts "scrape contents before reply button xpath: #{reply_url_scrape}"
    test = reply_url_scrape.xpath("//a[@class='mailapp']")
    puts "scrape contents after reply button xpath #{test}"
    if !test.empty?
      puts "Found legitimate reply info? #{test}"
      @reply_content ||= test.try(:attribute, "href").try( :text )
    else
      nil
    end
  end
    # unless email_contents.empty?
    # unless returned_recaptcha?
    #   reply_type = "normal"
    #   self.save!
    #   puts "Recaptcha data not found in reply."
    #   puts "SUCCESS? #{scrape_contents.attribute("href").text.split("?")}"
    # else
    #   puts "!Recaptcha data found in reply!"
    #   reply_type = "recaptcha"
    #   self.save!
    # end
    # return email_contents
    # If so, save type to denote such, and simply save, instead of trying
    # to scrape nil content.
    # unless mailapp_content.xpath("//div[@class='captcha']").empty?
    # if scrape_contents.xpath("//div[@class='captcha']").empty?
    # if reply_scrape.xpath("//div[@class='captcha']").empty?
      # puts "!Recaptcha data found in reply!"
      # reply_type = "recaptcha"
      # self.save!
    # end
  # end

  # TODO look in scrape text for 'reply below', and regex out information accordingly.
  # def set_reply_type
  #   if scrape
  # end

  def get_email_address
    puts "#get_email_address"
    # puts "AM I RECAPTCHAD? #{self.returned_recaptcha?}"
    # puts "REPLY_CONTENT: #{reply_content}"
    a = reply_content.split("?").first.try(:split, ":").second
    puts "Email address retrived: #{a}"
    return a
  end

  def get_email_subject_line
    puts "#get_email_subject_line"
    # puts "AM I RECAPTCHAD? #{self.returned_recaptcha?}"
    # puts "REPLY_CONTENT: #{reply_content}"
    # TODO use URI.unescape on this string, to replace the %20, %40 with the appropriate chars.
    a = reply_content.split("?").second.try(:split, "=").second.gsub("%20", " ").gsub("&body", "")
    puts "Email subject line retrived: #{a}"
    return a
  end

  # TODO see if this method is necessary
  # def check_recaptcha_status!
  #   reply_type unless reply_type.nil?
  #
  #   # unless scrape_contents.empty?
  #   unless reply_content.empty?
  #     # reply_type = "normal"
  #     self.update_attributes( :recaptcha => false, :scrape_contents => reply_content )
  #     puts "Recaptcha data not found in reply."
  #   else
  #     self.update_attribute( :recaptcha => true )
  #   end
  # end

  def get_email_information!
    unless (posting_returned_bad? || reply_info_url_returned_bad?)
      email_address   = get_email_address
      subject_line    = get_email_subject_line
      # scrape_contents = scrape.text
      # self.save!
      puts "IN GETEMAILINFORMATION... not recaptchad."
      self.update_attributes( :recaptcha => false, :scrape_contents => reply_content,
      :email_address => email_address, :subject_line => subject_line )
    else
      # puts "Should be recaptcha -- reply = #{reply_content}"
      self.update_attributes( :recaptcha => true )
    end
  end
end
