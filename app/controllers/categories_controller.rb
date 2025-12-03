class CategoriesController < ApplicationController
  before_action :set_site_settings
  before_action :set_category, only: [ :show, :products ]

  # GET /categories or /categories.json
  def index
    @categories = Category.roots.active.ordered.includes(:children, :products)

    respond_to do |format|
      format.html
      format.json { render json: @categories, include: [ :children ], methods: [ :full_path ] }
    end
  end

  # GET /categories/:slug or /categories/:slug.json
  def show
    @products = @category.all_products.published.includes(:category).ordered
    @subcategories = @category.children.active.ordered
    @breadcrumbs = @category.ancestors.reverse + [ @category ]

    respond_to do |format|
      format.html
      format.json { render json: @category, include: [ :children, :products ], methods: [ :full_path, :depth ] }
    end
  end

  # GET /categories/:slug/products.json
  def products
    @products = @category.all_products.published.includes(:category).ordered

    respond_to do |format|
      format.html { redirect_to category_path(@category) }
      format.json { render json: @products, include: [ :category ] }
    end
  end

  # GET /categories/tree.json
  def tree
    @categories = Category.roots.active.ordered.includes(children: :children)

    respond_to do |format|
      format.json { render json: build_tree(@categories) }
    end
  end

  # GET /categories/featured.json
  def featured
    @categories = Category.roots.active.ordered.limit(6)

    respond_to do |format|
      format.json { render json: @categories }
    end
  end

  private

  def set_category
    @category = Category.includes(:children, :parent).find_by!(slug: params[:slug])
  end

  def set_site_settings
    @site_info = SiteSetting.value_for("site_info")
    @contact_info = SiteSetting.value_for("contact_info")
    @social_links = SiteSetting.value_for("social_links")
  end

  def build_tree(categories)
    categories.map do |cat|
      {
        id: cat.id,
        name: cat.name,
        slug: cat.slug,
        icon: cat.icon,
        children: build_tree(cat.children.active.ordered)
      }
    end
  end
end
