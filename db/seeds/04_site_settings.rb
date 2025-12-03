# =============================================================================
# SITE SETTINGS SEED
# =============================================================================
puts "⚙️  Seeding site settings..."

SiteSetting::SYSTEM_KEYS.each do |key|
  SiteSetting.get(key)
  puts "   ✅ #{key}"
end

puts "   📊 Total site settings: #{SiteSetting.count}"
