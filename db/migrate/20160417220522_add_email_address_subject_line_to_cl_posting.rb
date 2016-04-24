class AddEmailAddressSubjectLineToClPosting < ActiveRecord::Migration
  def change
    add_column :craigslist_postings, :email_address, :string
    add_column :craigslist_postings, :subject_line, :string
  end
end
