class ProductsController < ApplicationController
  before_action :set_site_settings
  before_action :set_product, only: [ :show ]

  # GET /products or /products.json
  def index
    @products = Product.published.includes(:category).ordered

    # Filter by category if provided (include products from child categories)
    if params[:category].present?
      @category = Category.find_by(slug: params[:category])
      if @category
        category_ids = [ @category.id ] + @category.descendants.map(&:id)
        @products = @products.where(category_id: category_ids)
      end
    end

    # Filter by brand if provided
    @products = @products.by_brand(params[:brand]) if params[:brand].present?

    # Search
    if params[:q].present?
      search_term = "%#{params[:q]}%"
      @products = @products.where("name ILIKE :q OR description ILIKE :q OR brand ILIKE :q", q: search_term)
    end

    # Get all root categories with products for sidebar/filter
    @categories = Category.roots.active.ordered
    @brands = Product.available_brands

    # Group products by category for Netflix-style display (only for HTML)
    @products_by_category = build_products_by_category

    respond_to do |format|
      format.html
      format.json { render json: @products, include: [ :category ], methods: [ :effective_price, :on_sale?, :discount_percentage ] }
    end
  end

  # GET /products/:slug or /products/:slug.json
  def show
    @related_products = @product.category&.products&.published
      &.where&.not(id: @product.id)
      &.limit(4) || []

    respond_to do |format|
      format.html
      format.json { render json: @product, include: [ :category ], methods: [ :effective_price, :on_sale?, :discount_percentage ] }
    end
  end

  # GET /products/search.json
  def search
    query = params[:q].to_s.strip
    @products = Product.published
      .where("name ILIKE :q OR description ILIKE :q OR sku ILIKE :q OR brand ILIKE :q", q: "%#{query}%")
      .includes(:category)
      .limit(20)

    respond_to do |format|
      format.html { redirect_to products_path(q: query) }
      format.json { render json: @products }
    end
  end

  # GET /products/featured.json
  def featured
    @products = Product.published.includes(:category).limit(8)

    respond_to do |format|
      format.json { render json: @products }
    end
  end

  # GET /products/brands.json
  def brands
    respond_to do |format|
      format.json { render json: Product.available_brands }
    end
  end

  private

  def set_product
    @product = Product.published.includes(:category).find_by!(slug: params[:slug])
  end

  def set_site_settings
    @site_info = SiteSetting.value_for("site_info")
    @contact_info = SiteSetting.value_for("contact_info")
    @social_links = SiteSetting.value_for("social_links")
  end

  def build_products_by_category
    return {} if params[:q].present? || params[:category].present? || params[:brand].present?

    Category.active.ordered
      .joins(:products)
      .where(products: { published: true })
      .distinct
      .includes(:products)
      .each_with_object({}) do |category, hash|
        products = category.products.published.limit(8)
        hash[category] = products if products.any?
      end
  end
end
