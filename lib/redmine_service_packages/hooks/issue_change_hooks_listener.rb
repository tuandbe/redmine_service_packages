module RedmineServicePackages
  module Hooks
    class IssueChangeHooksListener < Redmine::Hook::ViewListener
      # Called after a new issue is saved
      def controller_issues_new_after_save(context = {})
        Rails.logger.info "[RedmineServicePackages] Hook controller_issues_new_after_save called."
        issue = context[:issue]
        
        unless issue
          Rails.logger.warn "[RedmineServicePackages] Issue not found in context for controller_issues_new_after_save."
          return
        end
        
        unless issue.project
          Rails.logger.warn "[RedmineServicePackages] Project not found for issue ##{issue.id} in controller_issues_new_after_save."
          return
        end
        
        Rails.logger.info "[RedmineServicePackages] Calling ProjectWrittenPostsUpdater for project ##{issue.project.id} from new_after_save for issue ##{issue.id}."
        RedmineServicePackages::Services::ProjectWrittenPostsUpdater.update_for_project(issue.project)
      end

      # Called after an existing issue is updated
      def controller_issues_edit_after_save(context = {})
        Rails.logger.info "[RedmineServicePackages] Hook controller_issues_edit_after_save called."
        issue = context[:issue]
        journal = context[:journal] # journal can be nil if only attachments are changed, for example.
        
        unless issue
          Rails.logger.warn "[RedmineServicePackages] Issue not found in context for controller_issues_edit_after_save."
          return
        end

        unless issue.project
          Rails.logger.warn "[RedmineServicePackages] Project not found for issue ##{issue.id} in controller_issues_edit_after_save."
          return
        end
        
        Rails.logger.info "[RedmineServicePackages] Calling ProjectWrittenPostsUpdater for project ##{issue.project.id} from edit_after_save for issue ##{issue.id}."
        RedmineServicePackages::Services::ProjectWrittenPostsUpdater.update_for_project(issue.project)

        # If the issue was moved from another project, update the old project's count as well
        if journal
          project_id_detail = journal.details.find { |d| d.prop_key == 'project_id' && d.old_value.present? }
          if project_id_detail
            old_project = Project.find_by(id: project_id_detail.old_value)
            if old_project
              Rails.logger.info "[RedmineServicePackages] Issue ##{issue.id} moved from project ##{old_project.id}. Updating old project."
              RedmineServicePackages::Services::ProjectWrittenPostsUpdater.update_for_project(old_project)
            else
              Rails.logger.warn "[RedmineServicePackages] Old project with ID #{project_id_detail.old_value} not found for issue ##{issue.id} move."
            end
          end
        end
      end
    end
  end
end 
