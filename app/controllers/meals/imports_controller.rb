# frozen_string_literal: true

module Meals
  # Handles meal CSV imports.
  class ImportsController < ApplicationController
    before_action :authorize_import
    before_action -> { nav_context(:meals, :meals) }

    def new
      prep_form_vars
    end

    private

    def prep_form_vars
      @roles = Meals::Role.in_community(current_community).by_title
      @sample_times = [Time.current.midnight + 7.days, Time.current.midnight + 10.days].map do |t|
        (t + 18.hours).to_s(:no_sec_no_t)
      end
      @locations = Meal.hosted_by(current_community).newest_first.first&.resources
      @locations ||= Reservations::Resource.in_community(current_community).meal_hostable[0...2].presence
      @locations ||= [
        Reservations::Resource.new(id: 1234, name: "Dining Room"),
        Reservations::Resource.new(id: 5678, name: "Kitchen")
      ]
      @formula = Formula.default_for(current_community) || Formula.new(id: 439, name: "Main Formula")
    end

    def authorize_import
      authorize(Meal.new(community: current_community), :import?, policy_class: Meals::MealPolicy)
    end
  end
end
