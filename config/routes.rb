# frozen_string_literal: true

# Defines the routes for the service_packages resource.
# This will create standard RESTful routes for ServicePackagesController.
# We exclude the :show action as it might not be needed for basic management.
Rails.application.routes.draw do
  resources :service_packages, except: [:show]
end 
