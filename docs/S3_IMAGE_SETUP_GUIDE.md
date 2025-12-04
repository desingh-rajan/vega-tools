# S3 Image Storage with WebP Optimization - Reference Guide

> **Project:** vega-tools (Vega Tools and Hardwares)  
> **Date:** December 2024  
> **Purpose:** Document the S3 image setup for future Rails projects

---

## TL;DR - Use the Gem (Recommended)

**For your next project, use the `s3_webp_uploader` gem:**

```ruby
# Gemfile
gem "s3_webp_uploader", github: "desingh-rajan/s3_webp_uploader"
```

```bash
bundle install
bin/rails generate s3_webp_uploader:install
```

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  include S3WebpUploader::ImageHelpers
end
```

```erb
<%# In views %>
<%= image_tag @product.s3_thumbnail_url if @product.s3_has_images? %>
```

**That's it!** The gem handles:

- S3 uploads with `aws-sdk-s3`
- WebP conversion with `ruby-vips`
- Predictable folder structure: `{app}/{env}/images/{slug}/original.webp`
- Image count tracking (JSON column or dedicated column)

**What you DON'T need:**

- `S3PrefixedService` (monkey-patching Active Storage)
- Active Storage for public images
- Complex blob key management
- Manual service classes

---

## The Simple Setup (Using the Gem)

### 1. AWS S3 Bucket Setup

```bash
# Create bucket
aws s3 mb s3://your-bucket-name --region ap-south-1

# Bucket structure
your-bucket-name/
├── your-app/
│   ├── dev/
│   │   └── images/
│   │       └── {product-slug}/
│   │           ├── original.webp
│   │           └── thumbnail.webp
│   ├── prod/
│   │   └── images/
│   │       └── {product-slug}/
│   │           ├── original.webp
│   │           └── thumbnail.webp
│   └── test/
│       └── images/
```

### 2. S3 Bucket Policy (Public Read)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadForApp",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::your-bucket-name/your-app/*"
    }
  ]
}
```

**Important:** Disable "Block all public access" in bucket settings.

### 3. Install the Gem

```ruby
# Gemfile
gem "s3_webp_uploader", github: "desingh-rajan/s3_webp_uploader"
```

```bash
bundle install
bin/rails generate s3_webp_uploader:install
```

### 4. Dockerfile (for libvips)

```dockerfile
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libvips
```

### 5. Rails Credentials

```bash
EDITOR="code --wait" bin/rails credentials:edit
```

```yaml
aws:
  access_key_id: YOUR_ACCESS_KEY
  secret_access_key: YOUR_SECRET_KEY
```

### 6. Configure the Gem

The generator creates `config/initializers/s3_webp_uploader.rb`:

```ruby
S3WebpUploader.configure do |config|
  config.bucket = "your-bucket-name"
  config.region = "ap-south-1"
  config.prefix = "your-app/#{Rails.env}/images"
  
  # Optional customization
  config.original_max_size = 1200
  config.thumbnail_max_size = 300
  config.webp_quality = 85
  config.acl = "public-read"
end
```

### 7. Add to Your Model

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  include S3WebpUploader::ImageHelpers
end
```

### 8. Use in Views

```erb
<% if @product.s3_has_images? %>
  <%= image_tag @product.s3_thumbnail_url %>
  
  <%# Multiple images %>
  <% @product.s3_image_count.times do |i| %>
    <%= image_tag @product.s3_thumbnail_url(i) %>
  <% end %>
<% end %>
```

### 9. Upload in Controller

```ruby
def upload_images
  @product = Product.find(params[:id])
  uploader = @product.s3_image_uploader
  
  if params[:images].present?
    uploader.upload_all(params[:images])
    redirect_to @product, notice: "Images uploaded"
  end
end

def delete_image
  @product = Product.find(params[:id])
  @product.s3_image_uploader.delete(params[:index].to_i)
  redirect_to @product, notice: "Image deleted"
