class CreateFloorPlans < ActiveRecord::Migration
  def change
    create_table :floor_plans do |t|
      t.string :name
      t.integer :beds
      t.integer :baths
      t.integer :sqft

      t.timestamps null: false
    end
  end
end
