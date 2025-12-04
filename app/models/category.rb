class Category < ApplicationRecord
  include HasProcessedImages

  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: :parent_id, dependent: :destroy
  has_many :products, dependent: :nullify

  has_one_attached :icon_image, service: Rails.env.production? ? :amazon_public : (Rails.env.development? ? :amazon_dev : :local)
  has_processed_images :icon_image

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  scope :roots, -> { where(parent_id: nil) }
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, name: :asc) }
  scope :with_children, -> { includes(:children) }

  def ancestors
    parent ? [ parent ] + parent.ancestors : []
  end

  def full_path
    (ancestors.reverse + [ self ]).map(&:name).join(" > ")
  end

  def depth
    ancestors.count
  end

  def descendants
    children.flat_map { |child| [ child ] + child.descendants }
  end

  def all_products
    Product.where(category_id: [ id ] + descendants.map(&:id))
  end

  class << self
    def ransackable_attributes(_auth_object = nil)
      %w[name slug description position parent_id created_at]
    end

    def ransackable_associations(_auth_object = nil)
      %w[parent children products]
    end
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
