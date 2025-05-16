# frozen_string_literal: true

# Controller for managing ServicePackage records.
# This controller is responsible for CRUD operations on service packages.
# It uses the admin layout and requires admin privileges for all actions.
class ServicePackagesController < ApplicationController
  # Use the standard Redmine admin layout for these pages
  layout 'admin'

  # Ensure that only admin users can access these actions
  before_action :require_admin
  # Find the specific service package for edit, update, and destroy actions
  before_action :find_service_package, only: [:edit, :update, :destroy]

  # GET /service_packages
  # Displays a list of all service packages, ordered by name.
  def index
    @service_packages = ServicePackage.order(:name)
  end

  # GET /service_packages/new
  # Initializes a new ServicePackage object for the form.
  def new
    @service_package = ServicePackage.new
  end

  # POST /service_packages
  # Creates a new service package based on submitted parameters.
  def create
    @service_package = ServicePackage.new(service_package_params)
    if @service_package.save
      flash[:notice] = l(:notice_successful_create) # Generic success message
      redirect_to service_packages_path
    else
      # If save fails, re-render the 'new' form to display errors
      render :new
    end
  end

  # GET /service_packages/:id/edit
  # Fetches an existing service package for editing (done by before_action).
  def edit
    # @service_package is already set by the find_service_package before_action
  end

  # PATCH/PUT /service_packages/:id
  # Updates an existing service package based on submitted parameters.
  def update
    # @service_package is already set by the find_service_package before_action
    if @service_package.update(service_package_params)
      flash[:notice] = l(:notice_successful_update) # Generic success message
      redirect_to service_packages_path
    else
      # If update fails, re-render the 'edit' form to display errors
      render :edit
    end
  end

  # DELETE /service_packages/:id
  # Deletes an existing service package.
  def destroy
    # @service_package is already set by the find_service_package before_action
    if @service_package.destroy
      flash[:notice] = l(:notice_successful_delete) # Generic success message
    else
      # If destroy fails (e.g., due to callbacks or database constraints, though unlikely here)
      flash[:error] = l(:error_can_not_delete_service_package) # Custom error message
    end
    redirect_to service_packages_path
  end

  private

  # Finds the ServicePackage record by ID from the params.
  # Renders a 404 error if the record is not found.
  def find_service_package
    @service_package = ServicePackage.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Strong parameters for ServicePackage.
  # Defines which attributes are permitted for mass assignment.
  def service_package_params
    params.require(:service_package).permit(:name, :post_count, :description)
  end
end 
