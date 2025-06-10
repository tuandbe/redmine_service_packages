# Redmine Service Packages Plugin

> [!NOTE]
> **Please Note:** This plugin was custom-developed for a specific media company to meet their operational needs. If you would like to customize it for your own business requirements, please feel free to get in touch:
> *   **Email:** tuan.m4u@gmail.com
> *   **Phone:** (+84) 972 286 455

## 1. Plugin Overview

The Redmine Service Packages plugin extends Redmine's project management capabilities with features for tracking service-level agreements based on post counts. It allows administrators to define "Service Packages," associate them with projects, and automatically track progress against the package's limits.

The plugin introduces core features:
1.  **Service Package Sync**: Assign a "Service Package" (e.g., "Pro 1", "Pro 2") to a project. The package's total allowed "Post Count" is automatically synced to a project custom field.
2.  **Automatic Written Post Counting**: The plugin actively counts the number of issues created under a specific, configurable tracker (e.g., "Blog Post"). This count is stored in a "Written Posts" custom field on the project, providing a real-time view of work completed.
3.  **Project Progress Status**: Based on the ratio of "Written Posts" to the total "Post Count," the plugin calculates and assigns a progress status (e.g., "On Track", "At Risk", "Exceeded") to the project.
4.  **Posting Schedule Management**: Automatically determines if a post is needed today based on configurable posting frequency and tracks the last actual posting date.
5.  **Automated Daily Updates**: Includes a Rake task and cron job configuration for daily batch updates of all projects.

This plugin is ideal for organizations that offer tiered services or manage projects with defined deliverable quotas (e.g., content creation, support tickets, development tasks).

## 2. Features

*   **Service Package Management:**
    *   Create, Read, Update, and Delete service packages in the Administration panel.
    *   Each package has a Name, Post Count (total allowed), and Description.
*   **Automatic Post Counting:**
    *   Automatically counts issues under a designated tracker as "written posts".
    *   The count is updated when relevant issues are created, deleted, or have their tracker/status changed.
    *   Counts only child issues of the latest "Social Plan" issue in each project.
*   **Posting Schedule Intelligence:**
    *   Determines if a post is needed today based on posting frequency configuration.
    *   Tracks the actual posting dates and calculates overdue status.
    *   Supports configurable posting frequencies (daily, weekly, etc.).
*   **Progress Calculation:**
    *   Calculates project completion based on written posts vs. total posts.
    *   Assigns a text-based status based on configurable rules (e.g., display "At Risk" when behind schedule).
*   **Project Integration:**
    *   Seamlessly integrates with projects via Project Custom Fields.
    *   Fields for tracking are automatically updated to ensure data integrity.
*   **Automated Daily Processing:**
    *   Includes Rake task for batch processing all active projects.
    *   Cron job configuration for daily automated updates at 1:00 AM.
*   **UI Enhancements:**
    *   Adds a color-coded status indicator to the project list for quick progress assessment.
*   **Internationalization:**
    *   Supports English and Vietnamese.

## 3. Installation

1.  **Download/Clone Plugin:**
    *   Place the `redmine_service_packages` directory into your Redmine `plugins` folder.
2.  **Install Dependencies:**
    *   The plugin includes a `Gemfile` with required dependencies.
    *   From your Redmine root directory, run: `bundle install`
3.  **Run Migrations:**
    *   Navigate to your Redmine root directory.
    *   Run: `bundle exec rake redmine:plugins:migrate RAILS_ENV=production`
4.  **Restart Redmine:**
    *   Restart your Redmine application server (e.g., Puma, Passenger).

## 4. Configuration

After installation, the plugin requires configuration of custom fields and settings.

### Step 1: Create Project Custom Fields

Go to "Administration" -> "Custom fields" and create the following **Project** custom fields:

1.  **Service Package Name Field:**
    *   Format: **List**
    *   Name: e.g., "Service Package"
    *   Possible values: Enter the exact names of the service packages you will create (e.g., "Pro 1", "Pro 2").
    *   *Make sure this field is active.*
2.  **Total Post Count Field:**
    *   Format: **Integer**
    *   Name: e.g., "Total Posts"
    *   This field will be automatically populated from the selected service package.
    *   *Make sure this field is active.*
3.  **Written Posts Count Field:**
    *   Format: **Integer**
    *   Name: e.g., "Written Posts"
    *   This field will be automatically updated by the plugin as issues are created.
    *   *Make sure this field is active.*
4.  **Progress Status Field:**
    *   Format: **List**
    *   Name: e.g., "Progress Status"
    *   Possible values: "Đang chạy", "Sắp đủ bài", "Hoàn thành", "Quá hạn mức"
    *   This field will display the calculated status.
    *   *Make sure this field is active.*
5.  **Needs Posting Today Field:**
    *   Format: **Boolean**
    *   Name: e.g., "Hôm nay cần đăng bài"
    *   This field indicates if a post is required today based on frequency.
    *   *Make sure this field is active.*

### Step 2: Create Issue Custom Fields

Go to "Administration" -> "Custom fields" and create the following **Issue** custom fields:

1.  **Posting Frequency Field:**
    *   Format: **Integer**
    *   Name: e.g., "Tần suất đăng bài"
    *   Applied to "Social Plan" tracker issues.
    *   Represents posting frequency in days (e.g., 1 for daily, 7 for weekly).
2.  **Posting Date Field:**
    *   Format: **Date**
    *   Name: e.g., "Ngày đăng"
    *   Applied to "Written Post" tracker issues.
    *   Records the actual posting date.

