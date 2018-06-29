# frozen_string_literal: true

require "rails_helper"

describe Work::ReminderDelivery do
  include_context "reminders"
  describe "deliver_at computation" do
    let(:delivery) { reminder.deliveries.first }
    subject(:deliver_at) { delivery.deliver_at.to_s(:machine_datetime_no_zone) }

    context "date_time job" do
      let(:job) { create(:work_job, shift_times: [shift_start], shift_count: 1) }

      context "absolute time" do
        let(:shift_start) { "2018-01-01 12:00" }
        let!(:reminder) { create_reminder(job, "2018-01-01 09:15") }
        it { is_expected.to eq("2018-01-01 09:15") }
      end

      context "zero days" do
        let(:shift_start) { "2018-01-01 12:00" }
        let!(:reminder) { create_reminder(job, 0, "days_after") }
        it { is_expected.to eq("2018-01-01 09:00") }
      end

      context "negative days" do
        let(:shift_start) { "2018-01-03 12:00" }
        let!(:reminder) { create_reminder(job, 2, "days_before") }
        it { is_expected.to eq("2018-01-01 09:00") }
      end

      context "positive days" do
        let(:shift_start) { "2017-12-31 12:00" }
        let!(:reminder) { create_reminder(job, 1, "days_after") }
        it { is_expected.to eq("2018-01-01 09:00") }
      end

      context "negative hours" do
        let(:shift_start) { "2018-01-01 14:00" }
        let!(:reminder) { create_reminder(job, 3, "hours_before") }
        it { is_expected.to eq("2018-01-01 11:00") }
      end

      context "positive hours" do
        let(:shift_start) { "2017-12-30 11:00" }
        let!(:reminder) { create_reminder(job, 48, "hours_after") }
        it { is_expected.to eq("2018-01-01 11:00") }
      end

      context "fractional hours" do
        let(:shift_start) { "2017-12-30 11:00" }
        let!(:reminder) { create_reminder(job, 3.5, "hours_after") }
        it { is_expected.to eq("2017-12-30 14:30") }
      end
    end

    context "date_only job" do
      let(:job) do
        create(:work_job, shift_times: [shift_start], shift_count: 1, time_type: "date_only")
      end

      context "zero days" do
        let(:shift_start) { "2018-01-01" }
        let!(:reminder) { create_reminder(job, 0, "days_after") }
        it { is_expected.to eq("2018-01-01 09:00") }
      end

      context "negative days" do
        let(:shift_start) { "2018-01-05" }
        let!(:reminder) { create_reminder(job, 4, "days_before") }
        it { is_expected.to eq("2018-01-01 09:00") }
      end

      context "positive days" do
        let(:shift_start) { "2017-12-31" }
        let!(:reminder) { create_reminder(job, 1, "days_after") }
        it { is_expected.to eq("2018-01-01 09:00") }
      end
    end
  end
end
