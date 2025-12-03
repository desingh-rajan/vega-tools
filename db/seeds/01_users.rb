# =============================================================================
# USERS SEED
# =============================================================================
puts "👤 Creating users..."

super_admin = User.find_or_create_by!(email: "admin@vegatoolsandhardwares.in") do |u|
  u.password = "changeme123"
  u.role = :super_admin
  u.name = "Super Admin"
  u.phone_number = "9500716588"
end
puts "   ✅ Super Admin: #{super_admin.email}"

admin = User.find_or_create_by!(email: "demo@vegatoolsandhardwares.in") do |u|
  u.password = "demo1234"
  u.role = :admin
  u.name = "Demo Admin"
end
puts "   ✅ Admin: #{admin.email}"

puts "   📊 Total users: #{User.count}"
