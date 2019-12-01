# frozen_string_literal: true

module GeneralHelpers
  def fixture_file_path(name)
    Rails.root.join("spec", "fixtures", name)
  end

  def expectation_file(name)
    File.read(Rails.root.join("spec", "expectations", name))
  end

  # `substitutions` should be a hash of arrays.
  # For each hash pair, e.g. `grp: groups_ids`, the method substitutes
  # e.g. `*grp8*` in the file with `groups_ids[7]`.
  def prepare_expectation(filename, substitutions = {})
    expectation_file(filename).tap do |contents|
      substitutions.each do |key, values|
        values.each_with_index do |value, i|
          contents.gsub!("*#{key}#{i + 1}*", value.to_s)
        end
      end
    end
  end

  def stub_translation(key, msg, expect_defaults: nil)
    original_translate = I18n.method(:translate)
    allow(I18n).to receive(:translate) do |key_arg, options|
      if key == key_arg
        expect(options[:default]).to eq(expect_defaults) if expect_defaults
        msg
      else
        original_translate.call(key_arg, options)
      end
    end
  end

  def use_subdomain(subdomain)
    set_host("#{subdomain}.#{Settings.url.host}")
  end

  def use_user_subdomain(user)
    use_subdomain(user.community.slug)
  end

  def with_tenant(tenant)
    ActsAsTenant.with_tenant(tenant) do
      yield
    end
  end

  def with_locale(locale)
    old_locale = I18n.locale
    I18n.locale = locale
    yield
    I18n.locale = old_locale
  end

  # Tests for a URL with no subdomain.
  def contain_apex_url(path)
    include("http://#{Settings.url.host}:#{Settings.url.port}#{path}")
  end

  def contain_community_url(community, path)
    include("http://#{community.slug}.#{Settings.url.host}:#{Settings.url.port}#{path}")
  end

  def have_correct_meal_url(meal)
    contain_community_url(meal.community, "/meals/#{meal.id}")
  end

  def have_correct_shifts_url(community)
    contain_community_url(community, "/work/signups")
  end

  def have_correct_shift_url(shift)
    contain_community_url(shift.community, "/work/signups/#{shift.id}")
  end

  def email_sent_by
    old_count = ActionMailer::Base.deliveries.size
    yield
    ActionMailer::Base.deliveries[old_count..-1] || []
  end

  # Does nothing. Just a nice way to indicate why a let block is being called.
  def run_let_blocks(*objects)
  end
end
