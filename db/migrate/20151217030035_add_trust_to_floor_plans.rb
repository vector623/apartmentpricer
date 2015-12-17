class AddTrustToFloorPlans < ActiveRecord::Migration
  def change
    add_column :floor_plans, :trust, :string
  end
end