### Step 3: Configure Plugin Settings

1.  Go to "Administration" -> "Plugins".
2.  Find "Redmine Service Packages" and click "Configure".
3.  Map the custom fields you created in Steps 1-2 to the corresponding settings:
    *   **Service Package Name CF ID**: Map to the List field for service packages.
    *   **Service Package Posts CF ID**: Map to the Integer field for total posts.
    *   **Written Posts CF ID**: Map to the Integer field for written posts count.
    *   **Progress Status CF ID**: Map to the List field for progress status.
    *   **Needs Posting Today CF ID**: Map to the Boolean field for posting requirements.
    *   **Posting Frequency CF ID**: Map to the Issue Integer field for frequency.
    *   **Posting Date CF ID**: Map to the Issue Date field for posting dates.
    *   **Counting Tracker ID**: Enter the ID of the tracker for "Written Posts".
    *   **Social Plan Tracker ID**: Enter the ID of the tracker for "Social Plan" issues.
4.  **Progress Calculation Rules**: (Optional) Modify the rules that determine progress status.
5.  Click "Apply".

### Step 4: Manage Service Packages

1.  Go to "Administration" -> "Service Packages".
2.  Create your service packages (e.g., "Pro 1" with Post Count 20). The names must **exactly match** the "Possible values" you set for the 'List' custom field.

### Step 5: Setup Automated Daily Updates (Optional)

The plugin includes automated batch processing capabilities:

1.  **Manual Execution:**
    ```bash
    # Test the rake task
    RAILS_ENV=production bundle exec rake redmine_service_packages:update_all_projects_status
    ```

2.  **Automated Daily Execution:**
    ```bash
    # Setup cron job to run daily at 1:00 AM
    bundle exec whenever --update-crontab --load-file plugins/redmine_service_packages/config/schedule.rb --set 'environment=production'
    
    # Verify cron job was created
    crontab -l
    
    # Check cron job logs
    tail -f log/cron_service_packages.log
    ```

3.  **Remove Cron Job (if needed):**
    ```bash
    bundle exec whenever --clear-crontab --load-file plugins/redmine_service_packages/config/schedule.rb
    ```

## 5. Usage

1.  **Enable Module for Projects:**
    *   Go to a project's "Settings" -> "Modules" tab.
    *   Check "Service packages module" and save.
2.  **Setup Project Structure:**
    *   Create a "Social Plan" issue in your project with the configured tracker.
    *   Set the "Posting Frequency" custom field on this issue (e.g., 1 for daily, 7 for weekly).
    *   Create "Written Post" issues as children of the Social Plan issue.
3.  **Assign Service Package:**
    *   On the project's "Settings" page, select a "Service Package" from the dropdown.
    *   Click "Save".
    *   The plugin will automatically update all related fields.
4.  **Track Progress:**
    *   As you create "Written Post" issues with actual posting dates, the counts will automatically update.
    *   The "Needs Posting Today" field will indicate if a post is required based on frequency.
    *   The "Progress Status" will update according to your rules.
    *   View status colors in the project list by adding the "Progress Status" field as a column.

## 6. Automatic Updates

The plugin automatically updates project data in the following scenarios:

*   **Real-time Updates:** When creating, editing, or deleting issues
*   **Daily Batch Updates:** Via cron job at 1:00 AM (if configured)
*   **Manual Updates:** Via Rake task execution

### Rake Task Details

The plugin provides a comprehensive Rake task:

```bash
# Update all active projects
RAILS_ENV=production bundle exec rake redmine_service_packages:update_all_projects_status
```

This task:
*   Processes all active projects
*   Updates written post counts
*   Calculates posting requirements
*   Updates progress status
*   Provides detailed logging

## 7. Troubleshooting

*   **Counts or Status not updating:**
    *   Ensure Redmine has been restarted after installation.
    *   Double-check that all custom fields are correctly created and mapped in the plugin settings.
    *   Verify that tracker IDs are correct in the plugin configuration.
    *   Confirm that `ServicePackage` record names exactly match the values in the 'List' custom field.
    *   Check that "Social Plan" and "Written Post" issues are properly structured (parent-child relationship).
    *   Check Redmine's logs: `tail -f log/production.log | grep RSP`

*   **Cron Job Issues:**
    *   Verify `whenever` gem is installed: `bundle list | grep whenever`
    *   Check cron job setup: `crontab -l`
    *   Monitor cron job execution: `tail -f log/cron_service_packages.log`
    *   Ensure proper environment variables are set in the cron job.

*   **Permission Errors:**
    *   Ensure the web server user has write permissions to the log directory.
    *   Check that all custom fields are marked as "For all projects" or properly assigned to specific projects.

*   **Performance Issues:**
    *   For installations with many projects, consider running the daily update during off-peak hours.
    *   Monitor the execution time of the Rake task and optimize if necessary.

## 8. Development Notes

The plugin has been refactored for maintainability:

*   **Clean Architecture:** Service classes are split into focused, single-responsibility methods.
*   **Error Handling:** Comprehensive error logging and graceful failure handling.
*   **Testing:** Rake task can be safely tested without affecting production data.
*   **Extensibility:** Easy to add new rules or modify existing calculation logic.

## 9. Author

@tuandbe

## 10. Contributing

Patches, bug reports, and feature requests are welcome.

---

*This README provides a comprehensive guide. Depending on your Redmine version and specific setup, some steps might vary slightly.* 
