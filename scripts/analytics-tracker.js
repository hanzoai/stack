/**
 * Hanzo Analytics Tracker
 * Production analytics tracking code for all Hanzo services
 */

(function() {
  // Configuration
  const ANALYTICS_HOST = 'https://a.hanzo.ai';
  const SCRIPT_NAME = 'hanzo.js';
  
  // Get website ID from meta tag or data attribute
  function getWebsiteId() {
    const metaTag = document.querySelector('meta[name="hanzo-analytics-id"]');
    if (metaTag) return metaTag.content;
    
    const scriptTag = document.querySelector('script[data-website-id]');
    if (scriptTag) return scriptTag.dataset.websiteId;
    
    // Default mapping based on hostname
    const hostname = window.location.hostname;
    const serviceMap = {
      'chat.hanzo.ai': 'chat-hanzo-ai',
      'ide.hanzo.ai': 'ide-hanzo-ai',
      'search.hanzo.ai': 'search-hanzo-ai',
      'flow.hanzo.ai': 'flow-hanzo-ai',
      'cloud.hanzo.ai': 'cloud-hanzo-ai',
      'app.hanzo.ai': 'app-hanzo-ai',
      'chat.localhost': 'chat-hanzo-ai-dev',
      'ide.localhost': 'ide-hanzo-ai-dev',
      'search.localhost': 'search-hanzo-ai-dev',
      'flow.localhost': 'flow-hanzo-ai-dev',
      'cloud.localhost': 'cloud-hanzo-ai-dev',
      'app.localhost': 'app-hanzo-ai-dev'
    };
    
    return serviceMap[hostname] || 'unknown-hanzo-service';
  }
  
  // Load analytics script if not already loaded
  function loadAnalytics() {
    if (document.querySelector(`script[src*="${SCRIPT_NAME}"]`)) {
      return; // Already loaded
    }
    
    const websiteId = getWebsiteId();
    const script = document.createElement('script');
    script.async = true;
    script.defer = true;
    script.src = `${ANALYTICS_HOST}/${SCRIPT_NAME}`;
    script.dataset.websiteId = websiteId;
    script.dataset.hostUrl = ANALYTICS_HOST;
    
    // Additional tracking configuration
    script.dataset.doNotTrack = 'false';
    script.dataset.domains = 'hanzo.ai,hanzo.ai,localhost';
    
    document.head.appendChild(script);
  }
  
  // Custom event tracking helper
  window.hanzoTrack = function(eventName, eventData) {
    if (window.umami && window.umami.track) {
      window.umami.track(eventName, eventData);
    } else {
      // Queue events until umami is loaded
      window._hanzoEventQueue = window._hanzoEventQueue || [];
      window._hanzoEventQueue.push({ eventName, eventData });
    }
  };
  
  // Process queued events when analytics loads
  function processEventQueue() {
    if (window.umami && window._hanzoEventQueue) {
      window._hanzoEventQueue.forEach(({ eventName, eventData }) => {
        window.umami.track(eventName, eventData);
      });
      window._hanzoEventQueue = [];
    }
  }
  
  // Initialize
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadAnalytics);
  } else {
    loadAnalytics();
  }
  
  // Check for umami availability
  const checkInterval = setInterval(() => {
    if (window.umami) {
      processEventQueue();
      clearInterval(checkInterval);
    }
  }, 100);
  
  // Stop checking after 10 seconds
  setTimeout(() => clearInterval(checkInterval), 10000);
})();