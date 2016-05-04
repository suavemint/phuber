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

  # TODO encapsulate proxy return failure externally.
  def scrape
    scrape_proxy = proxy
    response     = open( url, "User-Agent" => user_agent, :proxy => scrape_proxy.location_string )

    @scrape ||= Nokogiri::HTML( response )
    # rescue OpenURI::HTTPError
    # how to catch certain error codes?

    # Check for 'banned response'. Retry if it exists.
    # puts "Testing response code... #{response.status[0]}"
    rescue
      puts "HTTP error caught; trying request again..."
      scrape_proxy.increment :bad_count
      # case response.status[0]
      # puts "Response = #{response}"
      # when 403
      #   scrape_proxy.increment( :code_403_count )
      # when 500
      #   scrape_proxy.increment( :code_500_count )
      # else
      # end

      retry
  end

  def reply_url
    scrape.xpath("//a[@id='replylink']").attribute("href").text
  end

  def reply_scrape
    # scrape.xpath("//a[@class='mailapp']").attribute("href").value.split("?")
    # @reply_scrape ||= Nokogiri::HTML( open( base_url + reply_url, "User-Agent" => user_agent, :proxy => proxy ) )
    @reply_scrape ||= Nokogiri::HTML( open( base_url + reply_url, "User-Agent" => user_agent ) )
  end

  def returned_recaptcha?
    reply_content.empty?
  end

  def reply_content
    @email_contents ||= reply_scrape.xpath("//a[@class='mailapp']").attribute("href").text
    # Check if we're handed a reCAPTCHA.
    # puts "TESTING SCRAPECONTENTS BEFORE CAPTCHA DETERMINATION: #{@email_contents}"
    # return @email_contents
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
    puts "AM I RECAPTCHAD? #{self.recaptcha?}"
    puts "REPLY_CONTENT: #{reply_content}"
    reply_content.split("?").first.try(:split, ":").second
  end

  def get_email_subject_line
    puts "#get_email_subject_line"
    puts "AM I RECAPTCHAD? #{self.recaptcha?}"
    puts "REPLY_CONTENT: #{reply_content}"
    # TODO use URI.unescape on this string, to replace the %20, %40 with the appropriate chars.
    reply_content.split("?").second.try(:split, "=").second.gsub("%20", " ").gsub("&body", "")
  end

  # TODO see if this method is necessary
  def check_recaptcha_status!
    reply_type unless reply_type.nil?

    # unless scrape_contents.empty?
    unless reply_content.empty?
      # reply_type = "normal"
      self.update_attributes( :recaptcha => false, :scrape_contents => reply_content )
      puts "Recaptcha data not found in reply."
    end

    # if scrape_contents.xpath("//div[@class='captcha']").empty?
    if reply_content.xpath("//div[@class='captcha']").empty?
      puts "!Recaptcha data found in reply!"
      # reply_type = "recaptcha"
      self.update_attributes( :recaptcha => true )
      # self.save!
    end
  end

  def get_email_information!
    unless returned_recaptcha?
      email_address   = get_email_address
      subject_line    = get_email_subject_line
      # scrape_contents = scrape.text
      # self.save!
      puts "IN GETEMAILINFORMATION... not recaptchad."
      self.update_attributes( :recaptcha => false, :scrape_contents => reply_content,
      :email_address => email_address, :subject_line => subject_line )
    else
      if reply_content.xpath("//div[@class='captcha']").empty?
        puts "!Recaptcha data found in reply!"
        # reply_type = "recaptcha"
        self.update_attributes( :recaptcha => true )
      end
    end
  end
end
