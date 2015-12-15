class AddPagePullIdToFloorPlans < ActiveRecord::Migration
  def change
    add_column :floor_plans, :page_pull_id, :integer
  end
end

