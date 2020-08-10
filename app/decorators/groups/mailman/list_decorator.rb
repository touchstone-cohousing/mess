# frozen_string_literal: true

module Groups
  module Mailman
    class ListDecorator < ApplicationDecorator
      delegate_all

      def additional_members_ul
        membership_ul(additional_members)
      end

      def additional_senders_ul
        # We don't want to show all of these as there can be quite a few and it's not as sensitive
        # as additional members.
        membership_ul(additional_senders, max: 10)
      end

      private

      def membership_ul(memberships, max: nil)
        overflow = max.nil? ? 0 : memberships.size - max
        memberships = memberships[0...max] if overflow > 0
        items = memberships.sort_by { |m| m.name_or_email.downcase }.map do |membership|
          text = membership.name_or_email
          text << "*" if membership.moderation_action == "hold"
          h.content_tag(:li, h.link_to(text, membership.email))
        end
        items << h.content_tag(:li, "+#{overflow} more") if overflow > 0
        h.content_tag(:ul, h.safe_join(items), class: "no-bullets")
      end
    end
  end
end