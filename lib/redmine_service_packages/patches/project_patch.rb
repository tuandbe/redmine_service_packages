# frozen_string_literal: true

Rails.logger.info "RSP_PROJECT_PATCH_LOADING: Attempting to load ProjectPatch file..."

module RedmineServicePackages
  Rails.logger.info "RedmineServicePackages: ProjectPatchFile: START of project_patch.rb"

  module Patches
    Rails.logger.info "RedmineServicePackages: ProjectPatchFile: Defining module Patches"
    # Patch for the Project model to update service package post counts.
    module ProjectPatch
      Rails.logger.info "RedmineServicePackages: ProjectPatchFile: Defining module ProjectPatch"
      extend ActiveSupport::Concern

      included do
        Rails.logger.info "RSP_PROJECT_PATCH_INCLUDED: ProjectPatch included in Project model. Setting up after_save callback."
        after_save :update_post_count_cf_from_service_package
      end

      # Module ClassMethods can be defined here if needed in the future
      # module ClassMethods
      # end

      # Instance methods
      def update_post_count_cf_from_service_package
        settings = Setting.plugin_redmine_service_packages
        name_cf_id = settings['service_package_name_cf_id'].to_i
        posts_cf_id = settings['service_package_posts_cf_id'].to_i

        if name_cf_id == 0 || posts_cf_id == 0
          # Rails.logger.warn "RedmineServicePackages: ProjectPatch: Custom field IDs are not configured in plugin settings. Aborting update for project ##{id}."
          return
        end

        service_package_name_cv = self.custom_values.find_by(custom_field_id: name_cf_id)

        if service_package_name_cv.nil? || service_package_name_cv.value.blank?
          # Rails.logger.info "RedmineServicePackages: ProjectPatch: Service Package Name CF is blank for project ##{id}. Clearing Posts CF."
          posts_custom_value = self.custom_values.find_or_initialize_by(custom_field_id: posts_cf_id)
          unless posts_custom_value.value.blank?
            posts_custom_value.value = nil
            unless posts_custom_value.save
              Rails.logger.error "RedmineServicePackages: ProjectPatch: Failed to clear Posts CF for project ##{id}. Errors: #{posts_custom_value.errors.full_messages.join(', ')}"
            end
          end
          return
        end

        selected_package_name = service_package_name_cv.value
        service_package = ServicePackage.find_by(name: selected_package_name)

        if service_package
          posts_custom_value = self.custom_values.find_or_initialize_by(custom_field_id: posts_cf_id)
          new_post_count_value = service_package.post_count.to_s

          if posts_custom_value.value != new_post_count_value
            posts_custom_value.value = new_post_count_value
            unless posts_custom_value.save
              Rails.logger.error "RedmineServicePackages: ProjectPatch: Failed to save Posts CF for project ##{id}. Name CF: #{name_cf_id}, Posts CF: #{posts_cf_id}, Package: #{selected_package_name}. Errors: #{posts_custom_value.errors.full_messages.join(', ')}"
            end
          end
        else
          # Rails.logger.warn "RedmineServicePackages: ProjectPatch: ServicePackage '#{selected_package_name}' not found for project ##{id}. Clearing Posts CF."
          posts_custom_value = self.custom_values.find_or_initialize_by(custom_field_id: posts_cf_id)
          unless posts_custom_value.value.blank?
            posts_custom_value.value = nil
            unless posts_custom_value.save
              Rails.logger.error "RedmineServicePackages: ProjectPatch: Failed to clear Posts CF (package not found) for project ##{id}. Errors: #{posts_custom_value.errors.full_messages.join(', ')}"
            end
          end
        end
      rescue StandardError => e
        Rails.logger.error "RedmineServicePackages: ProjectPatch: ERROR in update_post_count_cf_from_service_package for project ##{id}: #{e.message}"
        Rails.logger.error "RedmineServicePackages: ProjectPatch: Backtrace: \n#{e.backtrace.join("\n")}"
      end
      Rails.logger.info "RedmineServicePackages: ProjectPatchFile: END of module ProjectPatch"
    end
    Rails.logger.info "RedmineServicePackages: ProjectPatchFile: END of module Patches"
  end
  Rails.logger.info "RedmineServicePackages: ProjectPatchFile: END of module RedmineServicePackages"
end
Rails.logger.info "RedmineServicePackages: ProjectPatchFile: END of project_patch.rb" 
