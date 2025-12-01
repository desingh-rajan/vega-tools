# Vega Tools - E-commerce Implementation Progress

**GitHub Issue:** <https://github.com/desingh-rajan/vega-tools/issues/12>
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

# 6. Generate SiteSetting (key-value pattern like tstack-kit)
rails generate model SiteSetting key:string:uniq category:string value:jsonb is_system:boolean is_public:boolean description:text updated_by:references

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

### SiteSetting Model (Key-Value Pattern - like tstack-kit)

```ruby
# app/models/site_setting.rb
# Key-value based settings with JSON values (following tstack-kit pattern)
class SiteSetting < ApplicationRecord
  CATEGORIES = %w[general appearance contact sections features].freeze
  
  SYSTEM_KEYS = %w[
    site_info contact_info hero_section stats_section 
    about_section social_links theme_config
  ].freeze

  belongs_to :updated_by, class_name: "User", optional: true
  has_one_attached :logo
  has_many_attached :images  # For carousel, etc.

  validates :key, presence: true, uniqueness: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }

  scope :public_settings, -> { where(is_public: true) }
  scope :by_category, ->(cat) { where(category: cat) }

  # Get by key with auto-seed for system settings
  def self.get(key)
    find_by(key: key) || (SYSTEM_KEYS.include?(key) ? seed_system_setting(key) : nil)
  end

  def self.value_for(key)
    get(key)&.value || {}
  end

  private_class_method def self.seed_system_setting(key)
    defaults = DEFAULTS[key]
    return nil unless defaults
    
    create!(key: key, **defaults, is_system: true)
  end

  DEFAULTS = {
    "site_info" => {
      category: "general", is_public: true,
      description: "Basic site information",
      value: {
        "site_name" => "Vega Tools & Hardwares",
        "tagline" => "Building your dreams with quality tools",
        "description" => "Dindigul's #1 Tool Store - Authorized POLYMAK dealer"
      }
    },
    "contact_info" => {
      category: "contact", is_public: true,
      description: "Contact details",
      value: {
        "phone" => "095007 16588",
        "email" => "contact@vegatools.in",
        "address" => "No. 583/4B, Dindigul - Trichy Bypass Road, Rajakkapatti, EB Colony, Dindigul District, Tamil Nadu 624004",
        "google_maps_url" => "https://maps.app.goo.gl/eQ6RmoxqpgrFpksp7",
        "store_hours" => "Monday - Saturday: 9 AM - 8 PM"
      }
    },
    "hero_section" => {
      category: "sections", is_public: true,
      description: "Hero section content",
      value: {
        "title_line1" => "Dindigul's #1 Tool Store",
        "title_line2" => "Premium Tools, Trusted Service",
        "subtitle" => "Authorized POLYMAK dealer in Dindigul | Professional power tools, precision hand tools & complete safety solutions"
      }
    },
    "stats_section" => {
      category: "sections", is_public: true,
      description: "Stats displayed on landing page",
      value: {
        "stat1" => { "number" => "4.8⭐", "label" => "Google Rating" },
        "stat2" => { "number" => "500+", "label" => "Power Tools" },
        "stat3" => { "number" => "100+", "label" => "Genuine Products" }
      }
    },
    "about_section" => {
      category: "sections", is_public: true,
      description: "About section content",
      value: {
        "title" => "About Vega Tools and Hardwares",
        "paragraphs" => [
          "Located on Trichy Road in Dindigul District, Tamil Nadu, Vega Tools and Hardwares is your trusted partner for professional power tools and safety equipment.",
          "With a 4.8-star rating and hundreds of satisfied customers, we serve contractors, builders, and industrial clients across Dindigul and surrounding regions."
        ],
        "features" => [
          "Authorized POLYMAK Dealer",
          "Complete Safety Equipment",
          "Professional Grade Tools",
          "Expert Technical Support"
        ]
      }
    },
    "social_links" => {
      category: "contact", is_public: true,
      description: "Social media links",
      value: {
        "whatsapp" => "https://wa.me/919500716588",
        "instagram" => "",
        "facebook" => ""
      }
    },
    "theme_config" => {
      category: "appearance", is_public: true,
      description: "Theme and appearance settings",
      value: {
        "primary_color" => "#f59e0b",
        "secondary_color" => "#1e293b",
        "font_family" => "Inter, system-ui, sans-serif"
      }
    }
  }.freeze
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

# Seed all system site settings
SiteSetting::SYSTEM_KEYS.each { |key| SiteSetting.get(key) }
```

### Active Admin for Site Settings

```ruby
# app/admin/site_settings.rb
ActiveAdmin.register SiteSetting do
  menu label: "Site Settings", priority: 1

  permit_params :key, :category, :value, :is_public, :description

  index do
    selectable_column
    column :key
    column :category
    column :is_system
    column :is_public
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :key
      row :category
      row :is_system
      row :is_public
      row :description
      row :value do |setting|
        pre JSON.pretty_generate(setting.value)
      end
      row :updated_at
      row :updated_by
    end
  end

  form do |f|
    f.inputs do
      f.input :key, input_html: { disabled: f.object.is_system? }
      f.input :category, as: :select, collection: SiteSetting::CATEGORIES
      f.input :value, as: :text, input_html: { rows: 15 }, 
              hint: "JSON format - be careful with syntax!"
      f.input :is_public
      f.input :description
    end
    f.actions
  end

  # Custom action to reset system setting to defaults
  member_action :reset, method: :post do
    setting = SiteSetting.find(params[:id])
    if setting.is_system? && SiteSetting::DEFAULTS[setting.key]
      setting.update!(value: SiteSetting::DEFAULTS[setting.key][:value])
      redirect_to admin_site_setting_path(setting), notice: "Reset to defaults!"
    else
      redirect_to admin_site_setting_path(setting), alert: "Cannot reset non-system setting"
    end
  end

  action_item :reset, only: :show do
    if resource.is_system?
      link_to "Reset to Defaults", reset_admin_site_setting_path(resource), method: :post,
              data: { confirm: "Reset this setting to default values?" }
    end
  end
end
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

- Google: <https://console.cloud.google.com/apis/credentials>
- Facebook: <https://developers.facebook.com/apps/>

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
