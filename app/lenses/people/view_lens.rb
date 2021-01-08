# frozen_string_literal: true

module People
  # View options for directory
  class ViewLens < Lens::SelectLens
    param_name :view
    select_prompt :album
    possible_options %i[table tableall albumall]
    i18n_key "simple_form.options.user.view"

    def any_table?
      table? || tableall?
    end

    def any_album?
      album? || albumall?
    end

    def active_only?
      blank? || table? || album?
    end

    protected

    def excluded_options
      UserPolicy.new(context.current_user, h.sample_user).show_inactive? ? [] : %i[albumall tableall]
    end
  end
end
