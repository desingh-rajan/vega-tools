require "test_helper"

class Api::V1::SiteSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @site_info = site_settings(:site_info)
    @contact_info = site_settings(:contact_info)
    @hero_section = site_settings(:hero_section)
    @social_links = site_settings(:social_links)
    @footer_content = site_settings(:footer_content)
  end

  # INDEX tests
  test "index returns all site settings" do
    get api_v1_site_settings_url, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal "success", json["status"]
    assert json["data"].is_a?(Hash)
    assert json["data"]["site_info"].present?
    assert json["data"]["contact_info"].present?
  end

  test "index returns settings as key-value pairs" do
    get api_v1_site_settings_url, as: :json

    json = JSON.parse(response.body)

    assert_equal "Test Store", json["data"]["site_info"]["name"]
    assert_equal "+91 1234567890", json["data"]["contact_info"]["phone"]
  end

  # SHOW tests
  test "show returns single setting by key" do
    get api_v1_site_setting_url(key: "site_info"), as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal "site_info", json["data"]["key"]
    assert_equal "Test Store", json["data"]["value"]["name"]
  end

  test "show returns 404 for non-existent key" do
    get api_v1_site_setting_url(key: "non_existent"), as: :json

    assert_response :not_found
  end

  # HOMEPAGE tests
  test "homepage returns all homepage settings in one call" do
    get homepage_api_v1_site_settings_url, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal "success", json["status"]
    assert json["data"]["site_info"].present?
    assert json["data"]["hero_section"].present?
    assert json["data"]["contact_info"].present?
    assert json["data"]["social_links"].present?
    assert json["data"]["footer_content"].present?
    assert json["data"]["featured_categories"].is_a?(Array)
    assert json["data"]["featured_products"].is_a?(Array)
  end

  test "homepage returns hero section data" do
    get homepage_api_v1_site_settings_url, as: :json

    json = JSON.parse(response.body)

    assert_equal "Welcome", json["data"]["hero_section"]["title"]
    assert_equal "Shop Now", json["data"]["hero_section"]["subtitle"]
  end

  # APP_CONFIG tests
  test "app_config returns essential app configuration" do
    get app_config_api_v1_site_settings_url, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal "success", json["status"]
    assert_equal "Test Store", json["data"]["app_name"]
    assert_equal "Best Tools", json["data"]["tagline"]
    assert_equal "INR", json["data"]["currency"]
    assert_equal "₹", json["data"]["currency_symbol"]
    assert json["data"]["contact"].present?
    assert_equal "+91 1234567890", json["data"]["contact"]["phone"]
  end

  test "app_config includes social links" do
    get app_config_api_v1_site_settings_url, as: :json

    json = JSON.parse(response.body)

    assert json["data"]["social_links"].present?
    assert_equal "https://facebook.com/test", json["data"]["social_links"]["facebook"]
  end

  test "app_config returns defaults when settings not configured" do
    SiteSetting.delete_all

    get app_config_api_v1_site_settings_url, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    # Should use fallback values
    assert_equal "Vega Tools", json["data"]["app_name"]
  end

  # Featured data tests
  test "homepage featured_categories uses setting when available" do
    category = categories(:power_tools)
    SiteSetting.find_or_create_by!(key: "featured_categories") do |s|
      s.category = "sections"
      s.is_public = true
      s.value = [ category.id ]
    end.update!(value: [ category.id ])

    get homepage_api_v1_site_settings_url, as: :json

    json = JSON.parse(response.body)

    assert json["data"]["featured_categories"].length >= 1
    category_names = json["data"]["featured_categories"].map { |c| c["name"] }
    assert_includes category_names, "Power Tools"
  end

  test "homepage featured_products uses setting when available" do
    product = products(:professional_drill)
    SiteSetting.find_or_create_by!(key: "featured_products") do |s|
      s.category = "sections"
      s.is_public = true
      s.value = [ product.id ]
    end.update!(value: [ product.id ])

    get homepage_api_v1_site_settings_url, as: :json

    json = JSON.parse(response.body)

    assert json["data"]["featured_products"].length >= 1
    product_names = json["data"]["featured_products"].map { |p| p["name"] }
    assert_includes product_names, "Professional Drill"
  end
end
