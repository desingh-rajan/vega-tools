require "test_helper"

class SiteSettingTest < ActiveSupport::TestCase
  setup do
    @site_info = site_settings(:site_info)
    @contact_info = site_settings(:contact_info)
  end

  # Validations
  test "valid site setting with required fields" do
    setting = SiteSetting.new(
      key: "new_setting",
      category: "general",
      value: { "test" => "value" }
    )
    assert setting.valid?
  end

  test "invalid without key" do
    setting = SiteSetting.new(category: "general", value: {})
    assert_not setting.valid?
    assert_includes setting.errors[:key], "can't be blank"
  end

  test "invalid with duplicate key" do
    setting = SiteSetting.new(key: "site_info", category: "general", value: {})
    assert_not setting.valid?
    assert_includes setting.errors[:key], "has already been taken"
  end

  test "invalid without category" do
    setting = SiteSetting.new(key: "test", value: {})
    assert_not setting.valid?
    assert_includes setting.errors[:category], "can't be blank"
  end

  test "invalid with unknown category" do
    setting = SiteSetting.new(key: "test", category: "invalid", value: {})
    assert_not setting.valid?
    assert_includes setting.errors[:category], "is not included in the list"
  end

  test "valid with all allowed categories" do
    SiteSetting::CATEGORIES.each_with_index do |cat, idx|
      setting = SiteSetting.new(key: "test_#{cat}_#{idx}", category: cat, value: { "test" => true })
      assert setting.valid?, "Category '#{cat}' should be valid. Errors: #{setting.errors.full_messages.join(', ')}"
    end
  end

  # Class methods
  test "get returns setting by key" do
    setting = SiteSetting.get("site_info")
    assert_equal @site_info, setting
  end

  test "get returns nil for non-existent non-system key" do
    setting = SiteSetting.get("random_key")
    assert_nil setting
  end

  test "value_for returns setting value hash" do
    value = SiteSetting.value_for("site_info")
    assert_equal "Test Store", value["name"]
  end

  test "value_for returns empty hash for non-existent key" do
    value = SiteSetting.value_for("random_key")
    assert_equal({}, value)
  end

  test "get_all returns multiple settings" do
    result = SiteSetting.get_all("site_info", "contact_info")
    assert result.key?("site_info")
    assert result.key?("contact_info")
  end

  # Scopes
  test "public_settings returns only public settings" do
    public_settings = SiteSetting.public_settings
    assert public_settings.all?(&:is_public)
  end

  test "by_category filters by category" do
    general = SiteSetting.by_category("general")
    assert general.all? { |s| s.category == "general" }
  end

  test "system_settings returns only system settings" do
    system = SiteSetting.system_settings
    assert system.all?(&:is_system)
  end

  # JSON value storage
  test "stores and retrieves JSON value" do
    setting = SiteSetting.create!(
      key: "json_test",
      category: "general",
      value: {
        "nested" => {
          "deep" => "value"
        },
        "array" => [ 1, 2, 3 ]
      }
    )

    setting.reload
    assert_equal "value", setting.value["nested"]["deep"]
    assert_equal [ 1, 2, 3 ], setting.value["array"]
  end

  # Ransackable (for Active Admin)
  test "ransackable_attributes returns allowed attributes" do
    attrs = SiteSetting.ransackable_attributes
    assert_includes attrs, "key"
    assert_includes attrs, "category"
    assert_includes attrs, "is_public"
  end

  # Constants
  test "CATEGORIES constant is defined" do
    assert SiteSetting::CATEGORIES.include?("general")
    assert SiteSetting::CATEGORIES.include?("contact")
    assert SiteSetting::CATEGORIES.include?("sections")
  end

  test "SYSTEM_KEYS constant is defined" do
    assert SiteSetting::SYSTEM_KEYS.include?("site_info")
    assert SiteSetting::SYSTEM_KEYS.include?("contact_info")
  end
end
