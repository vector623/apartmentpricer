class CreatePagePulls < ActiveRecord::Migration
  def change
    create_table :page_pulls do |t|
      t.string :location
      t.string :url
      t.text :html

      t.timestamps null: false
    end
  end
end
