# frozen_string_literal: true

require "rails_helper"

describe "vehicles list" do
  let(:actor) { create(:user) }

  before do
    use_user_subdomain(actor)
    login_as(actor, scope: :user)
  end

  context "with no vehicles" do
    scenario "index" do
      visit(people_vehicles_path)
      expect(page).to have_title("Vehicles")
      expect(page).to have_content("No vehicles found")
    end
  end

  context "with vehicles" do
    let!(:households) { create_list(:household, 2, :with_vehicles) }
    let!(:vehicles) { households.flat_map(&:vehicles) }

    scenario "index" do
      visit(people_vehicles_path)
      expect(page).to have_title("Vehicles")
      vehicles.each { |v| expect(page).to have_content(v.make) }
    end
  end
end
