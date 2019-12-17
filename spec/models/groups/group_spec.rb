# frozen_string_literal: true

require "rails_helper"

describe Groups::Group do
  it "has a valid factory" do
    create(:group)
  end

  describe "normalization" do
    describe "memberships" do
      let(:memberships) do
        [build(:group_membership, kind: "member"), build(:group_membership, kind: "manager")]
      end
      let(:group) { create(:group, memberships: memberships) }

      context "for normal group" do
        it "is expected to have saved memberships" do
          expect(group.memberships.map(&:kind)).to eq(%w[member manager])
          expect(Groups::Membership.count).to eq(2)
        end
      end

      context "for broadcast group" do
        it "is expected to delete non-manager memberships" do
          group.update!(kind: "broadcast")
          expect(group.memberships.map(&:kind)).to eq(["manager"])
          expect(Groups::Membership.count).to eq(1)
        end
      end
    end
  end

  describe "validation" do
    describe "name uniqueness in all relevant communities" do
      let(:community1) { create(:community) }
      let(:community2) { create(:community) }

      context "with no existing groups" do
        subject(:group) { build(:group, communities: [community1], name: "Foo") }
        it { is_expected.to be_valid }
      end

      context "with same names and single community groups" do
        let!(:existing) { create(:group, communities: [community1], name: "Foo") }
        subject(:group) { build(:group, communities: [community1], name: "Foo") }
        it { is_expected.to have_errors(name: "has already been taken") }
      end

      context "with same names in cluster but separate communities" do
        let!(:existing) { create(:group, communities: [community1], name: "Foo") }
        subject(:group) { build(:group, communities: [community2], name: "Foo") }
        it { is_expected.to be_valid }
      end

      context "with single community group and multi community group" do
        let!(:existing) { create(:group, communities: [community1], name: "Foo") }
        subject(:group) { build(:group, communities: [community1, community2], name: "Foo") }
        it { is_expected.to have_errors(name: "has already been taken") }
      end
    end
  end
end
