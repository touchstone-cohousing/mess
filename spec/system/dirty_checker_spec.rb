# frozen_string_literal: true

require "rails_helper"

# TODO: This spec is flaky, gives false negatives, and is not working properly on Travis.
# It is reporting that a dialog was shown when not expected.
# describe "dirty checker" do
#   let(:admin) { create(:admin) }
#   let!(:meal_location) { create(:resource, name: "Dining Room", abbrv: "DR") }
#   let!(:formula) { create(:meal_formula) }
#
#   before do
#     use_user_subdomain(admin)
#     login_as(admin, scope: :user)
#   end
#
#   scenario "meals form", js: true do
#     visit(new_meal_path)
#     expect_no_confirm_on_reload
#     pick_datetime(".meals_meal_served_at")
#     expect_confirm_on_reload
#     # Tried to test more field types but it was taking forever.
#   end
#
#   scenario "user form", js: true do
#     visit(new_user_path)
#     expect_no_confirm_on_reload
#   end
# end
