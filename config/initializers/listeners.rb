# frozen_string_literal: true

Rails.application.config.after_initialize do
  Work::JobReminder.subscribe(Work::JobReminderMaintainer.instance)
  Work::Job.subscribe(Work::JobReminderMaintainer.instance)

  Meals::RoleReminder.subscribe(Meals::RoleReminderMaintainer.instance)
  Meals::Formula.subscribe(Meals::RoleReminderMaintainer.instance)
  Meals::Meal.subscribe(Meals::RoleReminderMaintainer.instance)
  Meals::Role.subscribe(Meals::RoleReminderMaintainer.instance)

  User.subscribe(Work::ShiftIndexUpdater.instance)
  Groups::Group.subscribe(Work::ShiftIndexUpdater.instance)
  Work::Job.subscribe(Work::ShiftIndexUpdater.instance)

  User.subscribe(Groups::MembershipMaintainer.instance)
  Groups::Affiliation.subscribe(Groups::MembershipMaintainer.instance)
  Household.subscribe(Groups::MembershipMaintainer.instance)

  # SyncListener must come after MembershipMaintainer because the former
  # relies on the latter having removed a user's memberships after e.g. they are deactivated.
  User.subscribe(Groups::Mailman::SyncListener.instance)
  Household.subscribe(Groups::Mailman::SyncListener.instance)
  Groups::Group.subscribe(Groups::Mailman::SyncListener.instance)
  Groups::Mailman::List.subscribe(Groups::Mailman::SyncListener.instance)
  Groups::Affiliation.subscribe(Groups::Mailman::SyncListener.instance)
  Groups::Membership.subscribe(Groups::Mailman::SyncListener.instance)
end
