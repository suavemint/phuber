namespace :photographers do
  desc "For Los Angeles, check craigslist for photographers and return list"
  task :get_for_los_angeles => :environment do |task|
    CraigslistScrape.create()
  end

  desc "For a location, check craigslist for photographers and return list"
  task :get_for_location, [:location] => :environment do |task|

  end
end
