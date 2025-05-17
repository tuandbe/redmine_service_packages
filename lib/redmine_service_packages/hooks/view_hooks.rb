module RedmineServicePackages
  module Hooks
    class ViewHooks < Redmine::Hook::ViewListener
      # Adds custom CSS to the HTML head
      def view_layouts_base_html_head(context = {})
        stylesheet_link_tag('rsp_progress_colors.css', plugin: 'redmine_service_packages')
      end

      # Adds custom JavaScript to the bottom of the body
      def view_layouts_base_body_bottom(context = {})
        javascript_include_tag('rsp_progress_colors.js', plugin: 'redmine_service_packages')
      end
    end
  end
end 
