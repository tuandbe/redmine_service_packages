# frozen_string_literal: true

namespace :redmine_service_packages do
  desc "Updates the written posts count and progress status for all active projects."
  task update_all_projects_status: :environment do
    puts "Starting daily project status update for Redmine Service Packages plugin..."
    
    projects_to_update = Project.active
    
    if projects_to_update.empty?
      puts "No active projects found to update."
    else
      puts "Found #{projects_to_update.count} active project(s) to process."
      
      projects_to_update.find_each do |project|
        begin
          puts "Processing project: '#{project.name}' (ID: #{project.id})"
          RedmineServicePackages::Services::ProjectWrittenPostsUpdater.update_for_project(project)
        rescue => e
          # Log the error to both console and Rails logger for better tracking
          error_message = "Error updating project '#{project.name}' (ID: #{project.id}): #{e.message}"
          puts error_message
          Rails.logger.error "[RSP Rake Task] #{error_message}"
        end
      end
    end
    
    puts "Daily project status update finished."
  end
end 
