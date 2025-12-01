require "test_helper"

class Api::V1::ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:power_tools)
    @product1 = products(:professional_drill)
    @product2 = products(:basic_drill)
    @unpublished_product = products(:unpublished_product)
  end

  # INDEX tests
  test "index returns published products" do
    get api_v1_products_url, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal "success", json["status"]
    assert json["data"].is_a?(Array)
    assert json["data"].length >= 2

    # Should not include unpublished
    names = json["data"].map { |p| p["name"] }
    refute_includes names, "Unpublished Product"
  end

  test "index includes pagination meta" do
    get api_v1_products_url, as: :json

    json = JSON.parse(response.body)

    assert json["meta"].present?
    assert_equal 1, json["meta"]["current_page"]
    assert json["meta"]["filters"].present?
  end

  test "index filters by category" do
    other_category = Category.create!(name: "Other Cat", slug: "other-cat-unique", active: true)

    get api_v1_products_url(category_id: other_category.id), as: :json

    json = JSON.parse(response.body)
    assert_equal 0, json["data"].length
  end

  test "index filters by brand" do
    get api_v1_products_url(brand: "Bosch"), as: :json

    json = JSON.parse(response.body)
    assert json["data"].length >= 1
    assert_equal "Professional Drill", json["data"].first["name"]
  end

  test "index filters by price range" do
    get api_v1_products_url(min_price: 3000, max_price: 6000), as: :json

    json = JSON.parse(response.body)
    # Professional Drill has discounted_price of 4500
    assert json["data"].length >= 1
  end

  test "index filters by on_sale" do
    get api_v1_products_url(on_sale: "true"), as: :json

    json = JSON.parse(response.body)
    assert json["data"].length >= 1
    product_names = json["data"].map { |p| p["name"] }
    assert_includes product_names, "Professional Drill"
  end

  test "index sorts by price_asc" do
    get api_v1_products_url(sort: "price_asc"), as: :json

    json = JSON.parse(response.body)
    # Basic drill (2000) should come before Professional drill (4500 effective)
    prices = json["data"].map { |p| p["effective_price"] }
    assert_equal prices.sort, prices
  end

  test "index sorts by price_desc" do
    get api_v1_products_url(sort: "price_desc"), as: :json

    json = JSON.parse(response.body)
    prices = json["data"].map { |p| p["effective_price"] }
    assert_equal prices.sort.reverse, prices
  end

  test "index supports pagination" do
    get api_v1_products_url(page: 1, per_page: 1), as: :json

    json = JSON.parse(response.body)
    assert_equal 1, json["data"].length
    assert json["meta"]["total_pages"] >= 1
  end

  # SHOW tests
  test "show returns single product with full details" do
    get api_v1_product_url(@product1), as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal "Professional Drill", json["data"]["name"]
    assert_equal "professional-drill", json["data"]["slug"]
    assert_equal "DRILL-001", json["data"]["sku"]
    assert_equal "Bosch", json["data"]["brand"]
    assert_equal 5000.0, json["data"]["price"]
    assert_equal 4500.0, json["data"]["discounted_price"]
    assert_equal 4500.0, json["data"]["effective_price"]
    assert json["data"]["on_sale"]
    assert json["data"]["category"].present?
  end

  test "show returns 404 for unpublished product" do
    get api_v1_product_url(@unpublished_product), as: :json

    assert_response :not_found
  end

  test "show returns 404 for non-existent product" do
    get api_v1_product_url(99999), as: :json

    assert_response :not_found
  end

  # SEARCH tests
  test "search finds products by name" do
    get search_api_v1_products_url(q: "Professional"), as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert json["data"].length >= 1
    product_names = json["data"].map { |p| p["name"] }
    assert_includes product_names, "Professional Drill"
  end

  test "search finds products by brand" do
    get search_api_v1_products_url(q: "Bosch"), as: :json

    json = JSON.parse(response.body)
    assert json["data"].length >= 1
  end

  test "search finds products by SKU" do
    get search_api_v1_products_url(q: "DRILL-002"), as: :json

    json = JSON.parse(response.body)
    assert json["data"].length >= 1
    product_names = json["data"].map { |p| p["name"] }
    assert_includes product_names, "Basic Drill"
  end

  test "search returns error without query" do
    get search_api_v1_products_url, as: :json

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_equal "Search query is required", json["error"]
  end

  test "search includes query in meta" do
    get search_api_v1_products_url(q: "drill"), as: :json

    json = JSON.parse(response.body)
    assert_equal "drill", json["meta"]["query"]
  end

  # FEATURED tests
  test "featured returns products" do
    get featured_api_v1_products_url, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert json["data"].is_a?(Array)
  end

  test "featured uses site setting when available" do
    SiteSetting.find_or_create_by!(key: "featured_products") do |s|
      s.category = "sections"
      s.is_public = true
      s.value = [ @product1.id ]
    end.update!(value: [ @product1.id ])

    get featured_api_v1_products_url, as: :json

    json = JSON.parse(response.body)
    assert json["data"].length >= 1
    product_names = json["data"].map { |p| p["name"] }
    assert_includes product_names, "Professional Drill"
  end

  # ON_SALE tests
  test "on_sale returns only discounted products" do
    get on_sale_api_v1_products_url, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert json["data"].length >= 1
    product_names = json["data"].map { |p| p["name"] }
    assert_includes product_names, "Professional Drill"
    # All returned products should be on sale
    json["data"].each { |p| assert p["on_sale"] }
  end

  # BRANDS tests
  test "brands returns list of available brands" do
    get brands_api_v1_products_url, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert json["data"].is_a?(Array)
    assert_includes json["data"], "Bosch"
    assert_includes json["data"], "Stanley"
  end

  # BY_SLUG tests
  test "by_slug finds product by slug" do
    get by_slug_api_v1_products_url(slug: "professional-drill"), as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal "Professional Drill", json["data"]["name"]
  end

  test "by_slug returns 404 for non-existent slug" do
    get by_slug_api_v1_products_url(slug: "non-existent"), as: :json

    assert_response :not_found
  end
end
