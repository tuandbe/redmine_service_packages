document.addEventListener('DOMContentLoaded', function() {
  function applyProgressColors() {
    const projectsTable = document.querySelector('table.list.projects');
    if (!projectsTable) {
      // If it's not the main projects list, try the one in admin (less specific selector)
      // Or, this could be a project overview page that also lists subprojects
      const genericProjectsTable = document.querySelector('table.list');
      if (genericProjectsTable && genericProjectsTable.querySelector('th.name')) { // Heuristic: if it has a name column, it might be projects
        // This is a bit of a guess, ideally we need a more specific selector for other project lists
        // For now, we proceed cautiously if it looks like a generic list table
      } else {
        return; // Not a project list we want to style
      }
    }

    const table = projectsTable || document.querySelector('table.list'); // Use the more specific one if found
    if (!table) return;

    const headers = Array.from(table.querySelectorAll('thead th'));
    let progressColumnIndex = -1;

    headers.forEach((th, index) => {
      // TODO: Make 'Tiến độ' translatable or configurable if necessary
      if (th.textContent.trim() === 'Tiến độ') {
        progressColumnIndex = index;
      }
    });

    if (progressColumnIndex === -1) {
      // console.warn('[RSP] "Tiến độ" column not found.');
      return;
    }

    const rows = table.querySelectorAll('tbody tr');
    rows.forEach(row => {
      const cell = row.cells[progressColumnIndex];
      if (cell) {
        const statusText = cell.textContent.trim();
        let statusClass = '';

        // Remove any existing <span> wrapper to re-apply correctly
        // This is to handle cases where content might be updated via AJAX without full page reload
        const existingSpan = cell.querySelector('span[class^="rsp-status-"]');
        if (existingSpan) {
          cell.textContent = existingSpan.textContent; // Restore original text before re-wrapping
        }
        
        // Update the text content to be wrapped in a span for styling
        const originalText = cell.textContent.trim(); // Get fresh text content

        switch (originalText) {
          case 'Đang chạy':
            statusClass = 'rsp-status-in-progress';
            break;
          case 'Sắp đủ bài':
            statusClass = 'rsp-status-nearing-completion';
            break;
          case 'Hoàn thành':
            statusClass = 'rsp-status-completed';
            break;
          case 'Quá hạn mức':
            statusClass = 'rsp-status-over-limit';
            break;
          default:
            // If status doesn't match, do nothing or apply a default style
            break;
        }

        if (statusClass) {
          // Add a class to the TD as well for potential TD-specific styling
          cell.classList.add('rsp-progress-cell'); 
          // Wrap the content in a span with the status class for finer-grained styling
          cell.innerHTML = `<span class="${statusClass}">${originalText}</span>`;
        }
      }
    });
  }

  // Initial application
  applyProgressColors();

  // Re-apply on AJAX updates (Redmine uses jQuery for AJAX)
  // Using a MutationObserver is more robust if jQuery AJAX events are not standard
  // However, for Redmine, ajaxComplete is common.
  if (typeof jQuery !== 'undefined') {
    jQuery(document).ajaxComplete(function(event, xhr, settings) {
      // Check if the AJAX request might have updated the project list
      // This is a heuristic. A more specific check might be needed if too many AJAX calls trigger this.
      if (settings.url.includes('/projects') || settings.url.includes('/issues') || settings.url.includes('set_filter') || settings.url.includes('query')) {
        setTimeout(applyProgressColors, 100); // Delay slightly to ensure DOM is updated
      }
    });
  }

  // Also consider using MutationObserver for more modern and robust detection of DOM changes
  // Example (simplified):
  // const observer = new MutationObserver(function(mutations) {
  //   mutations.forEach(function(mutation) {
  //     if (mutation.type === 'childList' || mutation.type === 'characterData') {
  //        applyProgressColors();
  //     }
  //   });
  // });
  // const config = { childList: true, subtree: true, characterData: true };
  // const projectListContainer = document.getElementById('content'); // Observe a parent container
  // if (projectListContainer) {
  //   observer.observe(projectListContainer, config);
  // }
}); 
