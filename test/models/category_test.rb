require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  setup do
    @power_tools = categories(:power_tools)
    @drills = categories(:drills)
    @inactive = categories(:inactive_category)
  end

  # Validations
  test "valid category with required fields" do
    category = Category.new(name: "Test Category", slug: "test-category")
    assert category.valid?
  end

  test "invalid without name" do
    category = Category.new(slug: "test")
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "invalid with duplicate slug" do
    category = Category.new(name: "Power Tools", slug: "power-tools")
    assert_not category.valid?
    assert_includes category.errors[:slug], "has already been taken"
  end

  # Slug generation
  test "generates slug from name when blank" do
    category = Category.create!(name: "Safety Equipment")
    assert_equal "safety-equipment", category.slug
  end

  test "does not overwrite existing slug" do
    category = Category.create!(name: "Safety Equipment", slug: "custom-slug")
    assert_equal "custom-slug", category.slug
  end

  # Self-referential associations
  test "root category has no parent" do
    assert_nil @power_tools.parent
  end

  test "child category has parent" do
    assert_equal @power_tools, @drills.parent
  end

  test "parent has children" do
    assert_includes @power_tools.children, @drills
  end

  # Tree traversal methods
  test "ancestors returns parent chain" do
    grandchild = Category.create!(name: "Cordless", parent: @drills)
    assert_equal [ @drills, @power_tools ], grandchild.ancestors
  end

  test "ancestors returns empty array for root" do
    assert_equal [], @power_tools.ancestors
  end

  test "full_path returns ancestor chain as string" do
    grandchild = Category.create!(name: "Cordless", parent: @drills)
    assert_equal "Power Tools > Drills > Cordless", grandchild.full_path
  end

  test "depth returns correct level" do
    assert_equal 0, @power_tools.depth
    assert_equal 1, @drills.depth

    grandchild = Category.create!(name: "Cordless", parent: @drills)
    assert_equal 2, grandchild.depth
  end

  test "descendants returns all children recursively" do
    grandchild = Category.create!(name: "Cordless", parent: @drills)
    descendants = @power_tools.descendants

    assert_includes descendants, @drills
    assert_includes descendants, grandchild
  end

  # Scopes
  test "roots scope returns only root categories" do
    roots = Category.roots
    assert_includes roots, @power_tools
    refute_includes roots, @drills
  end

  test "active scope returns only active categories" do
    active = Category.active
    assert_includes active, @power_tools
    refute_includes active, @inactive
  end

  test "ordered scope sorts by position then name" do
    cat_a = Category.create!(name: "AAA", position: 2)
    cat_b = Category.create!(name: "BBB", position: 1)

    ordered = Category.ordered
    assert ordered.index(cat_b) < ordered.index(cat_a)
  end

  # Dependent destroy
  test "destroying parent destroys children" do
    child = @drills
    child_id = child.id
    @power_tools.destroy!

    assert_nil Category.find_by(id: child_id)
  end

  # Product association
  test "all_products includes products from descendants" do
    product1 = Product.create!(name: "Drill 1", sku: "D1", price: 100, category: @power_tools, published: true)
    product2 = Product.create!(name: "Drill 2", sku: "D2", price: 200, category: @drills, published: true)

    all_products = @power_tools.all_products
    assert_includes all_products, product1
    assert_includes all_products, product2
  end

  # Ransackable (for Active Admin)
  test "ransackable_attributes returns allowed attributes" do
    attrs = Category.ransackable_attributes
    assert_includes attrs, "name"
    assert_includes attrs, "slug"
    assert_includes attrs, "parent_id"
  end
end
