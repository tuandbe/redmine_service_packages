# frozen_string_literal: true

# Standard Rails logger
logger = Rails.logger

Redmine::Plugin.register :redmine_service_packages do
  name 'Redmine Service Packages'
  author 'tuandbe'
  description 'Manage service packages, sync post counts, count issues from a configurable tracker, and update project progress status based on configurable rules.'
  version '0.2.5'
  url 'https://github.com/tuandbe/redmine_service_packages'
  author_url 'https://github.com/tuandbe'

  requires_redmine version_or_higher: '5.0.0'

  settings default: {
    'service_package_name_cf_id' => nil,
    'service_package_posts_cf_id' => nil,
    'written_posts_cf_id' => nil,
    'counting_tracker_id' => nil,
    'progress_status_cf_id' => nil,
    'progress_calculation_rules' => "lt(0):Quá hạn mức\neq(0):Hoàn thành\nbetween(1,2):Sắp đủ bài\ngt(2):Đang chạy"
  }, partial: 'settings/redmine_service_packages_settings'

  project_module :service_packages_module do
    permission :manage_service_packages, { service_packages: [:index, :new, :create, :edit, :update, :destroy, :show] }, require: :admin
    # Add other permissions for the project module if needed later
  end

  menu :admin_menu, :service_packages,
       { controller: 'service_packages', action: 'index' },
       caption: :label_service_packages,
       html: { class: 'icon icon-package' }

  # Ensure the service class is available. Rails autoloading from lib/ should handle this,
  # but explicit require_dependency is safer during plugin initialization.
  begin
    project_written_posts_updater_file = File.join(File.dirname(__FILE__), 'lib', 'redmine_service_packages', 'services', 'project_written_posts_updater.rb')
    require_dependency project_written_posts_updater_file
  rescue LoadError => e
    logger.error "RedmineServicePackages: Error loading ProjectWrittenPostsUpdater service. Message: #{e.message}"
  end

  # Load existing hooks_listener (if any specific logic is there)
  begin
    hooks_listener_file_absolute_path = File.join(File.dirname(__FILE__), 'lib', 'redmine_service_packages', 'hooks_listener.rb')
    # Check if file exists before requiring, to avoid error if it was meant to be removed or renamed.
    require_dependency hooks_listener_file_absolute_path if File.exist?(hooks_listener_file_absolute_path)
  rescue LoadError => e
    logger.warn "RedmineServicePackages: Could not load general hooks_listener.rb (might be intentional). Message: #{e.message}"
  end
  
  # Load IssueChangeHooksListener for "Số bài đã viết" feature
  begin
    issue_hooks_listener_file = File.join(File.dirname(__FILE__), 'lib', 'redmine_service_packages', 'hooks', 'issue_change_hooks_listener.rb')
    require_dependency issue_hooks_listener_file
  rescue LoadError => e
    logger.error "RedmineServicePackages: Error loading IssueChangeHooksListener. Message: #{e.message}"
  end

  # Apply ProjectPatch (existing patch)
  begin
    project_patch_fqn = 'RedmineServicePackages::Patches::ProjectPatch'
    project_patch_file = File.join(File.dirname(__FILE__), 'lib', 'redmine_service_packages', 'patches', 'project_patch.rb')

    # Check if file exists before requiring
    if File.exist?(project_patch_file)
      require_dependency project_patch_file
      patch_module = project_patch_fqn.constantize
      target_class = Project

      unless target_class.included_modules.include?(patch_module)
        target_class.send(:include, patch_module)
        logger.info "RedmineServicePackages: Successfully applied ProjectPatch."
      end
    else
      logger.warn "RedmineServicePackages: ProjectPatch file not found at #{project_patch_file}. Skipping patch."
    end
  rescue LoadError => e
    logger.error "RedmineServicePackages: Error loading ProjectPatch. Message: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n")}"
  rescue NameError => e
    logger.error "RedmineServicePackages: Error finding Project or ProjectPatch module. Message: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n")}"
  rescue StandardError => e
    logger.error "RedmineServicePackages: Error applying ProjectPatch. Message: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n")}"
  end

  # Apply IssuePatch for "Số bài đã viết" feature
  begin
    issue_patch_fqn = 'RedmineServicePackages::Patches::IssuePatch'
    issue_patch_file = File.join(File.dirname(__FILE__), 'lib', 'redmine_service_packages', 'patches', 'issue_patch.rb')

    if File.exist?(issue_patch_file) 
      require_dependency issue_patch_file
      patch_module = issue_patch_fqn.constantize
      target_class = Issue # Target class is Issue

      unless target_class.included_modules.include?(patch_module)
        target_class.send(:include, patch_module)
        logger.info "RedmineServicePackages: Successfully applied IssuePatch."
      end
    else
      logger.warn "RedmineServicePackages: IssuePatch file not found at #{issue_patch_file}. Skipping patch."
    end
  rescue LoadError => e
    logger.error "RedmineServicePackages: Error loading IssuePatch. Message: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n")}"
  rescue NameError => e
    logger.error "RedmineServicePackages: Error finding Issue or IssuePatch module for 'Số bài đã viết'. Message: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n")}"
  rescue StandardError => e
    logger.error "RedmineServicePackages: Error applying IssuePatch for 'Số bài đã viết'. Message: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n")}"
  end
end
