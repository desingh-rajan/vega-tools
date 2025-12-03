# =============================================================================
# MAIN SEEDS FILE
# =============================================================================
# Loads all seed files from db/seeds/ directory in order.
# Files are loaded alphabetically, so use numeric prefixes:
#   01_users.rb, 02_categories.rb, 03_products.rb, etc.
#
# Run: bin/rails db:seed
# =============================================================================

puts "🌱 Seeding database..."
puts ""

# Load all seed files in order
Dir[Rails.root.join("db/seeds/*.rb")].sort.each do |file|
  puts "━" * 60
  puts "📂 Loading #{File.basename(file)}"
  puts "━" * 60
  load file
  puts ""
end

# =============================================================================
# SUMMARY
# =============================================================================
puts "━" * 60
puts "🎉 Seeding complete!"
puts "━" * 60
puts ""
puts "📊 Summary:"
puts "   Users:         #{User.count}"
puts "   Categories:    #{Category.count} (#{Category.roots.count} root)"
puts "   Products:      #{Product.count}"
puts "   Site Settings: #{SiteSetting.count}"
puts ""
puts "🔐 Login credentials:"
puts "   Super Admin: admin@vegatoolsandhardwares.in / changeme123"
puts "   Demo Admin:  demo@vegatoolsandhardwares.in / demo1234"
puts ""
