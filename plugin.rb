# frozen_string_literal: true

# name: discourse-browser-bypass
# about: Allows specific user-agents to bypass the "unsupported browser" gate
# version: 0.1.0
# authors: Tony
# url: https://github.com/tonyfruzza/discourse-browser-bypass
# required_version: 2.7.0

enabled_site_setting :browser_bypass_enabled

register_html_builder("server:before-script-load") do |controller|
  if SiteSetting.browser_bypass_enabled
    nonce = controller.helpers.csp_nonce_placeholder rescue ""
    <<~HTML
      <script nonce="#{nonce}">
      (function() {
        var errors = [];
        window.onerror = function(msg, url, line, col, err) {
          errors.push(msg + ' at ' + url + ':' + line + ':' + col);
          var d = document.getElementById('compat-errors');
          if (!d) {
            d = document.createElement('div');
            d.id = 'compat-errors';
            d.style.cssText = 'position:fixed;bottom:0;left:0;right:0;background:red;color:white;padding:8px;z-index:999999;font-size:12px;max-height:40vh;overflow:auto';
            document.body.appendChild(d);
          }
          d.innerHTML = '<b>JS Errors:</b><br>' + errors.join('<br>');
        };
        window.addEventListener('unhandledrejection', function(e) {
          var reason = e.reason ? (e.reason.stack || e.reason.message || String(e.reason)) : 'unknown';
          errors.push('Promise: ' + reason);
          var d = document.getElementById('compat-errors');
          if (!d) {
            d = document.createElement('div');
            d.id = 'compat-errors';
            d.style.cssText = 'position:fixed;bottom:0;left:0;right:0;background:red;color:white;padding:8px;z-index:999999;font-size:12px;max-height:40vh;overflow:auto';
            document.body.appendChild(d);
          }
          d.innerHTML = '<b>JS Errors:</b><br>' + errors.join('<br>');
        });
      })();
      </script>
    HTML
  else
    ""
  end
end

after_initialize do
  reloadable_patch do |plugin|
    CrawlerDetection.singleton_class.prepend(
      Module.new do
        def show_browser_update?(user_agent)
          return false unless super(user_agent)
          return false if SiteSetting.browser_bypass_allow_all

          bypass_agents = SiteSetting.browser_update_bypass_agents
          return true if bypass_agents.blank?

          @browser_bypass_matchers ||= {}
          matcher =
            @browser_bypass_matchers[bypass_agents] ||=
              CrawlerDetection.to_matcher(bypass_agents)

          !user_agent.match?(matcher)
        end
      end,
    )
  end
end
