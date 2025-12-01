class Category < ApplicationRecord
  # Self-referential association for subcategories
  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: :parent_id, dependent: :destroy

  # Products - nullify so products become "uncategorized" when category deleted
  has_many :products, dependent: :nullify

  # Active Storage for category icon/image
  has_one_attached :icon_image

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  # Auto-generate slug from name
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  # Scopes
  scope :roots, -> { where(parent_id: nil) }
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, name: :asc) }
  scope :with_children, -> { includes(:children) }

  # Get all ancestors (parent, grandparent, etc.)
  def ancestors
    parent ? [ parent ] + parent.ancestors : []
  end

  # Get full path: "Power Tools > Drills > Cordless"
  def full_path
    (ancestors.reverse + [ self ]).map(&:name).join(" > ")
  end

  # Depth level (0 = root, 1 = child, 2 = grandchild, etc.)
  def depth
    ancestors.count
  end

  # All descendants (children, grandchildren, etc.)
  def descendants
    children.flat_map { |child| [ child ] + child.descendants }
  end

  # All products including from descendants
  def all_products
    Product.where(category_id: [ id ] + descendants.map(&:id))
  end

  # For Ransack search (Active Admin)
  def self.ransackable_attributes(auth_object = nil)
    %w[name slug description position parent_id created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[parent children products]
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
