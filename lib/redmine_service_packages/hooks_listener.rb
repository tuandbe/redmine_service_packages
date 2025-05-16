# frozen_string_literal: true

module RedmineServicePackages
  class HooksListener < Redmine::Hook::ViewListener
    # Adds JavaScript to make the 'Post Count' custom field readonly on the project settings page.
    def view_projects_form(context = {})
      project = context[:project]
      # context[:controller] gives access to the controller instance
      # context[:form] gives access to the form builder instance

      # Only apply on existing projects, or if project object exists
      # On new project page, the field should also be readonly if it appears.
      # We need to ensure custom fields are present.
      return '' unless context[:project] && context[:project].custom_field_values.any?

      settings = Setting.plugin_redmine_service_packages
      posts_cf_id = settings['service_package_posts_cf_id'].to_i
      return '' if posts_cf_id == 0 # Custom field not configured

      # Using I18n.t within the script string generation
      # Ensure that the translation keys exist
      tooltip_message = I18n.t('text_posts_cf_readonly_message', default: 'This field is automatically updated by the Service Package selection.')
      
      # Escape the tooltip message for JavaScript context
      escaped_tooltip_message = ERB::Util.json_escape(tooltip_message)

      script_content = <<~JAVASCRIPT
        $(document).ready(function() {
          var postsCfId = #{posts_cf_id};
          var postsCfInputId = 'project_custom_field_values_' + postsCfId;
          console.log('RSP_HOOK: Document ready. Looking for CF ID: ' + postsCfId + ', Input ID: ' + postsCfInputId);
          var $inputField = $('#' + postsCfInputId);

          if ($inputField.length) {
            console.log('RSP_HOOK: Found input field:', $inputField.get(0)); // Log the DOM element itself
            $inputField.prop('readonly', true);
            $inputField.attr('title', "#{escaped_tooltip_message}"); // Ensure quotes are correct here
            console.log('RSP_HOOK: Set field to readonly. Current readonly prop: ', $inputField.prop('readonly'));
            // Optional: Add some visual indication that it's readonly
            // $inputField.css('background-color', '#eeeeee'); 
          } else {
            console.error('RSP_HOOK: Input field NOT found with ID: ' + postsCfInputId);
            // You can add more debug here, like listing all input IDs on the page
            // console.log('RSP_HOOK: Available input IDs:', $('input[id]').map(function() { return this.id; }).get());
          }
        });
      JAVASCRIPT

      return context[:controller].view_context.javascript_tag(script_content)
    end
  end
end 
