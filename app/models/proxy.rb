class Proxy < ActiveRecord::Base
  require 'open-uri'

  scope :good_proxies, -> { where( :bad => false ) }
  scope :bad_proxies,  -> { where( :bad => true ) }

  def location_string
    "#{protocol}://#{ip_address}:#{port}"
  end

  def bad?
    begin
      test_request = Nokogiri::HTML( open( "http://google.com",
                                           :proxy => location_string ))
    rescue RuntimeError, OpenURI::HTTPError,
           URI::InvalidURIError, SystemCallError
      return true
    end
    return false
  end
end