end
```

---

## Problems We Faced & Solutions

### Problem 1: Active Storage Random Keys

**Issue:** Active Storage generates random blob keys like `abc123xyz789...`  
**Why it matters:** Ugly URLs, can't predict image location, hard to debug

**Solution:** Skip Active Storage for product images. Use direct S3 with predictable paths.

### Problem 2: S3 Folder Structure with Active Storage

**Issue:** Active Storage doesn't support folder prefixes out of the box  
**What we tried:** Created `S3PrefixedService` to add prefixes

```ruby
# lib/active_storage/service/s3_prefixed_service.rb
# This was monkey-patching Rails internals - NOT RECOMMENDED
```

**Better solution:** Use the `s3_webp_uploader` gem instead.

### Problem 3: AWS Credentials Not Available in Docker

**Issue:** Locally, AWS SDK reads from `~/.aws/credentials`. In Docker, this file doesn't exist.

**Symptoms:**

```text
Aws::Errors::MissingCredentialsError: unable to sign request without credentials set
```

**Solution:** The gem handles this automatically by reading from Rails credentials.

### Problem 4: S3 403 Forbidden on Public Images

**Issue:** Images uploaded but return 403 when accessed via URL

**Causes:**

1. Bucket "Block Public Access" enabled
2. Missing bucket policy
3. Objects not uploaded with `acl: "public-read"`

**Solution:**

1. Disable "Block all public access" in S3 console
2. Add bucket policy (see above)
3. Always upload with `acl: "public-read"`

For existing files:

```bash
aws s3 cp s3://bucket/path/ s3://bucket/path/ --recursive --acl public-read --metadata-directive REPLACE
```

### Problem 5: Delete Last Image Didn't Update Count

**Issue:** Deleting the last image left `image_count: 1` instead of `0`

**Root cause:** Reindex logic only ran when there were images to shift

**Solution:** Always update count, even when no reindexing needed:

```ruby
def reindex_images_after_delete(deleted_index)
  # ... reindex logic ...
  update_image_count([total - 1, 0].max)  # Always update!
end
```

### Problem 6: Slug Mismatch Between Dev and Prod

**Issue:** Copied images from dev S3 to prod S3, but product slugs differed

**Example:** Dev had `safety-helmet-blue`, prod had `safety-helmet-s-rh-g-blue`

**Solution:** Don't copy images between environments. Either:

1. Re-seed with source images available
2. Manually upload via admin panel
3. Ensure slug generation is deterministic

---

## Quick Reference

### Image URL Pattern

```text
https://{bucket}.s3.{region}.amazonaws.com/{app}/{env}/images/{slug}/original.webp
https://{bucket}.s3.{region}.amazonaws.com/{app}/{env}/images/{slug}/thumbnail.webp
```

### Multiple Images

```text
{slug}/original.webp    # First image
{slug}/original_1.webp  # Second image
{slug}/original_2.webp  # Third image
{slug}/thumbnail.webp
{slug}/thumbnail_1.webp
{slug}/thumbnail_2.webp
```

### Store Image Count

The gem supports two methods:

1. **Dedicated column:** `image_count` integer column
2. **JSON column:** `specifications["image_count"]`

### Gem Methods

```ruby
@product.s3_has_images?      # Check if images exist
@product.s3_image_count      # Number of images
@product.s3_thumbnail_url    # First thumbnail URL
@product.s3_thumbnail_url(1) # Second thumbnail URL
@product.s3_original_url     # First original URL
@product.s3_original_url(2)  # Third original URL
@product.s3_image_uploader   # Get uploader instance
```

---

## Summary: Use the Gem

| Aspect | Manual Setup | s3_webp_uploader Gem |
|--------|--------------|---------------------|
| Setup | ~150 lines of code | 3 lines + generator |
| URLs | Predictable slug-based | Predictable slug-based |
| Customization | Full control | Configurable |
| Reusability | Copy/paste | `bundle add` |
| Maintenance | Per-project | Centralized |

**For public product images: Use the gem.**

---

## Gem Repository

GitHub: <https://github.com/desingh-rajan/s3_webp_uploader>

---

## Future Improvements

1. **CDN:** Put CloudFront in front of S3 for faster delivery
2. **Multiple sizes:** Add medium size for product listings
3. **Background jobs:** Move upload/conversion to Solid Queue for large files
4. **Validation:** Check image dimensions before upload
