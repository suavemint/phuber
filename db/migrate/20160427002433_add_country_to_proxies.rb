class AddCountryToProxies < ActiveRecord::Migration
  def change
    add_column :proxies, :country, :string
  end
end
