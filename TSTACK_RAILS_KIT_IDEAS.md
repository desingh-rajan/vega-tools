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

## 🎨 JSON Editor for ActiveAdmin (Dual Interface)

> **Problem:** JSONB columns in ActiveAdmin show ugly raw JSON that non-technical users can't edit.
> **Solution:** Custom Formtastic input with tabs - "Form View" for users, "JSON View" for developers.

### 1. Custom Input Class

```ruby
# app/inputs/json_editor_input.rb
# frozen_string_literal: true

class JsonEditorInput < Formtastic::Inputs::TextInput
  def to_html
    input_wrapping do
      json_value = object.send(method)
      json_string = json_value.is_a?(String) ? json_value : JSON.pretty_generate(json_value || {})
      editor_id = "json_editor_#{object.class.name.underscore}_#{method}_#{object.id || 'new'}"

      template.content_tag(:div, class: "json-editor-container", id: editor_id) do
        template.concat(render_tabs(editor_id))
        template.concat(render_json_view(editor_id, json_string))
        template.concat(render_form_view(editor_id, json_value))
        template.concat(render_hidden_field)
        template.concat(render_javascript(editor_id, json_value))
      end
    end
  end

  private

  def render_tabs(editor_id)
    template.content_tag(:div, class: "json-editor-tabs") do
      template.content_tag(:button, "📝 Form View", type: "button", 
        class: "json-tab active", data: { target: "form", editor: editor_id }) +
      template.content_tag(:button, "{ } JSON View", type: "button", 
        class: "json-tab", data: { target: "json", editor: editor_id })
    end
  end

  def render_json_view(editor_id, json_string)
    template.content_tag(:div, class: "json-view", id: "#{editor_id}_json", style: "display: none;") do
      template.content_tag(:textarea, json_string, class: "json-textarea", rows: 15) +
      template.content_tag(:p, "Edit JSON directly. Changes sync automatically.", class: "json-hint")
    end
  end

  def render_form_view(editor_id, json_value)
    template.content_tag(:div, class: "form-view", id: "#{editor_id}_form") do
      render_hash_fields(json_value, "", editor_id) if json_value.is_a?(Hash)
    end
  end

  def render_hash_fields(hash, prefix, editor_id)
    template.content_tag(:div, class: "json-form-fields") do
      hash.map { |key, value| render_field(key, value, prefix.empty? ? key : "#{prefix}.#{key}", editor_id) }.join.html_safe
    end
  end

  def render_field(key, value, field_path, editor_id)
    label_text = key.to_s.humanize.titleize
    
    template.content_tag(:div, class: "json-field") do
      case value
      when Hash
        template.content_tag(:fieldset, class: "json-nested") do
          template.content_tag(:legend, label_text) + render_hash_fields(value, field_path, editor_id)
        end
      when Array
        if value.all? { |v| v.is_a?(String) }
          template.content_tag(:label, label_text) +
          template.content_tag(:textarea, value.join("\n"),
            class: "json-field-input json-array-input",
            data: { path: field_path, type: "array", editor: editor_id },
            placeholder: "One item per line", rows: [value.length + 1, 3].max) +
          template.content_tag(:span, "One item per line", class: "json-field-hint")
        else
          template.content_tag(:label, label_text) +
          template.content_tag(:pre, JSON.pretty_generate(value), class: "json-preview")
        end
      when TrueClass, FalseClass
        template.content_tag(:label, class: "json-checkbox-label") do
          template.check_box_tag("#{editor_id}_#{field_path}", "1", value,
            class: "json-field-input", data: { path: field_path, type: "boolean", editor: editor_id }) +
          " #{label_text}"
        end
      else
        is_long = value.to_s.length > 100 || value.to_s.include?("\n")
        template.content_tag(:label, label_text) +
        (is_long ? 
          template.content_tag(:textarea, value.to_s, class: "json-field-input",
            data: { path: field_path, type: "string", editor: editor_id }, rows: 3) :
          template.text_field_tag("#{editor_id}_#{field_path}", value.to_s, class: "json-field-input",
            data: { path: field_path, type: "string", editor: editor_id }))
      end
    end
  end

  def render_hidden_field
    template.hidden_field_tag(
      input_html_options[:name] || "#{object.class.name.underscore}[#{method}]", "",
      class: "json-hidden-field"
    )
  end

  def render_javascript(editor_id, json_value)
    template.content_tag(:script, <<~JS.html_safe)
      (function() {
        const container = document.getElementById('#{editor_id}');
        if (!container) return;
        
        const jsonTextarea = container.querySelector('.json-textarea');
        const hiddenField = container.querySelector('.json-hidden-field');
        const formView = document.getElementById('#{editor_id}_form');
        const jsonView = document.getElementById('#{editor_id}_json');
        const tabs = container.querySelectorAll('.json-tab');
        
        let currentJson = #{(json_value || {}).to_json};
        hiddenField.value = JSON.stringify(currentJson, null, 2);
        
        // Tab switching
        tabs.forEach(tab => {
          tab.addEventListener('click', function() {
            const target = this.dataset.target;
            tabs.forEach(t => t.classList.remove('active'));
            this.classList.add('active');
            
            if (target === 'json') {
              formView.style.display = 'none';
              jsonView.style.display = 'block';
              jsonTextarea.value = JSON.stringify(currentJson, null, 2);
            } else {
              try {
                currentJson = JSON.parse(jsonTextarea.value);
                jsonView.style.display = 'none';
                formView.style.display = 'block';
                syncJsonToForm();
              } catch(e) {
                alert('Invalid JSON. Please fix before switching.');
              }
            }
          });
        });
        
        // JSON textarea changes
        jsonTextarea.addEventListener('input', function() {
          try {
            currentJson = JSON.parse(this.value);
            hiddenField.value = this.value;
            this.classList.remove('json-error');
          } catch(e) { this.classList.add('json-error'); }
        });
        
        // Form field changes
        container.querySelectorAll('.json-field-input').forEach(input => {
          ['input', 'change'].forEach(evt => {
            input.addEventListener(evt, function() {
              const path = this.dataset.path;
              const type = this.dataset.type;
              let value = type === 'boolean' ? this.checked :
                          type === 'number' ? parseFloat(this.value) || 0 :
                          type === 'array' ? this.value.split('\\n').filter(s => s.trim()) :
                          this.value;
              setNestedValue(currentJson, path, value);
              hiddenField.value = JSON.stringify(currentJson, null, 2);
            });
          });
        });
        
        function setNestedValue(obj, path, value) {
          const keys = path.split('.');
          let current = obj;
          for (let i = 0; i < keys.length - 1; i++) {
            current[keys[i]] = current[keys[i]] || {};
            current = current[keys[i]];
          }
          current[keys[keys.length - 1]] = value;
        }
        
        function syncJsonToForm() {
          container.querySelectorAll('.json-field-input').forEach(input => {
            const path = input.dataset.path;
            const type = input.dataset.type;
            const value = path.split('.').reduce((o, k) => o?.[k], currentJson);
            if (type === 'boolean') input.checked = !!value;
            else if (type === 'array') input.value = Array.isArray(value) ? value.join('\\n') : '';
            else input.value = value ?? '';
          });
        }
      })();
    JS
  end
end
```

