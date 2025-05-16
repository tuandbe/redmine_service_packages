# Redmine Service Packages Plugin

## Plugin Overview

The Redmine Service Packages plugin allows administrators to define "Service Packages" (e.g., "Basic", "Pro", "Premium") which can then be associated with projects. Each service package has a name, a description, and a "Post Count".

When a project is assigned a specific service package via a project custom field, the corresponding "Post Count" for that package is automatically synced to another project custom field. This "Post Count" custom field can then be displayed in project views and lists.

This plugin is useful for organizations that offer different tiers of service or project scopes, where each tier has a predefined capacity (e.g., number of allowed posts, tasks, or other units).

## Features

*   **Service Package Management:**
    *   Administrators can Create, Read, Update, and Delete service packages.
    *   Each service package includes:
        *   Name (e.g., "Pro 1")
        *   Post Count (e.g., 20)
        *   Description
*   **Project Integration:**
    *   Assign a Service Package to a project using a dedicated 'List' type Project Custom Field.
    *   Automatically populate a separate 'Integer' type Project Custom Field with the "Post Count" from the selected Service Package.
*   **Readonly Post Count Field:**
    *   The "Post Count" custom field on the project settings page is made readonly, as it's automatically updated.
*   **Internationalization:**
    *   Supports English and Vietnamese.

## Installation

1.  **Download/Clone Plugin:**
    *   Place the `redmine_service_packages` plugin directory into your Redmine `plugins` folder (e.g., `REDMINE_ROOT/plugins/redmine_service_packages`).
2.  **Install Dependencies (if any specified in a Gemfile within the plugin - N/A for this plugin currently):**
    *   Navigate to your Redmine root directory: `cd REDMINE_ROOT`
    *   Run: `bundle install`
3.  **Run Migrations:**
    *   Navigate to your Redmine root directory.
    *   Run: `bundle exec rake redmine:plugins:migrate RAILS_ENV=production` (or `development` if appropriate)
    *   Alternatively, for newer Redmine versions: `bundle exec bin/rails redmine:plugins:migrate RAILS_ENV=production`
4.  **Restart Redmine:**
    *   Restart your Redmine application server (e.g., Puma, Passenger, Webrick).

## Configuration

After installation and restarting Redmine, you need to configure the plugin and associated project custom fields:

1.  **Create Project Custom Fields:**
    *   Go to "Administration" -> "Custom fields".
    *   Click "New custom field".
    *   **Service Package Name Field:**
        *   Format: **List**
        *   Name: e.g., "Service Package" (or "Gói dịch vụ" in Vietnamese)
        *   Possible values: Enter the names of the service packages you plan to create (e.g., "Pro 1", "Pro 2"). These must exactly match the names of the `ServicePackage` records you will create later.
        *   Used as a filter: Your choice.
        *   For all projects: Your choice.
        *   Trackers: Select the trackers where this field should be available.
        *   *Make sure this field is active.*
    *   **Post Count Field:**
        *   Format: **Integer**
        *   Name: e.g., "Post Count" (or "Số bài viết" in Vietnamese)
        *   Min/Max length, Default value: Your choice (though the default value will be overwritten by the plugin).
        *   For all projects: Your choice.
        *   Trackers: Select the trackers where this field should be available.
        *   *Make sure this field is active.*
    *   Note down the **IDs** of these two custom fields. You can usually see the ID in the URL when editing the custom field, or by inspecting the HTML.

2.  **Configure Plugin Settings:**
    *   Go to "Administration" -> "Plugins".
    *   Find "Redmine Service Packages" in the list and click its "Configure" link.
    *   **Project Custom Field for Service Package Name:** Select the 'List' custom field you created in step 1 (e.g., "Service Package").
    *   **Project Custom Field for Package Post Count:** Select the 'Integer' custom field you created in step 1 (e.g., "Post Count").
    *   Click "Apply".

3.  **Manage Service Packages:**
    *   Go to "Administration" -> "Service Packages" (this new menu item is added by the plugin).
    *   Create your service packages (e.g., "Pro 1" with Post Count 20, "Pro 2" with Post Count 50). The names must match the "Possible values" you set for the 'List' custom field.

## Usage

1.  **Enable Module for Projects:**
    *   Go to a project's "Settings" page.
    *   Go to the "Modules" tab.
    *   Ensure "Service packages module" (or its translated name) is checked.
    *   Click "Save".

2.  **Assign Service Package to a Project:**
    *   On the project's "Settings" page (Overview tab, or wherever your custom fields appear).
    *   You should see the "Service Package" custom field (the 'List' type one).
    *   Select a service package from the dropdown.
    *   You should see the "Post Count" custom field (the 'Integer' type one). This field will be readonly.
    *   Click "Save".
    *   The "Post Count" field should automatically update to reflect the post count of the selected service package.

3.  **Viewing Post Count:**
    *   The "Post Count" custom field can be added as a column in the project list ("Administration" -> "Settings" -> "Projects" -> "Columns displayed on project list").
    *   It will also be visible on the project's overview page or wherever project custom fields are displayed.

## Troubleshooting

*   **"Post Count" not updating:**
    *   Ensure Redmine has been restarted after plugin installation/updates.
    *   Verify that the custom field IDs are correctly configured in the plugin settings.
    *   Check that the names of the `ServicePackage` records exactly match the "Possible values" in your 'List' type custom field.
    *   Check Redmine's `log/development.log` or `log/production.log` for any errors related to the plugin.
*   **Plugin not visible or menu items missing:**
    *   Ensure the plugin migration has been run.
    *   Ensure Redmine has been restarted.

## Author

@tuandbe

## Contributing

Patches, bug reports, and feature requests are welcome.

---

*This README provides a basic guide. Depending on your Redmine version and specific setup, some steps might vary slightly.* 
