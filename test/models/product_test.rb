require "test_helper"

class ProductTest < ActiveSupport::TestCase
  setup do
    @category = categories(:power_tools)
    @product = products(:professional_drill)
    @unpublished = products(:unpublished_product)
  end

  # Validations
  test "valid product with required fields" do
    product = Product.new(
      name: "Test Product",
      sku: "TEST-001",
      price: 100,
      category: @category
    )
    assert product.valid?
  end

  test "invalid without name" do
    product = Product.new(sku: "TEST", price: 100)
    assert_not product.valid?
    assert_includes product.errors[:name], "can't be blank"
  end

  test "invalid without sku" do
    product = Product.new(name: "Test", price: 100)
    assert_not product.valid?
    assert_includes product.errors[:sku], "can't be blank"
  end

  test "invalid without price" do
    product = Product.new(name: "Test", sku: "TEST")
    assert_not product.valid?
    assert_includes product.errors[:price], "can't be blank"
  end

  test "invalid with duplicate sku" do
    product = Product.new(name: "Dupe", sku: "DRILL-001", price: 100)
    assert_not product.valid?
    assert_includes product.errors[:sku], "has already been taken"
  end

  test "auto-generates unique slug for duplicate names" do
    # Product model auto-generates unique slugs, doesn't validate uniqueness
    product = Product.create!(name: "Professional Drill", sku: "NEW-001", price: 100, category: @category)
    refute_equal "professional-drill", product.slug  # Should be "professional-drill-1" or similar
  end

  test "invalid with negative price" do
    product = Product.new(name: "Test", sku: "TEST", price: -10)
    assert_not product.valid?
    assert_includes product.errors[:price], "must be greater than or equal to 0"
  end

  test "invalid with discounted_price greater than price" do
    product = Product.new(name: "Test", sku: "TEST", price: 100, discounted_price: 150)
    assert_not product.valid?
    assert_includes product.errors[:discounted_price], "must be less than original price"
  end

  # Slug generation
  test "generates slug from name when blank" do
    product = Product.create!(name: "New Power Tool", sku: "NPT-001", price: 500, category: @category)
    assert_equal "new-power-tool", product.slug
  end

  # Price methods
  test "effective_price returns discounted_price when set" do
    assert_equal 4500, @product.effective_price
  end

  test "effective_price returns price when no discount" do
    product = products(:basic_drill)
    assert_equal product.price, product.effective_price
  end

  test "on_sale? returns true when discounted" do
    assert @product.on_sale?
  end

  test "on_sale? returns false when not discounted" do
    product = products(:basic_drill)
    assert_not product.on_sale?
  end

  test "discount_percentage calculates correctly" do
    # price: 5000, discounted: 4500 = 10% off
    assert_equal 10, @product.discount_percentage
  end

  test "discount_percentage returns 0 when not on sale" do
    product = products(:basic_drill)
    assert_equal 0, product.discount_percentage
  end

  # Scopes
  test "published scope returns only published products" do
    published = Product.published
    assert_includes published, @product
    refute_includes published, @unpublished
  end

  test "on_sale? method returns true for discounted products" do
    # Product model uses on_sale? method, not scope
    assert @product.on_sale?
  end

  test "by_category scope filters by category" do
    by_cat = Product.by_category(@category.id)
    refute_empty by_cat
  end

  test "available_brands returns unique brands" do
    brands = Product.available_brands
    assert_includes brands, "Bosch"
    assert_includes brands, "Stanley"
  end

  # Category association
  test "belongs to category" do
    assert_equal categories(:drills), @product.category
  end

  test "category can be nil" do
    product = Product.new(name: "Orphan", sku: "ORPH-001", price: 100, category: nil)
    assert product.valid?
  end

  # Ransackable (for Active Admin)
  test "ransackable_attributes returns allowed attributes" do
    attrs = Product.ransackable_attributes
    assert_includes attrs, "name"
    assert_includes attrs, "sku"
    assert_includes attrs, "brand"
    assert_includes attrs, "price"
  end

  test "ransackable_associations returns allowed associations" do
    assocs = Product.ransackable_associations
    assert_includes assocs, "category"
  end
end
