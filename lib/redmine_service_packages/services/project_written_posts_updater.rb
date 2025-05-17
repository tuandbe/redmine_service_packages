module RedmineServicePackages
  module Services
    class ProjectWrittenPostsUpdater
      # WRITTEN_POST_TRACKER_NAME = "Viết bài".freeze # Now configurable via counting_tracker_id setting

      def self.update_for_project(project)
        return unless project.is_a?(Project)

        # Part 1: Update "Số bài đã viết" (Written Posts Count)
        counting_tracker_id = Setting.plugin_redmine_service_packages['counting_tracker_id']
        tracker = Tracker.find_by(id: counting_tracker_id) if counting_tracker_id.present?
        
        written_posts_cf_id = Setting.plugin_redmine_service_packages['written_posts_cf_id']
        unless written_posts_cf_id.present?
          Rails.logger.info "[RSP] 'Written Posts Count CF ID' not configured. Cannot calculate written posts or progress for project ##{project.id}."
          return 
        end

        written_posts_custom_field = ProjectCustomField.find_by(id: written_posts_cf_id)
        unless written_posts_custom_field
          Rails.logger.warn "[RSP] ProjectCustomField for 'Written Posts' (ID #{written_posts_cf_id}) not found. Cannot update project ##{project.id}."
          return 
        end

        written_posts_count = 0
        if counting_tracker_id.present? && tracker
          written_posts_count = project.issues.where(tracker_id: tracker.id).count
          
          wp_cv = project.custom_value_for(written_posts_custom_field)
          if wp_cv.nil?
            if written_posts_custom_field.is_for_all? || (written_posts_custom_field.respond_to?(:project_ids) && written_posts_custom_field.project_ids.include?(project.id))
              wp_cv = CustomValue.new(custom_field: written_posts_custom_field, customized: project)
            else
              Rails.logger.warn "[RSP] Written Posts CF '#{written_posts_custom_field.name}' (ID: #{written_posts_cf_id}) not configured for project ##{project.id}. Update for this CF skipped."
              # wp_cv remains nil, will use existing value for written_posts_count if possible, or 0
            end
          end

          if wp_cv && wp_cv.value.to_s != written_posts_count.to_s
            wp_cv.value = written_posts_count
            if wp_cv.save
              Rails.logger.info "[RSP] Updated '#{written_posts_custom_field.name}' (Tracker: '#{tracker.name}') for project ##{project.id} to #{written_posts_count}."
            else
              Rails.logger.error "[RSP] Failed to save '#{written_posts_custom_field.name}' for project ##{project.id}: #{wp_cv.errors.full_messages.join(', ')}."
            end
          end
        else # Tracker for counting not configured or not found
          if !counting_tracker_id.present?
            Rails.logger.info "[RSP] 'Tracker for Counting Issues ID' not configured. Attempting to use existing written posts count for project ##{project.id}."
          elsif !tracker # counting_tracker_id was present but tracker not found
             Rails.logger.warn "[RSP] Tracker with ID #{counting_tracker_id} not found. Attempting to use existing written posts count for project ##{project.id}."
          end
          existing_wp_cv = project.custom_value_for(written_posts_custom_field)
          written_posts_count = existing_wp_cv&.value.to_i if existing_wp_cv
        end

        # Part 2: Update "Tiến độ" (Progress Status)
        progress_status_cf_id = Setting.plugin_redmine_service_packages['progress_status_cf_id']
        service_package_posts_cf_id = Setting.plugin_redmine_service_packages['service_package_posts_cf_id']

        unless progress_status_cf_id.present? && service_package_posts_cf_id.present?
          missing_cfs = []
          missing_cfs << "'Progress Status CF ID'" unless progress_status_cf_id.present?
          missing_cfs << "'Service Package Posts CF ID'" unless service_package_posts_cf_id.present?
          Rails.logger.info "[RSP] Required CF IDs (#{missing_cfs.join(' and ')}) for progress update not configured. Skipping progress update for project ##{project.id}."
          return
        end

        progress_custom_field = ProjectCustomField.find_by(id: progress_status_cf_id)
        total_posts_custom_field = ProjectCustomField.find_by(id: service_package_posts_cf_id)

        unless progress_custom_field && total_posts_custom_field
          not_found_cfs = []
          not_found_cfs << "Progress Status CF (ID: #{progress_status_cf_id})" unless progress_custom_field
          not_found_cfs << "Service Package Posts CF (ID: #{service_package_posts_cf_id})" unless total_posts_custom_field
          Rails.logger.warn "[RSP] #{not_found_cfs.join(' or ')} not found. Cannot update progress for project ##{project.id}."
          return
        end
        
        unless progress_custom_field.field_format == 'list'
            Rails.logger.warn "[RSP] Progress Status CF '#{progress_custom_field.name}' (ID: #{progress_custom_field.id}) is not of type 'list'. Cannot update progress. Project ##{project.id}."
            return
        end

        total_posts_cv = project.custom_value_for(total_posts_custom_field)
        total_posts = total_posts_cv&.value.to_i # Defaults to 0 if nil or not an int

        difference = total_posts - written_posts_count
        progress_string_value = case
                                when difference < 0
                                  "Quá hạn mức"
                                when difference == 0
                                  "Hoàn thành"
                                when difference == 1 || difference == 2
                                  "Sắp đủ bài"
                                when difference > 2
                                  "Đang chạy"
                                else
                                  nil 
                                end
        
        unless progress_string_value
          Rails.logger.warn "[RSP] Could not determine progress string value for project ##{project.id} (Total: #{total_posts}, Written: #{written_posts_count}). Logic might need adjustment or data is unexpected."
          return
        end

        possible_values = progress_custom_field.possible_values_options
        actual_possible_strings = possible_values.is_a?(Array) ? possible_values.map { |pv| pv.is_a?(Array) ? pv.first : pv.to_s } : []

        unless actual_possible_strings.include?(progress_string_value)
          Rails.logger.warn "[RSP] Determined progress string '#{progress_string_value}' is not a valid possible value for CF '#{progress_custom_field.name}'. Possible: #{actual_possible_strings.join(' | ')}. Project ##{project.id}."
          return
        end

        progress_cv = project.custom_value_for(progress_custom_field)
        if progress_cv.nil?
          if progress_custom_field.is_for_all? || (progress_custom_field.respond_to?(:project_ids) && progress_custom_field.project_ids.include?(project.id))
            progress_cv = CustomValue.new(custom_field: progress_custom_field, customized: project)
          else
            Rails.logger.warn "[RSP] Progress CF '#{progress_custom_field.name}' (ID: #{progress_custom_field.id}) not configured for project ##{project.id}. Cannot update progress."
            return
          end
        end

        if progress_cv.value.to_s != progress_string_value
          progress_cv.value = progress_string_value # Store the string value directly
          if progress_cv.save
            Rails.logger.info "[RSP] Updated '#{progress_custom_field.name}' for project ##{project.id} to '#{progress_string_value}'."
          else
            Rails.logger.error "[RSP] Failed to save '#{progress_custom_field.name}' for project ##{project.id}: #{progress_cv.errors.full_messages.join(', ')}."
          end
        end

      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error "[RSP] Error during update (RecordNotFound): #{e.message} for project ##{project&.id}"
      rescue StandardError => e
        Rails.logger.error "[RSP] Unexpected error in update_for_project for project ##{project&.id}: #{e.message}\n#{e.backtrace.join("\n")}"
      end
    end
  end
end 
