# frozen_string_literal: true

module CardScreenshotter
  class Members
    class << self
      include Rails.application.routes.url_helpers
      include PathHelper

      def update_screenshots
        driver = CardScreenshotter::Utils.open_headless_driver
        ppds = PolicyPersonDistance.all
        progress = ProgressBar.create(title: "Members screenshots", total: ppds.count, format: "%t: |%B| %E %a")
        ppds.find_each do |ppd|
          update_screenshot(driver, ppd)
          progress.increment
        end
        CardScreenshotter::Utils.close_driver(driver)
      end

      def update_screenshot(driver, ppd)
        CardScreenshotter::Utils.screenshot_and_save(driver, url(ppd), save_path(ppd))
      end

      def url(ppd)
        person_policy_url_simple(ppd.person, ppd.policy, ActionMailer::Base.default_url_options.merge(card: true))
      end

      def save_path(ppd)
        "public/cards#{person_policy_path_simple(ppd.person, ppd.policy)}.png"
      end
    end
  end
end
