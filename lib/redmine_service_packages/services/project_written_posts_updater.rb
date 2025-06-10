# frozen_string_literal: true

module RedmineServicePackages
  module Services
    # Service object to update project custom fields related to service packages.
    # This includes:
    # 1. Counting "Written Posts" based on a configured tracker.
    # 2. Determining if a post is needed today based on frequency.
    # 3. Calculating and updating the project's progress status.
    class ProjectWrittenPostsUpdater
      DEFAULT_PROGRESS_RULES = [
        "lt(0):Quá hạn mức",
        "eq(0):Hoàn thành",
        "between(1,2):Sắp đủ bài",
        "gt(2):Đang chạy"
      ].join("\n")

      # Main entry point. Orchestrates the updates for a given project.
      # @param project [Project] The project to update.
      def self.update_for_project(project)
          return unless project.is_a?(Project)

        settings = load_plugin_settings
        written_posts_count, latest_social_plan_issue = calculate_written_posts(project, settings)

        # Update "Written Posts Count" custom field
        update_custom_value(project, settings[:written_posts_cf_id], written_posts_count, 'Written Posts Count')

        # Update "Needs Posting Today" status if a social plan exists
        update_needs_posting_today_status(project, latest_social_plan_issue, settings) if latest_social_plan_issue

        # Update "Progress Status" custom field
        update_progress_status(project, written_posts_count, settings)

      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error "[RSP] Error during update (RecordNotFound) for project ##{project&.id}: #{e.message}"
      rescue StandardError => e
        Rails.logger.error "[RSP] Unexpected error in update_for_project for project ##{project&.id}: #{e.message}\n#{e.backtrace.join("\n")}"
      end

      # Class is designed to be used via class methods only
      class << self
        private

        # Loads all required plugin settings into a hash for easy access.
        # @return [Hash] A hash of setting keys and their values.
        def load_plugin_settings
          plugin_settings = Setting.plugin_redmine_service_packages
          {
            counting_tracker_id:           plugin_settings['counting_tracker_id'].to_i,
            written_posts_cf_id:           plugin_settings['written_posts_cf_id'].to_i,
            social_plan_tracker_id:        plugin_settings['social_plan_tracker_id'].to_i,
            posting_frequency_cf_id:       plugin_settings['posting_frequency_cf_id'].to_i,
            needs_posting_today_cf_id:     plugin_settings['needs_posting_today_cf_id'].to_i,
            posting_date_cf_id:            plugin_settings['posting_date_cf_id'].to_i,
            progress_status_cf_id:         plugin_settings['progress_status_cf_id'].to_i,
            service_package_posts_cf_id:   plugin_settings['service_package_posts_cf_id'].to_i,
            progress_calculation_rules:    plugin_settings['progress_calculation_rules'].presence || DEFAULT_PROGRESS_RULES
          }
        end

        # Part 1: Calculates the number of "written posts".
        # A "written post" is an issue with a specific tracker, which is a child
        # of the latest "Social Plan" issue in the project.
        # @param project [Project]
        # @param settings [Hash]
        # @return [Array<Integer, Issue|nil>] The count of written posts and the latest social plan issue.
        def calculate_written_posts(project, settings)
          return [0, nil] unless settings[:counting_tracker_id].positive? && settings[:social_plan_tracker_id].positive?

          latest_social_plan_issue = project.issues
                                            .where(tracker_id: settings[:social_plan_tracker_id])
                                            .order(start_date: :desc)
                                            .first

          return [0, nil] unless latest_social_plan_issue

          count = Issue.where(parent_id: latest_social_plan_issue.id, tracker_id: settings[:counting_tracker_id]).count
          [count, latest_social_plan_issue]
        end

        # Part 2: Updates the "Hôm nay cần đăng bài" (Needs Posting Today) project custom field.
        # This logic determines if a new post is required today based on a configured frequency
        # and the date of the last actual post.
        # @param project [Project]
        # @param latest_social_plan_issue [Issue] The project's current social plan issue.
        # @param settings [Hash]
        def update_needs_posting_today_status(project, latest_social_plan_issue, settings)
          required_cf_ids = [settings[:posting_frequency_cf_id], settings[:needs_posting_today_cf_id], settings[:posting_date_cf_id]]
          return unless required_cf_ids.all?(&:positive?)

          needs_posting_today = determine_if_posting_is_needed(project, latest_social_plan_issue, settings)
          value_to_save = needs_posting_today ? '1' : '0'

          update_custom_value(project, settings[:needs_posting_today_cf_id], value_to_save, 'Needs Posting Today', field_type: 'bool')
        rescue StandardError => e
          Rails.logger.error "[RSP] Project ##{project.id}: Error in update_needs_posting_today_status: #{e.message}\n#{e.backtrace.join("\n")}"
        end

        # Contains the core logic for deciding if a post is needed today.
        # @param project [Project]
        # @param latest_social_plan_issue [Issue]
        # @param settings [Hash]
        # @return [Boolean] True if a post is needed, false otherwise.
        def determine_if_posting_is_needed(project, latest_social_plan_issue, settings)
          frequency_cv = latest_social_plan_issue.custom_value_for(settings[:posting_frequency_cf_id])
          frequency = frequency_cv&.value.to_i
          return false unless frequency > 0

          latest_post_date = find_latest_post_date(project, settings[:counting_tracker_id], settings[:posting_date_cf_id])
          return true if latest_post_date.nil?

          today = Date.today
          return false if today == latest_post_date

          if today > latest_post_date
            days_diff = (today - latest_post_date).to_i
            return days_diff > frequency || (days_diff % frequency).zero?
          end

          false # Reached if latest_post_date is in the future
        end

        # Finds the date of the most recent post that has a value in the "Ngày đăng" (Posting Date) custom field.
        # @param project [Project]
        # @param tracker_id [Integer] The tracker ID for posts to consider.
        # @param posting_date_cf_id [Integer] The custom field ID for the posting date.
        # @return [Date|nil] The date of the last post, or nil if none found.
        def find_latest_post_date(project, tracker_id, posting_date_cf_id)
                      latest_post_cv = CustomValue
                        .joins("INNER JOIN issues ON issues.id = custom_values.customized_id AND custom_values.customized_type = 'Issue'")
                           .where(issues: { project_id: project.id, tracker_id: tracker_id })
                        .where(custom_field_id: posting_date_cf_id)
                        .where.not(value: [nil, ''])
                        .order(Arel.sql("CAST(value AS date) DESC"))
                        .first

          return nil unless latest_post_cv&.value

          Date.parse(latest_post_cv.value)
                        rescue Date::Error
                          Rails.logger.warn "[RSP] Project ##{project.id}: Invalid date format in 'Ngày đăng' CF (ID: #{posting_date_cf_id}) for CV ##{latest_post_cv.id}. Value: '#{latest_post_cv.value}'"
          nil
        end

        # Part 3: Updates the "Tiến độ" (Progress Status) project custom field.
        # This calculates progress based on total posts vs. written posts and applies configured rules.
        # @param project [Project]
        # @param written_posts_count [Integer]
        # @param settings [Hash]
        def update_progress_status(project, written_posts_count, settings)
          return unless settings[:progress_status_cf_id].positive? && settings[:service_package_posts_cf_id].positive?

          total_posts_cv = project.custom_value_for(settings[:service_package_posts_cf_id])
          total_posts = total_posts_cv&.value.to_i

          difference = total_posts - written_posts_count
          
          progress_string_value = apply_progress_rules(difference, settings[:progress_calculation_rules], project)
          return unless progress_string_value

          update_custom_value(project, settings[:progress_status_cf_id], progress_string_value, 'Progress Status', field_type: 'list')
        end

        # Generic helper to find and update a custom value for a given object (e.g., Project).
        # It handles finding/creating the CustomValue, checking for changes, and saving.
        # @param customizable [ActiveRecord::Base] The object to update (e.g., a Project instance).
        # @param cf_id [Integer] The ID of the CustomField to update.
        # @param new_value [String, Integer] The new value to set.
        # @param cf_name_for_logs [String] A descriptive name for logging purposes.
        # @param field_type [String, nil] Optional: enforces a check for the field format (e.g., 'bool', 'list').
        def update_custom_value(customizable, cf_id, new_value, cf_name_for_logs, field_type: nil)
          return unless cf_id.positive?

          custom_field = ProjectCustomField.find_by(id: cf_id)
          unless custom_field
            Rails.logger.warn "[RSP] Project ##{customizable.id}: #{cf_name_for_logs} CF with ID #{cf_id} not found."
            return
          end

          if field_type && custom_field.field_format != field_type
            Rails.logger.warn "[RSP] Project ##{customizable.id}: #{cf_name_for_logs} CF is not a '#{field_type}' type."
            return
          end

          if field_type == 'list' && !custom_field.possible_values_options.include?(new_value.to_s)
            Rails.logger.warn "[RSP] Determined progress string '#{new_value}' not valid for CF '#{custom_field.name}'. Project ##{customizable.id}."
            Rails.logger.warn "[RSP] Available values: #{custom_field.possible_values_options.inspect}"
            return
          end

          cv = customizable.custom_value_for(custom_field)
          if cv.nil?
            # If the custom field is not applicable to this project, custom_value_for returns nil.
            # We try to create a new CustomValue only if the field is configured for all projects
            # or if it's specifically configured for this project.
            unless custom_field.is_for_all?
              Rails.logger.warn "[RSP] Project ##{customizable.id}: #{cf_name_for_logs} CF '#{custom_field.name}' is not configured for this project."
              return
            end

            cv = CustomValue.new(custom_field: custom_field, customized: customizable)
          end

          new_value_str = new_value.to_s
          return if cv.value.to_s == new_value_str # No change needed

          cv.value = new_value_str
          if cv.save
            Rails.logger.info "[RSP] Project ##{customizable.id}: Updated '#{custom_field.name}' to '#{new_value_str}'."
            else
            Rails.logger.error "[RSP] Project ##{customizable.id}: Failed to save '#{custom_field.name}'. Errors: #{cv.errors.full_messages.join(', ')}."
            end
          end

        # Applies the configured rules to determine the progress status string.
        # (This method handles the original format with lt(), eq(), between(), gt() functions)
        # @param difference [Integer] The difference between total posts and written posts.
        # @param rules_string [String] The rule configuration.
        # @param project [Project]
        # @return [String|nil] The calculated progress status string.
        def apply_progress_rules(difference, rules_string, project)
          rules_string.each_line do |line|
            line.strip!
            next if line.blank? || line.start_with?('#')

            condition_part, outcome_string = line.split(':', 2)
            next unless condition_part && outcome_string
            
            condition_part.strip!
            outcome_string.strip!

            matched = false
            case condition_part
            when /\Aeq\((-?\d+)\)\z/
              matched = difference == $1.to_i
            when /\Alt\((-?\d+)\)\z/
              matched = difference < $1.to_i
            when /\Agt\((-?\d+)\)\z/
              matched = difference > $1.to_i
            when /\Abetween\((-?\d+),(-?\d+)\)\z/
              num1 = $1.to_i
              num2 = $2.to_i
              matched = difference >= [num1, num2].min && difference <= [num1, num2].max
            else
              Rails.logger.warn "[RSP] Invalid rule condition format: '#{condition_part}' for project ##{project.id}. Rule skipped."
              next 
            end

            return outcome_string if matched
          end
          nil
        end
      end
    end
  end
end 
