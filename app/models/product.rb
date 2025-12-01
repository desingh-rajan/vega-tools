class Product < ApplicationRecord
  # Associations
  belongs_to :category, optional: true  # optional for uncategorized products

  # Active Storage for product images
  has_many_attached :images

  # Validations
  validates :name, presence: true
  validates :sku, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :discounted_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :discounted_price_less_than_price

  # Auto-generate slug from name
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  # Scopes
  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }
  scope :by_category, ->(category_id) { where(category_id: category_id) }
  scope :by_brand, ->(brand) { where(brand: brand) }
  scope :uncategorized, -> { where(category_id: nil) }
  scope :ordered, -> { order(created_at: :desc) }
  scope :price_between, ->(min, max) { where(price: min..max) }

  # Calculate discount percentage
  def discount_percentage
    return 0 unless discounted_price.present? && price.present? && price > 0
    ((price - discounted_price) / price * 100).round
  end

  # Effective price (discounted if available)
  def effective_price
    discounted_price.presence || price
  end

  # Check if on sale
  def on_sale?
    discounted_price.present? && discounted_price < price
  end

  # For Ransack search (Active Admin)
  def self.ransackable_attributes(auth_object = nil)
    %w[name slug sku description price discounted_price brand published category_id created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[category images_attachments]
  end

  # Unique brands for filter dropdowns
  def self.available_brands
    where.not(brand: [ nil, "" ]).distinct.pluck(:brand).sort
  end

  private

  def generate_slug
    base_slug = name.parameterize
    slug_candidate = base_slug
    counter = 1

    while Product.exists?(slug: slug_candidate)
      slug_candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = slug_candidate
  end

  def discounted_price_less_than_price
    if discounted_price.present? && price.present? && discounted_price >= price
      errors.add(:discounted_price, "must be less than original price")
    end
  end
end
