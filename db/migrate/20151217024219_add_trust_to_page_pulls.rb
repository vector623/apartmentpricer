class AddTrustToPagePulls < ActiveRecord::Migration
  def change
    add_column :page_pulls, :trust, :string
  end
end
