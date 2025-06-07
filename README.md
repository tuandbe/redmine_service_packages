# Redmine Service Packages Plugin

> [!NOTE]
> **Please Note:** This plugin was custom-developed for a specific media company to meet their operational needs. If you would like to customize it for your own business requirements, please feel free to get in touch:
> *   **Email:** tuan.m4u@gmail.com
> *   **Phone:** (+84) 972 286 455

## 1. Plugin Overview

The Redmine Service Packages plugin extends Redmine's project management capabilities with features for tracking service-level agreements based on post counts. It allows administrators to define "Service Packages," associate them with projects, and automatically track progress against the package's limits.

The plugin introduces three core features:
1.  **Service Package Sync**: Assign a "Service Package" (e.g., "Pro 1", "Pro 2") to a project. The package's total allowed "Post Count" is automatically synced to a project custom field.
2.  **Automatic Written Post Counting**: The plugin actively counts the number of issues created under a specific, configurable tracker (e.g., "Blog Post"). This count is stored in a "Written Posts" custom field on the project, providing a real-time view of work completed.
3.  **Project Progress Status**: Based on the ratio of "Written Posts" to the total "Post Count," the plugin calculates and assigns a progress status (e.g., "On Track", "At Risk", "Exceeded") to the project. This status can be displayed on project lists for at-a-glance monitoring.

This plugin is ideal for organizations that offer tiered services or manage projects with defined deliverable quotas (e.g., content creation, support tickets, development tasks).

## 2. Features

*   **Service Package Management:**
    *   Create, Read, Update, and Delete service packages in the Administration panel.
    *   Each package has a Name, Post Count (total allowed), and Description.
*   **Automatic Post Counting:**
    *   Automatically counts issues under a designated tracker as "written posts".
    *   The count is updated when relevant issues are created, deleted, or have their tracker/status changed.
*   **Progress Calculation:**
    *   Calculates project completion based on written posts vs. total posts.
    *   Assigns a text-based status based on configurable percentage rules (e.g., display "At Risk" when 80% complete).
*   **Project Integration:**
    *   Seamlessly integrates with projects via Project Custom Fields.
    *   Fields for total and written posts are readonly on the project settings page to ensure data integrity.
*   **UI Enhancements:**
    *   Adds a color-coded status indicator to the project list for quick progress assessment.
*   **Internationalization:**
    *   Supports English and Vietnamese.

## 3. Installation

1.  **Download/Clone Plugin:**
    *   Place the `redmine_service_packages` directory into your Redmine `plugins` folder.
2.  **Run Migrations:**
    *   Navigate to your Redmine root directory.
    *   Run: `bundle exec rake redmine:plugins:migrate RAILS_ENV=production`
3.  **Restart Redmine:**
    *   Restart your Redmine application server (e.g., Puma, Passenger).

## 4. Configuration

After installation, the plugin requires configuration of custom fields and settings.

### Step 1: Create Project Custom Fields

Go to "Administration" -> "Custom fields" and create the following **Project** custom fields.

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
    *   Format: **Text**
    *   Name: e.g., "Progress Status"
    *   This field will display the calculated status (e.g., "On Track").
    *   *Make sure this field is active.*

### Step 2: Configure Plugin Settings

1.  Go to "Administration" -> "Plugins".
2.  Find "Redmine Service Packages" and click "Configure".
3.  Map the custom fields you created in Step 1 to the corresponding settings.
4.  **Counting Tracker ID**: Enter the ID of the tracker whose issues should be counted as posts (e.g., the ID for your "Blog Post" tracker).
5.  **Progress Calculation Rules**: (Optional) Modify the JSON rules that determine the progress status text and color based on the completion percentage.
6.  Click "Apply".

### Step 3: Manage Service Packages

1.  Go to "Administration" -> "Service Packages".
2.  Create your service packages (e.g., "Pro 1" with Post Count 20). The names must **exactly match** the "Possible values" you set for the 'List' custom field.

## 5. Usage

1.  **Enable Module for Projects:**
    *   Go to a project's "Settings" -> "Modules" tab.
    *   Check "Service packages module" and save.
2.  **Assign Service Package:**
    *   On the project's "Settings" page, select a "Service Package" from the dropdown.
    *   Click "Save".
    *   The "Total Posts" field will automatically populate. The "Written Posts" and "Progress Status" fields will also update.
3.  **Track Progress:**
    *   As you create issues under the configured "Counting Tracker", the "Written Posts" count will automatically increase.
    *   The "Progress Status" will update according to your rules.
    *   To see the status colors, add the "Progress Status" field as a column in the project list ("Administration" -> "Settings" -> "Projects" tab).

## 6. Troubleshooting

*   **Counts or Status not updating:**
    *   Ensure Redmine has been restarted after installation.
    *   Double-check that all four custom fields are correctly created and mapped in the plugin settings.
    *   Verify that the "Counting Tracker ID" is correct.
    *   Confirm that the `ServicePackage` record names exactly match the values in the 'List' custom field.
    *   Check Redmine's `log/production.log` for any errors related to the plugin.

## 7. Author

@tuandbe

## 8. Contributing

Patches, bug reports, and feature requests are welcome.

---

*This README provides a basic guide. Depending on your Redmine version and specific setup, some steps might vary slightly.* 
