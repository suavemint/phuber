require 'csv'
require 'timeout'

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

    Proxy.order('created_at DESC').find_each.with_index do |proxy, i|

      puts "[#{i+1}/#{Proxy.count}] Checking proxy #{proxy.location_string}..."
      t1 = Time.now

      begin
      Timeout::timeout(10) do
        if proxy.bad?
          t2 = Time.now
          puts "\tProxy found to be bad."
          puts "\tTime spent: #{t2-t1}"
          proxy.increment(:bad_count).update_attributes( :bad => true )
        else
          t2 = Time.now
          puts "\tProxy found to be good."
          puts "\tTime spent: #{t2-t1}"
          proxy.increment(:good_count).update_attributes( :bad => false )
        end


      end # end timeout
      rescue => timeout_error
        puts "\tKilled for taking > 10 seconds."
        proxy.increment.(:bad_count).update_attribute( :bad => true )
       end
    end
  end
end
