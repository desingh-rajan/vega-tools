require "test_helper"

class Api::V1::CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @root_category = categories(:power_tools)
    @child_category = categories(:drills)
    @inactive_category = categories(:inactive_category)
    @product = products(:professional_drill)
  end

  # INDEX tests
  test "index returns root categories" do
    get api_v1_categories_url, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal "success", json["status"]
    assert json["data"].is_a?(Array)

    # Should only include active root categories
    category_names = json["data"].map { |c| c["name"] }
    assert_includes category_names, "Power Tools"
    refute_includes category_names, "Inactive Category"
  end

  test "index includes children in response" do
    get api_v1_categories_url, as: :json

    json = JSON.parse(response.body)
    root = json["data"].find { |c| c["name"] == "Power Tools" }

    assert root["children"].present?
    assert_equal "Drills", root["children"].first["name"]
  end

  # SHOW tests
  test "show returns single category" do
    get api_v1_category_url(@root_category), as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal "Power Tools", json["data"]["name"]
    assert_equal "power-tools", json["data"]["slug"]
    assert json["data"]["children"].present?
  end

  test "show returns 404 for inactive category" do
    get api_v1_category_url(@inactive_category), as: :json

    assert_response :not_found
    json = JSON.parse(response.body)
    assert_equal "Not Found", json["error"]
  end

  test "show returns 404 for non-existent category" do
    get api_v1_category_url(99999), as: :json

    assert_response :not_found
  end

  test "show includes ancestors for child category" do
    get api_v1_category_url(@child_category), as: :json

    json = JSON.parse(response.body)
    assert json["data"]["ancestors"].present?
    assert_equal "Power Tools", json["data"]["ancestors"].first["name"]
  end

  # PRODUCTS tests
  test "products returns products in category" do
    get products_api_v1_category_url(@child_category), as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal "success", json["status"]
    assert json["data"].length >= 1
    product_names = json["data"].map { |p| p["name"] }
    assert_includes product_names, "Professional Drill"
  end

  test "products returns products from subcategories" do
    # Request products from parent category
    get products_api_v1_category_url(@root_category), as: :json

    json = JSON.parse(response.body)

    # Should include products from child categories
    assert json["data"].length >= 1
  end

  test "products includes pagination meta" do
    get products_api_v1_category_url(@child_category), as: :json

    json = JSON.parse(response.body)

    assert json["meta"].present?
    assert_equal 1, json["meta"]["current_page"]
  end

  # TREE tests
  test "tree returns full category tree" do
    get tree_api_v1_categories_url, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert json["data"].is_a?(Array)
    root = json["data"].find { |c| c["name"] == "Power Tools" }
    assert root.present?
    assert root["children"].present?
  end

  # FEATURED tests
  test "featured returns categories" do
    get featured_api_v1_categories_url, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert json["data"].is_a?(Array)
  end

  test "featured uses site setting when available" do
    SiteSetting.find_or_create_by!(key: "featured_categories") do |s|
      s.category = "sections"
      s.is_public = true
      s.value = [ @root_category.id ]
    end.update!(value: [ @root_category.id ])

    get featured_api_v1_categories_url, as: :json

    json = JSON.parse(response.body)
    assert json["data"].length >= 1
    category_names = json["data"].map { |c| c["name"] }
    assert_includes category_names, "Power Tools"
  end
end
