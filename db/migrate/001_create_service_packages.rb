# frozen_string_literal: true

# Migration to create the service_packages table.
# The version [5.2] should match the Rails version used by your Redmine instance.
class CreateServicePackages < ActiveRecord::Migration[5.2]
  def change
    create_table :service_packages do |t|
      # Name of the service package (e.g., "Pro 1", "Video Package")
      t.string :name, null: false
      # Number of posts included in this package
      t.integer :post_count, null: false, default: 0
      # Optional description for the service package
      t.text :description
      # Standard timestamps (created_at, updated_at)
      t.timestamps
    end

    # Add an index to the name column for uniqueness and faster lookups.
    add_index :service_packages, :name, unique: true
  end
end 
