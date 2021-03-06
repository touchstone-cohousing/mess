# frozen_string_literal: true

require "rails_helper"

describe Work::Period do
  describe "#auto_open_if_appropriate" do
    let(:auto_open_time) { Time.zone.parse("2018-08-15 19:00") } # In past
    let(:period) { create(:work_period, phase: phase, auto_open_time: auto_open_time) }
    subject(:phase) do
      period.auto_open_if_appropriate
      period.reload.phase
    end

    context "in pre-open phase and after auto_open_time" do
      let(:phase) { "draft" }
      it { is_expected.to eq("open") }
    end

    context "no auto_open_time" do
      let(:phase) { "draft" }
      let(:auto_open_time) { nil }
      it { is_expected.to eq("draft") }
    end

    context "before auto_open_time" do
      let(:phase) { "draft" }
      let(:auto_open_time) { Time.current + 7.days }
      it { is_expected.to eq("draft") }
    end
  end

  describe "normalization" do
    context "with shares" do
      let!(:users) { create_list(:user, 2) }
      let(:period) { create(:work_period, :with_shares, quota_type: "by_person") }

      context "with by_person quota" do
        it "keeps shares" do
          expect(period.shares.size).to eq(2)
        end
      end

      context "with none quota" do
        before { period.update!(quota_type: "none") }

        it "loses shares" do
          expect(period.shares).to be_empty
        end
      end
    end

    context "with staggering fields" do
      let(:period) do
        create(:work_period, quota_type: "by_person", pick_type: "staggered", round_duration: 5,
                             auto_open_time: Time.current + 1.day, max_rounds_per_worker: 3,
                             workers_per_round: 10)
      end

      context "with staggered pick type" do
        it "keeps values" do
          expect(period.pick_type).to eq("staggered")
          expect(period.round_duration).to eq(5)
          expect(period.max_rounds_per_worker).to eq(3)
          expect(period.workers_per_round).to eq(10)
        end
      end

      context "with free_for_all pick type" do
        before { period.update!(pick_type: "free_for_all") }

        it "loses values" do
          expect(period.round_duration).to be_nil
          expect(period.max_rounds_per_worker).to be_nil
          expect(period.workers_per_round).to be_nil
        end
      end

      context "with none quota type" do
        before { period.update!(quota_type: "none") }

        it "loses values and switches to free_for_all" do
          expect(period.pick_type).to eq("free_for_all")
          expect(period.round_duration).to be_nil
          expect(period.max_rounds_per_worker).to be_nil
          expect(period.workers_per_round).to be_nil
        end
      end
    end

    context "with auto_open_time in past" do
      let(:period) do
        create(:work_period, phase: "draft", auto_open_time: Time.current - 1.hour)
      end

      it "should open on save" do
        expect(period).to be_open
      end
    end
  end
end
