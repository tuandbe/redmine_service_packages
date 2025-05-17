module RedmineServicePackages
  module Patches
    module IssuePatch
      extend ActiveSupport::Concern

      included do
        # This block is executed when the module is included in the Issue class
        after_destroy :rsp_update_project_written_posts_count_after_destroy
      end

      private

      def rsp_update_project_written_posts_count_after_destroy
        # self refers to the issue instance being destroyed
        if self.project
          RedmineServicePackages::Services::ProjectWrittenPostsUpdater.update_for_project(self.project)
        end
      rescue StandardError => e
        Rails.logger.error "[RedmineServicePackages] Error in IssuePatch after_destroy for issue ##{self.id}: #{e.message}\n#{e.backtrace.join("\n")}"
      end
    end
  end
end 
