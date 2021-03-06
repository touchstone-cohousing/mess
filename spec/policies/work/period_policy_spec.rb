# frozen_string_literal: true

require "rails_helper"

describe Work::PeriodPolicy do
  include_context "work policies"

  describe "permissions" do
    include_context "policy permissions"
    let(:phase) { "published" }
    let(:quota_type) { "none" }
    let(:auto_open_time) { nil }
    let(:period) do
      create(:work_period, phase: phase, quota_type: quota_type, auto_open_time: auto_open_time)
    end
    let(:record) { period }

    permissions :index?, :show?, :new?, :edit?, :review_notices?,
                :create?, :update?, :destroy? do
      it_behaves_like "permits admins or special role but not regular users", :work_coordinator
    end

    permissions :report_wrapper? do
      it_behaves_like "permits users in community only"
    end

    permissions :send_notices? do
      context "when not ready or open phase" do
        let(:phase) { "draft" }
        it_behaves_like "forbids all"
      end

      context "when quota none" do
        let(:quota_type) { "none" }
        it_behaves_like "forbids all"
      end

      context "when quota not none and period ready" do
        let(:phase) { "ready" }
        let(:quota_type) { "by_person" }
        it_behaves_like "permits admins or special role but not regular users", :work_coordinator
      end
    end

    permissions :report? do
      it_behaves_like "permits users only in some phases", %i[ready open published archived]
    end
  end

  describe "scope" do
    include_context "policy scopes"
    let(:klass) { Work::Period }
    let!(:objs_in_community) { create_list(:work_period, 2) }
    let!(:objs_in_cluster) { create_list(:work_period, 2, community: communityB) }

    it_behaves_like "permits regular users in community"
  end

  describe "permitted attributes" do
    include_context "policy permissions"
    let(:actor) { work_coordinator }
    subject { Work::PeriodPolicy.new(actor, Work::Period.new).permitted_attributes }

    it do
      expect(subject).to match_array(
        %i[starts_on ends_on name phase quota_type
           auto_open_time pick_type max_rounds_per_worker workers_per_round round_duration] <<
        {shares_attributes: %i[id user_id portion priority]}
      )
    end
  end
end
