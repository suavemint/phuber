class AddBaseUrlToCraigslistPosting < ActiveRecord::Migration
  def change
    add_column :craigslist_postings, :base_url, :string
  end
end
