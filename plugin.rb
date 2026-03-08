# frozen_string_literal: true

# name: discourse-browser-bypass
# about: Allows specific user-agents to bypass the "unsupported browser" gate
# version: 0.1.0
# authors: Tony
# url: https://github.com/tonyfruzza/discourse-browser-bypass
# required_version: 2.7.0

enabled_site_setting :browser_bypass_enabled

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
