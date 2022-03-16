# frozen_string_literal: true

module CardScreenshotter
  class Members
    class << self
      include Rails.application.routes.url_helpers
      include PathHelper

      def update_screenshots
        screenshotter = CardScreenshotter::Utils.new
        update_policy_vote_screenshot(screenshotter)
        update_member_screenshot(screenshotter)
        screenshotter.close_driver!
      end

      def update_policy_vote_screenshot(screenshotter)
        options = { type: "ppd" }
        ppds = PolicyPersonDistance.all
        progress = ProgressBar.create(title: "Members votes on policies screenshots", total: ppds.count, format: "%t: |%B| %E %a")
        ppds.find_each do |ppd|
          update_screenshot(screenshotter, ppd, options)
          progress.increment
        end
      end

      def update_member_screenshot(screenshotter)
        options = { type: "member" }
        members = Member.all
        progress = ProgressBar.create(title: "Members page screenshots", total: members.count, format: "%t: |%B| %E %a")
        members.each do |member|
          update_screenshot(screenshotter, member, options)
          progress.increment
        end
      end

      def update_screenshot(screenshotter, object, options = {})
        screenshotter.screenshot_and_save(url(object, options), save_path(object, options))
      end

      def url(object, options = {})
        case options[:type]
        when "ppd"
          ppd = object
          person_policy_url_simple(ppd.person, ppd.policy, ActionMailer::Base.default_url_options.merge(card: true))
        when "member"
          member = object
          member_url(member.url_params.merge(ActionMailer::Base.default_url_options.merge(card: true)))
        else
          raise StandardError, "Invalid Options! Cannot generate URL"
        end
      end

      def save_path(object, options = {})
        case options[:type]
        when "ppd"
          ppd = object
          "public/cards#{person_policy_path_simple(ppd.person, ppd.policy)}.png"
        when "member"
          member = object
          "public/cards#{member_path_simple(member)}.png"
        else
          raise StandardError, "Invalid Options! Cannot generate save path"
        end
      end
    end
  end
end