### 2. CSS Styling (add to active_admin_overrides.css)

```css
/* JSON Editor - Dual Interface */
.json-editor-container {
  border: 1px solid #c5e0bb;
  border-radius: 8px;
  overflow: hidden;
  background: #fff;
}

.json-editor-tabs {
  display: flex;
  background: #e3f2de;
  border-bottom: 1px solid #c5e0bb;
}

.json-tab {
  flex: 1;
  padding: 12px 20px;
  border: none;
  background: transparent;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  color: #3d6635;
}

.json-tab.active {
  background: #fff;
  border-bottom: 2px solid #6cc24a;
}

.json-textarea {
  width: 100%;
  min-height: 300px;
  font-family: 'Monaco', 'Menlo', monospace;
  font-size: 13px;
  padding: 16px;
  border: 1px solid #c5e0bb;
  border-radius: 6px;
  background: #f7fbf5;
}

.json-textarea.json-error {
  border-color: #dc3545;
  background: #fff5f5;
}

.json-form-fields {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 20px;
}

.json-field > label {
  font-weight: 600;
  font-size: 13px;
  color: #2d5025;
  display: block;
  margin-bottom: 6px;
}

.json-field-input {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #c5e0bb;
  border-radius: 6px;
  font-size: 14px;
}

.json-nested {
  border: 1px solid #d4e8cf;
  border-radius: 8px;
  padding: 16px;
  background: #f9fcf8;
}

.json-nested legend {
  font-weight: 600;
  color: #3d6635;
  padding: 0 8px;
}
```

### 3. Usage in ActiveAdmin

```ruby
# app/admin/site_settings.rb
ActiveAdmin.register SiteSetting do
  form do |f|
    f.inputs "Value" do
      value = f.object.value
      if value.is_a?(Hash) || value.is_a?(Array)
        f.input :value, as: :json_editor  # <-- Magic!
      else
        f.input :value, as: :string
      end
    end
    f.actions
  end

  # Controller to parse JSON on save
  controller do
    def update
      @record = SiteSetting.find(params[:id])
      value_param = params[:site_setting][:value]
      
      if value_param.strip.start_with?("{", "[")
        @record.value = JSON.parse(value_param)
      else
        @record.value = value_param
      end
      
      if @record.save
        redirect_to admin_site_setting_path(@record), notice: "Updated!"
      else
        render :edit
      end
    rescue JSON::ParserError => e
      @record.errors.add(:value, "Invalid JSON: #{e.message}")
      render :edit
    end
  end
end
```

### 4. Pretty Display in Index/Show Pages

```ruby
# In index or show blocks
column :value do |setting|
  value = setting.value
  case value
  when Hash
    div class: "json-key-value-display" do
      value.each do |k, v|
        div class: "json-kv-row" do
          span k.to_s.humanize.titleize, class: "json-kv-key"
          span v.to_s, class: "json-kv-value"
        end
      end
    end
  when Array
    pre JSON.pretty_generate(value)
  else
    value.to_s
  end
end
```

### Key Benefits

1. **Non-technical users** see friendly form fields with labels
2. **Developers** can switch to JSON view for complex edits
3. **Bi-directional sync** - changes in one view update the other
4. **Validation** - JSON errors highlighted before save
5. **Nested objects** rendered as fieldsets
6. **Arrays of strings** rendered as textarea (one per line)

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
