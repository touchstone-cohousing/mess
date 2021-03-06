# frozen_string_literal: true

require "rails_helper"

describe Reservations::ReservationPolicy do
  let(:reserver) { create(:user) }
  let(:resource) { create(:resource) }

  describe "permissions" do
    include_context "policy permissions"
    let(:created_at) { nil }
    let(:starts_at) { Time.current + 1.week }
    let(:ends_at) { starts_at + 1.hour }
    let(:reservation) do
      create(:reservation, reserver: reserver, resource: resource, created_at: created_at,
                           starts_at: starts_at, ends_at: ends_at)
    end
    let(:record) { reservation }

    shared_examples_for "permits admins and reserver" do
      it_behaves_like "permits admins but not regular users"
      it "permits reserver" do
        expect(subject).to permit(reserver, reservation)
      end
    end

    shared_examples_for "permits admins but not reserver" do
      it_behaves_like "permits admins but not regular users"
      it "forbids reserver" do
        expect(subject).not_to permit(reserver, reservation)
      end
    end

    permissions :choose_reserver? do
      it_behaves_like "permits admins but not reserver"
    end

    context "non-meal reservation" do
      permissions :index?, :show?, :new?, :create? do
        it_behaves_like "permits active users only"
      end

      permissions :edit?, :update? do
        it_behaves_like "permits admins and reserver"

        context "just-created reservation with end time in past" do
          let(:starts_at) { 3.hours.ago }
          let(:created_at) { 50.minutes.ago }
          it_behaves_like "permits admins and reserver"
        end

        context "not-just-created reservation with end time in past" do
          let(:created_at) { 90.minutes.ago }
          let(:starts_at) { 3.hours.ago }

          it_behaves_like "permits admins and reserver"
        end
      end

      permissions :destroy? do
        context "future reservation" do
          let(:starts_at) { 1.day.from_now }
          it_behaves_like "permits admins and reserver"
        end

        context "just-created reservation" do
          let(:starts_at) { 1.day.ago }
          let(:created_at) { 50.minutes.ago }
          it_behaves_like "permits admins and reserver"
        end

        context "not-just-created reservation" do
          let(:starts_at) { 1.day.ago }
          let(:created_at) { 1.week.ago }
          it_behaves_like "permits admins but not reserver"
        end
      end

      permissions :privileged_change? do
        it_behaves_like "permits admins but not reserver"
      end
    end

    context "meal reservation" do
      let(:reservation) { create(:reservation, reserver: reserver, resource: resource, kind: "_meal") }

      permissions :index?, :show? do
        it_behaves_like "permits active users only"
      end

      permissions :new?, :create?, :destroy? do
        it "forbids all" do
          expect(subject).not_to permit(reserver, reservation)
          expect(subject).not_to permit(user, reservation)
          expect(subject).not_to permit(admin, reservation)
        end
      end

      permissions :edit?, :update? do
        it "permits access to admins, meals coordinators, and meal creator, and forbids others" do
          expect(subject).to permit(reserver, reservation)
          expect(subject).to permit(admin, reservation)
          expect(subject).to permit(meals_coordinator, reservation)
          expect(subject).not_to permit(user, reservation)
        end
      end
    end
  end

  describe "scope" do
    include_context "policy scopes"
    let(:klass) { Reservations::Reservation }
    let(:resource) { create(:resource) }
    let(:resourceB) { create(:resource, community: communityB) }
    let!(:objs_in_community) { create_list(:reservation, 2, resource: resource) }
    let!(:objs_in_cluster) { create_list(:reservation, 2, resource: resourceB) }

    it_behaves_like "permits all users in cluster"
  end

  describe "permitted_attributes" do
    include_context "policy permissions"
    let(:reservation) { create(:reservation, resource: resource) }
    let(:admin_attribs) { basic_attribs + %i[reserver_id] }
    subject { Reservations::ReservationPolicy.new(reserver, reservation).permitted_attributes }

    shared_examples_for "basic attribs" do
      it "should allow basic attribs" do
        expect(subject).to contain_exactly(*basic_attribs)
      end
    end

    shared_examples_for "each user type" do
      context "regular user" do
        it_behaves_like "basic attribs"
      end

      context "admin" do
        let(:reserver) { admin }

        it "should allow admin-only attribs" do
          expect(subject).to contain_exactly(*admin_attribs)
        end
      end

      context "outside admin" do
        let(:reserver) { admin_cmtyB }
        it_behaves_like "basic attribs"
      end
    end

    context "regular reservation" do
      let(:basic_attribs) { %i[name kind sponsor_id starts_at ends_at guidelines_ok note] }
      it_behaves_like "each user type"
    end

    context "meal reservation" do
      let(:basic_attribs) { %i[starts_at ends_at note] }
      let(:reservation) { create(:reservation, reserver: reserver, resource: resource, kind: "_meal") }
      it_behaves_like "each user type"
    end
  end
end
