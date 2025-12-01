# TStack Rails Kit - Starter Template Ideas

> **Purpose:** Capture all patterns, decisions, and code from vega-tools to create a reusable Rails 8 starter kit similar to tstack-kit (TypeScript version).

**Source Project:** vega-tools
**Target Project:** tstack-rails-kit (future)
**Rails Version:** 8.1.1
**Last Updated:** 2025-12-02

---

## 🚨 CRITICAL: ActiveAdmin + Propshaft Setup

> **This section documents a painful issue that took hours to debug. Follow these steps exactly to avoid CSS conflicts.**

### The Problem

ActiveAdmin 3.x with Rails 8 + Propshaft causes **CSS pollution** on public pages:

- All links get ugly underlines
- Link colors change to blue
- Font styles get overridden
- Your beautiful frontend becomes a mess

### Why It Happens

1. ActiveAdmin ships SCSS files (not pre-compiled CSS)
2. You might add `dartsass-rails` to compile them
3. Dartsass compiles to `app/assets/builds/active_admin.css`
4. **Propshaft loads ALL CSS from `app/assets/builds/` on EVERY page**
5. ActiveAdmin's normalize reset (`text-decoration: underline` on links) breaks your frontend

### The Correct Setup

**1. Do NOT use `dartsass-rails`**

```ruby
# Gemfile - DON'T add this!
# gem "dartsass-rails"
```

**2. Pre-compile ActiveAdmin CSS once to vendor folder**

```bash
mkdir -p vendor/assets/stylesheets

aa_gem_path=$(bundle info activeadmin --path)
sass --load-path="$aa_gem_path/app/assets/stylesheets" \
     --quiet-deps \
     - <<'EOF' > vendor/assets/stylesheets/active_admin.css
@import "active_admin/mixins";
@import "active_admin/base";
EOF
```

**3. Add vendor path to Propshaft**

```ruby
# config/initializers/assets.rb
Rails.application.config.assets.paths << Rails.root.join("vendor", "assets", "stylesheets")
```

**4. Commit the compiled CSS**

```bash
git add vendor/assets/stylesheets/active_admin.css
```

### Why This Works

- `vendor/assets/` is in Propshaft's load path for asset resolution
- BUT it's NOT in `app/assets/builds/` which gets bundled into `:app`
- ActiveAdmin's engine finds `active_admin.css` when rendering admin pages
- Your public frontend only loads YOUR CSS from `app/assets/stylesheets/`

### File Structure

```
app/assets/
├── builds/           # DO NOT put active_admin.css here!
│   └── .keep
├── stylesheets/
│   ├── application.css
│   └── pages.css     # Your frontend styles
vendor/assets/
└── stylesheets/
    └── active_admin.css  # Pre-compiled, only loaded by admin
```

---

## 🎯 Core Philosophy

1. **One User Model for Everything** - No separate AdminUser, just roles
2. **Self-Referential Categories** - Infinite nesting with one table
3. **Key-Value Site Settings** - Flexible JSON-based configuration
4. **API-First Design** - JSON endpoints for mobile/Flutter apps
5. **100% Test Coverage** - All public APIs and admin endpoints tested
6. **Propshaft-Safe ActiveAdmin** - Pre-compiled CSS in vendor folder

---

## 📦 Gem Stack (Gemfile)

```ruby
# Core Rails 8
gem "rails", "~> 8.1.1"
gem "propshaft"           # Modern asset pipeline
gem "sqlite3", ">= 2.1"   # Dev DB (PostgreSQL for prod)
gem "puma", ">= 5.0"
gem "importmap-rails"     # No Node.js required
gem "turbo-rails"         # Hotwire SPA-like
gem "stimulus-rails"      # Hotwire JS framework
gem "jbuilder"            # JSON APIs

# Authentication & Authorization
gem "bcrypt", "~> 3.1.7"
gem "devise"
gem "omniauth-google-oauth2"
gem "omniauth-facebook"
gem "omniauth-rails_csrf_protection"

# Admin Panel
gem "activeadmin", "~> 3.4"  # Tailwind-based admin

# API Authentication (for mobile apps)
gem "devise-jwt"  # TODO: Add this for JWT tokens

# Rails 8 Solid Stack
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Image Processing
gem "image_processing", "~> 1.2"
```

---

## 👤 User Model Pattern

### Single User with Roles

```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2, :facebook]

  # Roles enum - single source of truth
  enum :role, { user: 0, admin: 1, super_admin: 2 }

  # Validations - email OR phone required
  validates :role, presence: true
  validates :email, uniqueness: { allow_blank: true }
  validates :phone_number, uniqueness: { allow_blank: true }
  validate :email_or_phone_present

  # Virtual attribute for email/phone login
  attr_accessor :login

  # Scopes
  scope :admins, -> { where(role: [:admin, :super_admin]) }

  # Override Devise for email OR phone login
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions.to_h).where(
        "LOWER(email) = :value OR phone_number = :value",
        value: login.downcase.strip
      ).first
    elsif conditions.key?(:email) || conditions.key?(:phone_number)
      where(conditions.to_h).first
    end
  end

  # OmniAuth handler
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      user.avatar_url = auth.info.image
      user.role = :user
    end
  end

  # Role helpers
  def admin_access?
    admin? || super_admin?
  end

  # Allow email-only or phone-only registration
  def email_required?
    false
  end

  private

  def email_or_phone_present
    if email.blank? && phone_number.blank?
      errors.add(:base, "Email or phone number must be provided")
    end
  end
end
```

