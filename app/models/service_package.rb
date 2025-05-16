# frozen_string_literal: true

# Represents a service package that can be associated with a project.
class ServicePackage < ActiveRecord::Base
  # unloadable is a Redmine specific directive to allow class reloading in development mode.
  unloadable

  # Validations for the ServicePackage model
  # Name must be present and unique.
  validates :name, presence: true, uniqueness: true
  # Post count must be present and be an integer greater than or equal to 0.
  validates :post_count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  # Description is optional.

  # No direct associations with Project model defined here, as the link is managed via Custom Fields.
end 
