require 'csv'

namespace :proxies do
  desc "Import proxies from a CSV file. Does not upload duplicate rows."
  task :load, [:proxy_file_path] => :environment do |task, args|
    CSV.foreach( args[:proxy_file_path],
                 :headers           => true,
                 :header_converters => :symbol ) do |row|
      Proxy.find_or_create_by! row.to_h
    end
  end

  desc "Run over all saved proxies, checking each for usability."
  task :update_status => :environment do |task|
    puts "Going to check #{Proxy.count} proxies."

    Proxy.find_each.with_index do |proxy, i|
      puts "[#{i+1}/#{Proxy.count}] Checking proxy #{proxy.location_string}..."
      if proxy.bad?
        puts "\tProxy found to be bad."
        proxy.increment(:bad_count).update_attributes( :bad => true )
      else
        puts "\tProxy found to be good."
        proxy.increment(:good_count).update_attributes( :bad => false )
      end
    end
  end
end