### User Migration

```ruby
class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      ## Devise fields
      t.string :email, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at

      ## Custom fields
      t.string :name
      t.integer :role, default: 0, null: false
      t.string :provider
      t.string :uid
      t.string :avatar_url
      t.string :phone_number
      t.string :country_code, default: "+91"

      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :phone_number, unique: true
    add_index :users, [:provider, :uid], unique: true
  end
end
```

---

## 🗂️ Self-Referential Categories Pattern

### The Power of One Table

Instead of `categories` → `subcategories` → `groups` (3 tables), use ONE table with `parent_id`:

```ruby
# app/models/category.rb
class Category < ApplicationRecord
  # Self-referential: parent/children
  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: :parent_id, dependent: :destroy

  # Products - nullify to keep products when category deleted
  has_many :products, dependent: :nullify

  # Active Storage
  has_one_attached :icon_image

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  # Scopes
  scope :roots, -> { where(parent_id: nil) }
  scope :ordered, -> { order(position: :asc, name: :asc) }

  # Tree traversal methods
  def ancestors
    parent ? [parent] + parent.ancestors : []
  end

  def full_path
    (ancestors.reverse + [self]).map(&:name).join(" > ")
  end

  def depth
    ancestors.count
  end

  def descendants
    children.flat_map { |child| [child] + child.descendants }
  end

  def all_products
    Product.where(category_id: [id] + descendants.map(&:id))
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
```

### Category Migration

```ruby
class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug
      t.text :description
      t.string :icon
      t.integer :position, default: 0
      t.integer :parent_id, index: true

      t.timestamps
    end

    add_index :categories, :slug, unique: true
    add_foreign_key :categories, :categories, column: :parent_id
  end
end
```

### Visual Example

```
categories table:
┌────┬──────────────────┬───────────┐
│ id │ name             │ parent_id │
├────┼──────────────────┼───────────┤
│ 1  │ Power Tools      │ NULL      │  ← Root
│ 2  │ Drills           │ 1         │  ← Child of 1
│ 3  │ Cordless Drills  │ 2         │  ← Child of 2
│ 4  │ Safety Equipment │ NULL      │  ← Another Root
└────┴──────────────────┴───────────┘

Usage:
  category = Category.find(3)
  category.full_path  # => "Power Tools > Drills > Cordless Drills"
  category.ancestors  # => [Drills, Power Tools]
  category.depth      # => 2
```

---

## ⚙️ Site Settings Pattern (Key-Value JSON)

### Model

```ruby
# app/models/site_setting.rb
class SiteSetting < ApplicationRecord
  CATEGORIES = %w[general appearance contact sections features].freeze
  
  SYSTEM_KEYS = %w[
    site_info contact_info hero_section stats_section
    about_section social_links theme_config
  ].freeze

  belongs_to :updated_by, class_name: "User", optional: true
  has_one_attached :logo
  has_many_attached :images

  validates :key, presence: true, uniqueness: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }

  scope :public_settings, -> { where(is_public: true) }
  scope :by_category, ->(cat) { where(category: cat) }

  # Auto-seed system settings on first access
  def self.get(key)
    find_by(key: key) || (SYSTEM_KEYS.include?(key.to_s) ? seed_system_setting(key.to_s) : nil)
  end

  def self.value_for(key)
    get(key)&.value || {}
  end

  private

  def self.seed_system_setting(key)
    defaults = DEFAULTS[key]
    return nil unless defaults
    create!(key: key, **defaults, is_system: true)
  end

  DEFAULTS = {
    "site_info" => {
      category: "general",
      is_public: true,
      description: "Basic site information",
      value: {
        "site_name" => "My App",
        "tagline" => "Building amazing things"
      }
    }
    # ... more defaults
  }.freeze
end
```

### Migration

```ruby
class CreateSiteSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :site_settings do |t|
      t.string :key, null: false
      t.string :category, null: false
      t.json :value, null: false, default: {}
      t.boolean :is_system, null: false, default: false
      t.boolean :is_public, null: false, default: false
      t.text :description
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :site_settings, :key, unique: true
    add_index :site_settings, :category
  end
end
```

---

## 🔐 Active Admin with User Model

### Configuration

```ruby
# config/initializers/active_admin.rb
ActiveAdmin.setup do |config|
  config.site_title = "My App Admin"
  config.authentication_method = :authenticate_admin_user!
  config.current_user_method = :current_user
  config.logout_link_path = :destroy_user_session_path
end
```

### ApplicationController

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  protected

  def authenticate_admin_user!
    authenticate_user!
    unless current_user&.admin_access?
      flash[:alert] = "You are not authorized to access this area."
      redirect_to root_path
    end
  end
