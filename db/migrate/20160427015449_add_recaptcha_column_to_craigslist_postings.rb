class AddRecaptchaColumnToCraigslistPostings < ActiveRecord::Migration
  def change
    add_column :craigslist_postings, :recaptcha, :boolean
  end
end
