# frozen_string_literal: true

module Reservations
  module Rules
    # Rule for limiting access to other communities in cluster.
    class OtherCommunitiesRule < Rule
      # In order of restrictiveness, least to most.
      VALUES = %i[sponsor read_only forbidden].freeze

      def check(reservation)
        case value
        when "forbidden", "read_only"
          reservation.reserver_community == community ||
            # TODO: When I18ning these messages, add kinds when set.
            [:base, "Residents from other communities may not make reservations"]
        when "sponsor"
          reservation.reserver_community == community ||
            reservation.sponsor_community == community ||
            [:sponsor_id, "You must have a sponsor from #{community.name}"]
        else
          raise "Unknown value for other_communities rule"
        end
      end
    end
  end
end
