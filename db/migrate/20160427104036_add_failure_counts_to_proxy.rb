class AddFailureCountsToProxy < ActiveRecord::Migration
  def change
    add_column :proxies, :code_403_count, :integer
    add_column :proxies, :code_500_count, :integer
  end
end
