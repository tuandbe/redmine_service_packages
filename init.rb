# frozen_string_literal: true

# Standard Rails logger
logger = Rails.logger

Redmine::Plugin.register :redmine_service_packages do
  name 'Redmine Service Packages'
  author 'tuandbe'
  description 'Manage service packages for projects and sync post counts to a custom field.'
  version '0.2.0'
  url 'https://github.com/tuandbe/redmine_service_packages'
  author_url 'https://github.com/tuandbe'

  requires_redmine version_or_higher: '5.0.0'

  settings default: {
    'service_package_name_cf_id' => nil,
    'service_package_posts_cf_id' => nil
  }, partial: 'settings/redmine_service_packages_settings'

  project_module :service_packages_module do
    permission :manage_service_packages, { service_packages: [:index, :new, :create, :edit, :update, :destroy, :show] }, require: :admin
    # Add other permissions for the project module if needed later
  end

  menu :admin_menu, :service_packages,
       { controller: 'service_packages', action: 'index' },
       caption: :label_service_packages,
       html: { class: 'icon icon-package' }

  # Load hooks
  # require_dependency 'redmine_service_packages/hooks_listener' # Old relative path
  hooks_listener_file_absolute_path = File.join(File.dirname(__FILE__), 'lib', 'redmine_service_packages', 'hooks_listener.rb')
  require_dependency hooks_listener_file_absolute_path

  begin
    patch_module_fqn = 'RedmineServicePackages::Patches::ProjectPatch'
    patch_file_absolute_path = File.join(File.dirname(__FILE__), 'lib', 'redmine_service_packages', 'patches', 'project_patch.rb')

    require_dependency patch_file_absolute_path
    patch_module = patch_module_fqn.constantize
    target_class = Project

    unless target_class.included_modules.include?(patch_module)
      target_class.send(:include, patch_module)
    end

  rescue LoadError => e
    logger.error "RedmineServicePackages: Error loading ProjectPatch. Message: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n")}"
  rescue NameError => e
    logger.error "RedmineServicePackages: Error finding Project or ProjectPatch module. Message: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n")}"
  rescue StandardError => e
    logger.error "RedmineServicePackages: Error applying ProjectPatch. Message: #{e.message}\nBacktrace:\n#{e.backtrace.join("\n")}"
  end
end
