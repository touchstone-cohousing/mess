# frozen_string_literal: true

require "rails_helper"

describe UserPolicy do
  describe "permissions" do
    include_context "policy permissions"
    let(:record) { other_user }

    shared_examples_for "permits action on own community" do
      it "permits action on adults in same community" do
        expect(subject).to permit(actor, other_user)
      end

      it "permits action on children in same community" do
        expect(subject).to permit(actor, other_child)
      end

      it "permits action on inactive users" do
        expect(subject).to permit(actor, inactive_user)
      end
    end

    shared_examples_for "permits action on own community and cluster community adults" do
      it_behaves_like "permits action on own community"

      it "permits action on adults in other community in cluster" do
        expect(subject).to permit(actor, usercmtyB)
      end
    end

    shared_examples_for "permits action on own community users but denies on all others" do
      it_behaves_like "permits action on own community"

      it "denies action on users in other community in cluster" do
        expect(subject).not_to permit(actor, usercmtyB)
        expect(subject).not_to permit(actor, childcmtyB)
      end

      it "denies action on users outside cluster" do
        expect(subject).not_to permit(actor, outside_user)
        expect(subject).not_to permit(actor, outside_child)
      end
    end

    shared_examples_for "permits action on cluster users except non-community children, denies on others" do
      it_behaves_like "permits action on own community and cluster community adults"

      it "denies action on children in other community in cluster" do
        expect(subject).not_to permit(actor, childcmtyB)
      end

      it "denies action on users outside cluster" do
        expect(subject).not_to permit(actor, outside_user)
        expect(subject).not_to permit(actor, outside_child)
      end
    end

    shared_examples_for "inactive users" do
      context "for inactive user" do
        let(:actor) { inactive_user }

        it "denies action on other users" do
          expect(subject).not_to permit(actor, other_user)
        end

        it "permits action on self" do
          expect(subject).to permit(actor, actor)
        end
      end
    end

    shared_examples_for "cluster and super admins" do
      context "for cluster admin" do
        let(:actor) { cluster_admin }
        it_behaves_like "permits action on own community and cluster community adults"

        it "permits action on children in other community in cluster" do
          expect(subject).to permit(actor, childcmtyB)
        end

        it "denies action on users outside cluster" do
          expect(subject).not_to permit(actor, outside_user)
          expect(subject).not_to permit(actor, outside_child)
        end
      end

      context "for super admin" do
        let(:actor) { super_admin }
        it_behaves_like "permits action on own community and cluster community adults"

        it "permits action on children in other community in cluster" do
          expect(subject).to permit(actor, childcmtyB)
        end

        it "permits action on users outside cluster" do
          expect(subject).to permit(actor, outside_user)
          expect(subject).to permit(actor, outside_child)
        end
      end
    end

    shared_examples_for "permits admins except self and guardians" do
      it_behaves_like "permits admins but not regular users"

      it "denies action on self" do
        expect(subject).not_to permit(user, user)
      end

      it "denies action on guardians for own children" do
        expect(subject).not_to permit(guardian, child)
      end
    end

    permissions :index? do
      it "permits action on active users" do
        expect(subject).to permit(user, User)
      end

      it "denies action on inactive users" do
        expect(subject).not_to permit(inactive_user, User)
      end
    end

    permissions :show? do
      context "for normal user" do
        let(:actor) { user }
        it_behaves_like "permits action on cluster users except non-community children, denies on others"
      end

      context "for admin" do
        let(:actor) { admin }
        it_behaves_like "permits action on cluster users except non-community children, denies on others"
      end

      it_behaves_like "cluster and super admins"
      it_behaves_like "inactive users"
    end

    permissions :show_personal_info? do
      context "for normal user" do
        let(:actor) { user }
        it_behaves_like "permits action on own community users but denies on all others"
      end

      context "for admin" do
        let(:actor) { admin }
        it_behaves_like "permits action on own community users but denies on all others"
      end

      it_behaves_like "cluster and super admins"
      it_behaves_like "inactive users"
    end

    permissions :show_photo? do
      context "for normal user without flag set on target" do
        let(:actor) { user }
        it_behaves_like "permits action on cluster users except non-community children, denies on others"
      end

      context "for normal user with flag set to hide on target" do
        let(:actor) { user }
        before do
          usercmtyB.privacy_settings["hide_photo_from_cluster"] = true
        end
        it_behaves_like "permits action on own community users but denies on all others"
      end

      it_behaves_like "cluster and super admins"
      it_behaves_like "inactive users"
    end

    permissions :new?, :create? do
      it_behaves_like "permits admins but not regular users"
    end

    permissions :deactivate?, :show_inactive?, :administer?, :add_basic_role? do
      it_behaves_like "permits admins except self and guardians"
    end

    permissions :impersonate? do
      it_behaves_like "permits admins but not regular users"

      it "denies on self" do
        expect(subject).not_to permit(admin, admin)
      end

      it "permits on other admins of same level" do
        expect(subject).to permit(admin, admin2)
        expect(subject).to permit(cluster_admin, cluster_admin2)
        expect(subject).to permit(super_admin, super_admin2)
      end

      it "denies for admins on higher admins" do
        expect(subject).not_to permit(admin, cluster_admin)
        expect(subject).not_to permit(admin, super_admin)
        expect(subject).not_to permit(cluster_admin, super_admin)
      end

      it "denies on children" do
        expect(subject).not_to permit(admin, child)
      end
    end

    permissions :activate? do
      before { record.deactivate }
      it_behaves_like "permits admins except self and guardians"
    end

    permissions :cluster_adminify? do
      it "permits action on cluster admin and above" do
        expect(subject).to permit(cluster_admin, user)
        expect(subject).to permit(super_admin, user)
      end

      it "denies action on regular admins" do
        expect(subject).not_to permit(admin, user)
      end
    end

    permissions :super_adminify? do
      it "permits action on super admin" do
        expect(subject).to permit(super_admin, user)
      end

      it "denies action on cluster admins" do
        expect(subject).not_to permit(cluster_admin, user)
      end
    end

    permissions :edit?, :update? do
      it_behaves_like "permits admins or special role but not regular users", :photographer
      it_behaves_like "permits self (active or not) and guardians"
    end

    permissions :update_photo? do
      it_behaves_like "permits special role but not regular users", "photographer"

      it "denies admins" do # Admins can do regular edit instead.
        expect(subject).not_to permit(admin, user)
      end
    end

    permissions :update_info? do
      it_behaves_like "permits admins but not regular users"
      it_behaves_like "permits self (active or not) and guardians"
    end

    permissions :destroy? do
      let(:user) { create(:user) }
      let(:admin) { create(:admin) }
      let(:super_admin) { create(:super_admin) }
      let(:record) { create(:user) }

      context "with non-restricted associations" do
        let!(:proxier) { create(:user, job_choosing_proxy: record) }
        let!(:share) { create(:work_share, user: record) }

        it_behaves_like "permits admins but not regular users"
      end

      context "with assignments" do
        let!(:assignment) { create(:work_assignment, user: record) }
        it_behaves_like "forbids all"
      end

      context "with child" do
        let!(:child) { create(:user, :child, guardians: [record]) }
        it_behaves_like "forbids all"
      end

      context "with guardian" do
        before { record.update!(child: true, guardians: [create(:user)]) }
        it_behaves_like "forbids all"
      end

      context "with created meals" do
        let!(:meal) { create(:meal, creator: record) }
        it_behaves_like "forbids all"
      end

      context "with own reservations" do
        let!(:reservation) { create(:reservation, reserver: record) }
        it_behaves_like "forbids all"
      end

      context "with sponsored reservations" do
        let!(:reservation) { create(:reservation, sponsor: record) }
        it_behaves_like "forbids all"
      end

      context "with wiki page creation" do
        let!(:page) { create(:wiki_page, creator: record) }
        it_behaves_like "forbids all"
      end

      context "with wiki page update" do
        let!(:page) { create(:wiki_page, updator: record) }
        it_behaves_like "forbids all"
      end

      context "with wiki page version update" do
        let!(:page) { create(:wiki_page) }

        before do
          page.update!(content: "x", updator: record)
          page.update!(content: "y", updator: create(:user))
          # Only relation at this point should be to second page version
        end

        it_behaves_like "forbids all"
      end
    end
  end

  describe "#grantable_roles" do
    include_context "policy permissions"
    let(:roles) { described_class.new(actor, other_user).grantable_roles }
    let(:base_roles) { %i[biller photographer meals_coordinator wikiist work_coordinator] }

    context "for super admin" do
      let(:actor) { super_admin }
      it { expect(roles).to match_array(%i[super_admin cluster_admin admin] + base_roles) }
    end

    context "for cluster admin" do
      let(:actor) { cluster_admin }
      it { expect(roles).to match_array(%i[cluster_admin admin] + base_roles) }
    end

    context "for admin" do
      let(:actor) { admin }
      it { expect(roles).to match_array(%i[admin] + base_roles) }
    end

    context "for user with base role" do
      let(:actor) { biller }
      it { expect(roles).to be_empty }
    end

    context "for user with no role" do
      let(:actor) { user }
      it { expect(roles).to be_empty }
    end
  end

  describe "scope" do
    include_context "policy scopes"
    let(:klass) { User }

    # If we don't specify guardians, a bunch of extra users get created by the factory.
    let(:child) { create(:user, :child, guardians: [user]) }
    let(:other_child) { create(:user, :child, guardians: [user]) }
    let(:inactive_child) { create(:user, :child, :inactive, guardians: [user]) }
    let(:childB) { create(:user, :child, guardians: [user], community: communityB) }

    shared_examples_for "adults in cluster and children in community" do
      let!(:expected) do
        [user, other_user, userB, inactive_user,
         admin, cluster_admin, child, inactive_child, other_child]
      end
      it { is_expected.to match_array(expected) }
    end

    context "for cluster admin" do
      let(:actor) { cluster_admin }
      let!(:expected) do
        [user, other_user, userB, inactive_user,
         admin, cluster_admin, child, inactive_child, other_child, childB]
      end
      it "returns adults and children in cluster" do
        is_expected.to match_array(expected)
      end
    end

    context "for admin" do
      let(:actor) { admin }
      it_behaves_like "adults in cluster and children in community"
    end

    context "for regular user" do
      let(:actor) { user }
      it_behaves_like "adults in cluster and children in community"
    end
  end

  describe "permitted attributes" do
    include_context "policy permissions"
    let(:user2) { double(community: community, guardians: [], household: double(community: community)) }
    let(:base_attribs) do
      [:email, :first_name, :last_name, :mobile_phone, :home_phone, :work_phone,
       :photo, :photo_tmp_id, :photo_destroy, :birthdate_str, :child, :joined_on, :preferred_contact,
       :job_choosing_proxy_id, :allergies, :doctor, :medical, :school, :household_by_id,
       {privacy_settings: [:hide_photo_from_cluster]},
       {up_guardianships_attributes: %i[id guardian_id _destroy]}]
    end
    let(:normal_user_attribs) do
      base_attribs + [
        {household_attributes: %i[id name garage_nums keyholders]
          .concat(nested_hhold_attribs)}
      ]
    end
    let(:photographer_attribs) { %i[photo photo_tmp_id] }
    let(:admin_attribs) do
      base_attribs + [
        :google_email, :role_admin, :role_biller, :role_photographer,
        :role_meals_coordinator, :role_wikiist, :role_work_coordinator,
        {household_attributes: %i[id name garage_nums keyholders unit_num_and_suffix old_id old_name]
          .concat(nested_hhold_attribs)}
      ]
    end
    let(:cluster_admin_attribs) do
      base_attribs + [
        :google_email, :role_cluster_admin, :role_admin, :role_biller, :role_photographer,
        :role_meals_coordinator, :role_wikiist, :role_work_coordinator,
        {household_attributes: %i[id name garage_nums keyholders unit_num_and_suffix old_id old_name]
          .concat(nested_hhold_attribs)}
      ]
    end
    let(:nested_hhold_attribs) do
      [
        {vehicles_attributes: %i[id make model color plate _destroy]},
        {emergency_contacts_attributes: %i[id name relationship main_phone alt_phone
                                           email location _destroy]},
        {pets_attributes: %i[id name species color vet caregivers health_issues _destroy]}
      ]
    end
    subject { UserPolicy.new(user, user2).permitted_attributes }

    shared_examples_for "normal user" do
      it "should allow normal user attribs" do
        expect(subject).to contain_exactly(*normal_user_attribs)
      end
    end

    context "normal user" do
      it_behaves_like "normal user"
    end

    context "photographer" do
      let(:user) { photographer }

      it "should allow photographer attribs only" do
        expect(subject).to contain_exactly(*photographer_attribs)
      end
    end

    context "admin" do
      let(:user) { admin }

      it "should allow admin attribs" do
        expect(subject).to contain_exactly(*admin_attribs)
      end
    end

    context "admin from other community" do
      let(:user) { admincmtyB }
      it_behaves_like "normal user"
    end

    context "cluster admin" do
      let(:user) { cluster_admin }

      it "should allow cluster admin attribs" do
        expect(subject).to contain_exactly(*cluster_admin_attribs)
      end
    end

    context "super admin" do
      let(:user) { super_admin }

      it "should allow super admin attribs" do
        expect(subject).to contain_exactly(*(cluster_admin_attribs << :role_super_admin))
      end
    end
  end

  describe "#exportable_attributes" do
    include_context "policy permissions"

    let(:sample_user) { double(community: community) }
    subject(:exportable) { described_class.new(actor, sample_user).exportable_attributes }

    context "for regular user" do
      let(:actor) { user }
      it do
        is_expected.to match_array(
          %i[id first_name last_name unit_num unit_suffix birthdate email child
             mobile_phone home_phone work_phone joined_on preferred_contact
             garage_nums vehicles]
        )
      end
    end

    context "for admin" do
      let(:actor) { admin }
      it do
        is_expected.to match_array(
          %i[id first_name last_name unit_num unit_suffix birthdate email child google_email
             mobile_phone home_phone work_phone joined_on preferred_contact
             garage_nums vehicles]
        )
      end
    end
  end
end
