class AddLocationToFloorPlans < ActiveRecord::Migration
  def change
    add_column :floor_plans, :location, :string
  end
end
