module RedmineServicePackages
  module Services
    class ProjectWrittenPostsUpdater
      # WRITTEN_POST_TRACKER_NAME = "Viết bài".freeze # Now configurable via counting_tracker_id setting

      def self.update_for_project(project)
        return unless project.is_a?(Project)

        counting_tracker_id = Setting.plugin_redmine_service_packages['counting_tracker_id']
        unless counting_tracker_id.present?
          Rails.logger.info "[RedmineServicePackages] 'Tracker for Counting Issues ID' is not configured in plugin settings. Skipping update for project ##{project.id}."
          return
        end

        tracker = Tracker.find_by(id: counting_tracker_id)
        unless tracker
          Rails.logger.warn "[RedmineServicePackages] Tracker with ID #{counting_tracker_id} (for 'Counting Issues') not found. Cannot update written posts count for project ##{project.id}."
          return
        end

        written_posts_cf_id = Setting.plugin_redmine_service_packages['written_posts_cf_id']
        unless written_posts_cf_id.present?
          Rails.logger.info "[RedmineServicePackages] 'Written Posts Count Custom Field ID' is not configured in plugin settings. Skipping update for project ##{project.id}."
          return
        end

        custom_field = ProjectCustomField.find_by(id: written_posts_cf_id)
        unless custom_field
          Rails.logger.warn "[RedmineServicePackages] ProjectCustomField with ID #{written_posts_cf_id} (for 'Written Posts Count') not found. Cannot update for project ##{project.id}."
          return
        end

        count = project.issues.where(tracker_id: tracker.id).count # Use tracker.id from settings
        custom_value = project.custom_value_for(custom_field)
        
        if custom_value.nil?
          if custom_field.is_for_all? || (custom_field.respond_to?(:project_ids) && custom_field.project_ids.include?(project.id))
            Rails.logger.info "[RedmineServicePackages] CustomValue for CF '#{custom_field.name}' on project ##{project.id} is nil and CF is applicable. Building a new one."
            custom_value = CustomValue.new(custom_field: custom_field, customized: project)
          else
            Rails.logger.warn "[RedmineServicePackages] CustomField '#{custom_field.name}' (ID: #{custom_field.id}) is not configured for project '#{project.name}' (ID: #{project.id}). Cannot create/update value."
            return
          end
        end
        
        if custom_value.value.to_s != count.to_s
          custom_value.value = count
          if custom_value.save
            Rails.logger.info "[RedmineServicePackages] Updated '#{custom_field.name}' (counting Tracker '#{tracker.name}') for project ##{project.id} to #{count}."
          else
            Rails.logger.error "[RedmineServicePackages] Failed to save CustomValue for project ##{project.id}, CF '#{custom_field.name}': #{custom_value.errors.full_messages.join(', ')}. Value was: #{custom_value.value.inspect}"
          end
        else
           Rails.logger.info "[RedmineServicePackages] Value for '#{custom_field.name}' (counting Tracker '#{tracker.name}') on project ##{project.id} is already #{count}. No update needed."
        end
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error "[RedmineServicePackages] Error during update_for_project (RecordNotFound): #{e.message} for project ##{project&.id}"
      rescue StandardError => e
        Rails.logger.error "[RedmineServicePackages] Unexpected error in update_for_project for project ##{project&.id}: #{e.message}\n#{e.backtrace.join("\n")}"
      end
    end
  end
end 
