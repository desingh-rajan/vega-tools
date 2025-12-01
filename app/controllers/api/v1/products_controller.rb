module Api
  module V1
    class ProductsController < BaseController
      # GET /api/v1/products
      # Returns paginated list of published products
      def index
        products = Product.published.includes(:category).ordered

        # Apply filters
        products = apply_filters(products)

        result = paginate(products)

        render_success(
          result[:items].map { |p| product_json(p) },
          meta: result[:meta].merge(filters: available_filters)
        )
      end

      # GET /api/v1/products/:id
      # Returns a single product with full details
      def show
        product = Product.published.find(params[:id])

        render_success(product_detail_json(product))
      end

      # GET /api/v1/products/search
      # Search products by name, description, brand, SKU
      def search
        query = params[:q].to_s.strip

        if query.blank?
          return render_error("Search query is required", status: :bad_request)
        end

        products = Product.published
                         .where("name LIKE :q OR description LIKE :q OR brand LIKE :q OR sku LIKE :q",
                                q: "%#{query}%")
                         .includes(:category)
                         .ordered

        result = paginate(products)

        render_success(
          result[:items].map { |p| product_json(p) },
          meta: result[:meta].merge(query: query)
        )
      end

      # GET /api/v1/products/featured
      # Returns featured products for homepage
      def featured
        featured_setting = SiteSetting.value_for("featured_products")
        featured_ids = featured_setting.is_a?(Array) ? featured_setting : []

        if featured_ids.present?
          products = Product.published.where(id: featured_ids).includes(:category)
          render_success(products.map { |p| product_json(p) })
        else
          # Fallback: return newest published products
          products = Product.published.includes(:category).order(created_at: :desc).limit(8)
          render_success(products.map { |p| product_json(p) })
        end
      end

      # GET /api/v1/products/on_sale
      # Returns products currently on sale
      def on_sale
        products = Product.published
                         .where("discounted_price IS NOT NULL AND discounted_price < price")
                         .includes(:category)
                         .ordered

        result = paginate(products)

        render_success(
          result[:items].map { |p| product_json(p) },
          meta: result[:meta]
        )
      end

      # GET /api/v1/products/brands
      # Returns list of available brands
      def brands
        brands = Product.published.available_brands
        render_success(brands)
      end

      # GET /api/v1/products/by_slug/:slug
      # Find product by slug (useful for SEO-friendly URLs)
      def by_slug
        product = Product.published.find_by!(slug: params[:slug])
        render_success(product_detail_json(product))
      end

      private

      def apply_filters(products)
        # Filter by category
        if params[:category_id].present?
          category = Category.find(params[:category_id])
          # Get all descendant IDs (children, grandchildren, etc.) plus the category itself
          all_category_ids = [ category.id ] + category.descendants.select(&:active).map(&:id)
          products = products.where(category_id: all_category_ids)
        end

        # Filter by brand
        if params[:brand].present?
          products = products.where(brand: params[:brand])
        end

        # Filter by price range
        if params[:min_price].present?
          products = products.where("COALESCE(discounted_price, price) >= ?", params[:min_price].to_f)
        end
        if params[:max_price].present?
          products = products.where("COALESCE(discounted_price, price) <= ?", params[:max_price].to_f)
        end

        # Filter by sale status
        if params[:on_sale] == "true"
          products = products.where("discounted_price IS NOT NULL AND discounted_price < price")
        end

        # Sort
        case params[:sort]
        when "price_asc"
          products = products.order(Arel.sql("COALESCE(discounted_price, price) ASC"))
        when "price_desc"
          products = products.order(Arel.sql("COALESCE(discounted_price, price) DESC"))
        when "newest"
          products = products.order(created_at: :desc)
        when "name"
          products = products.order(:name)
        end

        products
      end

      def available_filters
        {
          brands: Product.published.available_brands,
          price_range: {
            min: Product.published.minimum(:price)&.to_f || 0,
            max: Product.published.maximum(:price)&.to_f || 0
          },
          sort_options: %w[price_asc price_desc newest name]
        }
      end

      def product_json(product)
        {
          id: product.id,
          name: product.name,
          slug: product.slug,
          sku: product.sku,
          brand: product.brand,
          price: product.price.to_f,
          discounted_price: product.discounted_price&.to_f,
          effective_price: product.effective_price.to_f,
          on_sale: product.on_sale?,
          discount_percentage: product.discount_percentage,
          image_url: product.images.attached? ? url_for(product.images.first) : nil,
          category: product.category ? {
            id: product.category.id,
            name: product.category.name,
            slug: product.category.slug
          } : nil
        }
      end

      def product_detail_json(product)
        {
          id: product.id,
          name: product.name,
          slug: product.slug,
          sku: product.sku,
          brand: product.brand,
          description: product.description,
          price: product.price.to_f,
          discounted_price: product.discounted_price&.to_f,
          effective_price: product.effective_price.to_f,
          on_sale: product.on_sale?,
          discount_percentage: product.discount_percentage,
          specifications: product.specifications,
          images: product.images.attached? ? product.images.map { |img| url_for(img) } : [],
          category: product.category ? {
            id: product.category.id,
            name: product.category.name,
            slug: product.category.slug,
            full_path: product.category.full_path,
            ancestors: product.category.ancestors.map { |a| { id: a.id, name: a.name, slug: a.slug } }
          } : nil,
          created_at: product.created_at,
          updated_at: product.updated_at
        }
      end
    end
  end
end
