class CreateApartmentListings < ActiveRecord::Migration
  def change
    create_table :apartment_listings do |t|
      t.integer :page_pull_id
      t.string :unitname
      t.string :unitnum
      t.integer :floor
      t.decimal :rent
      t.date :movein

      t.timestamps null: false
    end
  end
end