end
```

---

## 🌐 API Design (For Flutter/Mobile)

### Respond to JSON & HTML

```ruby
# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_api_user!

  respond_to :json

  private

  def authenticate_api_user!
    # JWT authentication for mobile apps
    # TODO: Implement devise-jwt
  end
end
```

### Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Web routes
  devise_for :users
  ActiveAdmin.routes(self)
  root "pages#home"

  # API routes for mobile apps
  namespace :api do
    namespace :v1 do
      # Public endpoints
      resources :categories, only: [:index, :show]
      resources :products, only: [:index, :show]
      get 'site_settings', to: 'site_settings#public_settings'

      # Authenticated endpoints
      resource :profile, only: [:show, :update]
    end
  end
end
```

---

## 🧪 Testing Patterns

### Model Tests

```ruby
# test/models/category_test.rb
class CategoryTest < ActiveSupport::TestCase
  test "generates slug from name" do
    category = Category.create!(name: "Power Tools")
    assert_equal "power-tools", category.slug
  end

  test "full_path returns ancestor chain" do
    parent = Category.create!(name: "Tools")
    child = Category.create!(name: "Drills", parent: parent)
    assert_equal "Tools > Drills", child.full_path
  end

  test "destroying parent destroys children but nullifies products" do
    parent = Category.create!(name: "Tools")
    child = Category.create!(name: "Drills", parent: parent)
    product = Product.create!(name: "Drill", sku: "D1", price: 100, category: child)

    parent.destroy!

    assert_nil Category.find_by(id: child.id)
    assert_nil product.reload.category_id  # Product still exists!
  end
end
```

### API Tests

```ruby
# test/controllers/api/v1/categories_controller_test.rb
class Api::V1::CategoriesControllerTest < ActionDispatch::IntegrationTest
  test "GET /api/v1/categories returns JSON" do
    Category.create!(name: "Tools")
    
    get api_v1_categories_url, as: :json
    
    assert_response :success
    assert_equal "application/json", response.content_type
    json = JSON.parse(response.body)
    assert_equal 1, json["data"].length
  end
end
```

---

## 📁 Directory Structure

```
tstack-rails-kit/
├── app/
│   ├── admin/              # Active Admin resources
│   │   ├── categories.rb
│   │   ├── products.rb
│   │   ├── site_settings.rb
│   │   └── users.rb
│   ├── controllers/
│   │   ├── api/
│   │   │   └── v1/
│   │   │       ├── base_controller.rb
│   │   │       ├── categories_controller.rb
│   │   │       ├── products_controller.rb
│   │   │       └── site_settings_controller.rb
│   │   └── application_controller.rb
│   ├── models/
│   │   ├── category.rb     # Self-referential
│   │   ├── product.rb
│   │   ├── site_setting.rb # Key-value JSON
│   │   └── user.rb         # Single model, multi-role
│   └── views/
├── config/
│   ├── initializers/
│   │   ├── active_admin.rb
│   │   └── devise.rb
│   └── routes.rb
├── db/
│   ├── migrate/
│   └── seeds.rb
└── test/
    ├── controllers/
    │   └── api/
    ├── models/
    └── integration/
```

---

## 🚀 Scaffold Commands

```bash
# 1. Create new Rails 8 app
rails new myapp --database=sqlite3 --css=tailwind --javascript=importmap

# 2. Add gems to Gemfile (see above)
bundle install

# 3. Install Devise
rails generate devise:install
rails generate devise User
# Edit migration to add custom fields

# 4. Install Active Admin
rails generate active_admin:install --skip-users

# 5. Generate models
rails generate model Category name:string slug:string:uniq description:text icon:string position:integer parent_id:integer:index

rails generate model Product name:string slug:string:uniq sku:string:uniq description:text price:decimal brand:string published:boolean category:references

rails generate model SiteSetting key:string:uniq category:string is_system:boolean is_public:boolean description:text

# 6. Run migrations
rails db:migrate

# 7. Seed data
rails db:seed
```

---

## 💡 Future Ideas to Add

- [ ] JWT authentication for mobile (devise-jwt)
- [ ] OmniAuth callbacks controller
- [ ] Rate limiting for API
- [ ] Pagination (kaminari or pagy)
- [ ] Search with Ransack
- [ ] Background jobs with Solid Queue
- [ ] File uploads to S3/Cloudflare R2
- [ ] Docker setup
- [ ] CI/CD with GitHub Actions
- [ ] Kamal deployment
- [ ] Swagger/OpenAPI docs
- [ ] Admin audit logs
- [ ] Soft delete (paranoia or discard gem)

---

## 📝 Notes & Decisions

### Why Single User Model?

- Simpler auth flow
- OAuth works for everyone
- Promote users to admin via panel
- Mobile app uses same JWT

### Why Self-Referential Categories?

- Industry standard (Amazon, Shopify)
- Infinite depth
- One model to maintain
- Simple queries

### Why Key-Value Site Settings?

- Flexible schema per setting
- Auto-seeding of defaults
- Easy to add new settings
- No migrations for content changes

---

*This document will evolve as we build vega-tools. Each pattern proven here will be extracted into tstack-rails-kit.*
