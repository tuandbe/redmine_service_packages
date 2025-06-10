# frozen_string_literal: true

# This file defines the cron jobs for the redmine_service_packages plugin.
# It uses the 'whenever' gem syntax.
# Learn more: http://github.com/javan/whenever

# Set the environment to the one Redmine is running in.
# This is crucial for the rake task to load the Redmine environment correctly.
set :environment, ENV['RAILS_ENV'] || 'development'

# Define the path for the cron job's output log file.
# It's placed in the main Redmine log directory for centralized logging.
# File.expand_path generates an absolute path from a relative one.
# __dir__ is the directory of the current file (plugins/redmine_service_packages/config)
set :output, File.expand_path("../../../log/cron_service_packages.log", __dir__)

# Define the schedule.
# The job will run every day at 1:00 AM.
every 1.day, at: '1:00 am' do
  # This executes the rake task we created earlier.
  # 'rake' is a command provided by the 'whenever' gem.
  rake "redmine_service_packages:update_all_projects_status"
end 
