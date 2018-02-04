module Work
  class JobPolicy < ApplicationPolicy
    alias_method :job, :record

    class Scope < Scope
      def resolve
        if active_cluster_admin?
          scope
        else
          scope.in_community(user.community)
        end
      end
    end

    def index?
      active_in_community?
    end

    def show?
      active_in_community?
    end

    def new?
      active_admin_or?(:work_coordinator)
    end

    def edit?
      new?
    end

    def create?
      new?
    end

    def update?
      new?
    end

    def destroy?
      new?
    end

    def permitted_attributes
      %i(description hours period_id requester_id slot_type time_type title) <<
        {shifts_attributes: %i(starts_at ends_at slots)}
    end
  end
end