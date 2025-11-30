# Vega Tools - E-commerce Implementation Progress

**GitHub Issue:** https://github.com/desingh-rajan/vega-tools/issues/12
**Feature Branch:** `feature/ecommerce-foundation`

## Current State: Phase 1 - Gemfile Updated ✅

### What's Done
- [x] Created GitHub issue #12 with full checklist
- [x] Updated Gemfile with required gems:
  - `bcrypt` (uncommented)
  - `devise`
  - `omniauth-google-oauth2`
  - `omniauth-facebook`
  - `omniauth-rails_csrf_protection`
  - `activeadmin` (~> 3.4)

### Next Steps (Run These Commands)

```bash
# 1. Install gems
bundle install

# 2. Install Devise
rails generate devise:install
rails generate devise User

# 3. Add role and OAuth fields to User migration (edit the generated migration)
# Add these columns:
#   t.integer :role, default: 0, null: false
#   t.string :provider
#   t.string :uid
#   t.string :avatar_url
#   t.string :name

# 4. Install Active Admin (use existing User model)
rails generate active_admin:install --use_existing_user

# 5. Generate models
rails generate model Category name:string slug:string description:text icon:string position:integer parent_id:integer:index
rails generate model Product name:string slug:string sku:string description:text price:decimal discounted_price:decimal brand:string specifications:jsonb published:boolean category:references

# 6. Generate SiteSetting (singleton)
rails generate model SiteSetting site_name:string tagline:string hero_title:string hero_subtitle:string about_text:text address:text phone:string email:string store_hours:text google_maps_url:string stats:jsonb about_features:jsonb social_links:jsonb

# 7. Run migrations
rails db:migrate

# 8. Set up Active Storage (if not already done)
rails active_storage:install
rails db:migrate
```

### User Model Should Look Like

```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2, :facebook]

  enum :role, { user: 0, admin: 1, super_admin: 2 }

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      user.avatar_url = auth.info.image
    end
  end
end
```

### Category Model

```ruby
# app/models/category.rb
class Category < ApplicationRecord
  belongs_to :parent, class_name: "Category", optional: true
  has_many :subcategories, class_name: "Category", foreign_key: :parent_id, dependent: :destroy
  has_many :products, dependent: :nullify
  has_one_attached :icon_image

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  scope :root_categories, -> { where(parent_id: nil) }
  scope :ordered, -> { order(position: :asc, name: :asc) }

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
```

### Product Model

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  belongs_to :category
  has_many_attached :images

  validates :name, :sku, :price, presence: true
  validates :sku, uniqueness: true

  scope :published, -> { where(published: true) }
  scope :by_category, ->(cat_id) { where(category_id: cat_id) }

  # For Ransack search (comes with Active Admin)
  def self.ransackable_attributes(auth_object = nil)
    %w[name sku brand description price]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[category]
  end
end
```

### SiteSetting Model (Singleton)

```ruby
# app/models/site_setting.rb
class SiteSetting < ApplicationRecord
  has_one_attached :logo
  has_many_attached :carousel_images

  def self.instance
    first_or_create!(
      site_name: "Vega Tools & Hardwares",
      tagline: "Building your dreams with quality tools",
      hero_title: "Dindigul's #1 Tool Store",
      hero_subtitle: "Premium Tools, Trusted Service"
    )
  end
end
```

### Categories to Seed

```ruby
# db/seeds.rb
categories = [
  { name: "PPE Safety Equipment", icon: "🦺", position: 1 },
  { name: "Cordless Tools", icon: "🔋", position: 2 },
  { name: "Drills", icon: "⚡", position: 3 },
  { name: "Core Drill", icon: "⚙️", position: 4 },
  { name: "Construction Tools", icon: "🔨", position: 5 },
  { name: "Chemical Anchors", icon: "🧪", position: 6 },
  { name: "Metal Working Tools", icon: "⚡", position: 7 },
  { name: "Measuring Tools", icon: "📏", position: 8 },
  { name: "Miscellaneous", icon: "🛠️", position: 9 },
  { name: "Welding Inverters", icon: "🔥", position: 10 }
]

categories.each do |cat|
  Category.find_or_create_by!(name: cat[:name]) do |c|
    c.slug = cat[:name].parameterize
    c.icon = cat[:icon]
    c.position = cat[:position]
  end
end

# Create super_admin
User.find_or_create_by!(email: "admin@vegatools.in") do |u|
  u.password = "changeme123"
  u.role = :super_admin
  u.name = "Super Admin"
end

# Create site settings
SiteSetting.instance
```

### Files to Create After Models

1. `app/admin/users.rb` - Active Admin user management
2. `app/admin/categories.rb` - Category CRUD
3. `app/admin/products.rb` - Product CRUD
4. `app/admin/site_settings.rb` - Site configuration
5. `app/controllers/products_controller.rb` - Public catalog
6. `app/controllers/categories_controller.rb` - Category browsing
7. `app/controllers/users/omniauth_callbacks_controller.rb` - OAuth handling
8. `config/initializers/devise.rb` - Add OmniAuth config
9. Update `config/routes.rb` with all routes
10. Update `app/views/pages/home.html.erb` to use SiteSetting

### OAuth Setup Required

Create OAuth credentials at:
- Google: https://console.cloud.google.com/apis/credentials
- Facebook: https://developers.facebook.com/apps/

Add to `config/credentials.yml.enc`:
```yaml
google:
  client_id: YOUR_CLIENT_ID
  client_secret: YOUR_CLIENT_SECRET

facebook:
  app_id: YOUR_APP_ID
  app_secret: YOUR_APP_SECRET
```

---

**Last Updated:** 2025-11-30
**Status:** Gemfile updated, ready for `bundle install`
