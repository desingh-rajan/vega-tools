# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# =============================================================================
# USERS
# =============================================================================
puts "👤 Creating users..."

super_admin = User.find_or_create_by!(email: "admin@vegatoolsandhardwares.in") do |u|
  u.password = "changeme123"
  u.role = :super_admin
  u.name = "Super Admin"
  u.phone_number = "9500716588"
end
puts "   ✅ Super Admin: #{super_admin.email} (password: changeme123)"

# Demo admin user
admin = User.find_or_create_by!(email: "demo@vegatoolsandhardwares.in") do |u|
  u.password = "demo1234"
  u.role = :admin
  u.name = "Demo Admin"
end
puts "   ✅ Admin: #{admin.email} (password: demo1234)"

# =============================================================================
# CATEGORIES (from product catalog screenshots)
# =============================================================================
puts "📁 Creating categories..."

categories_data = [
  { name: "PPE Safety Equipment", icon: "🦺", position: 1, children: [
    { name: "Safety Helmets", position: 1 },
    { name: "Safety Shoes", position: 2 },
    { name: "Safety Gloves", position: 3 },
    { name: "Safety Harness", position: 4 },
    { name: "Reflective Jackets", position: 5 }
  ] },
  { name: "Cordless Tools", icon: "🔋", position: 2, children: [
    { name: "Cordless Drills", position: 1 },
    { name: "Cordless Impact Drivers", position: 2 },
    { name: "Cordless Impact Wrenches", position: 3 },
    { name: "Cordless Angle Grinders", position: 4 },
    { name: "Cordless Rotary Hammers", position: 5 }
  ] },
  { name: "Drills", icon: "⚡", position: 3, children: [
    { name: "Electric Drills", position: 1 },
    { name: "Impact Drills", position: 2 }
  ] },
  { name: "Core Drills", icon: "⚙️", position: 4, children: [
    { name: "Diamond Core Drills", position: 1 },
    { name: "Magnetic Core Drills", position: 2 }
  ] },
  { name: "Construction Tools", icon: "🔨", position: 5, children: [
    { name: "Rotary Hammers", position: 1 },
    { name: "Demolition Hammers", position: 2 },
    { name: "Concrete Cutters", position: 3 },
    { name: "Wall Chasers", position: 4 },
    { name: "Concrete Vibrators", position: 5 },
    { name: "Electric Mixers", position: 6 },
    { name: "Wall Sanders", position: 7 }
  ] },
  { name: "Chemical Anchors", icon: "🧪", position: 6 },
  { name: "Metal Working Tools", icon: "⚡", position: 7, children: [
    { name: "Angle Grinders", position: 1 },
    { name: "Chop Saws", position: 2 }
  ] },
  { name: "Measuring Tools", icon: "📏", position: 8, children: [
    { name: "Laser Distance Meters", position: 1 },
    { name: "Measuring Tapes", position: 2 },
    { name: "Spirit Levels", position: 3 }
  ] },
  { name: "Miscellaneous Tools", icon: "🛠️", position: 9, children: [
    { name: "Vacuum Cleaners", position: 1 },
    { name: "Air Compressors", position: 2 },
    { name: "Car Polishers", position: 3 },
    { name: "Hydraulic Jacks", position: 4 }
  ] },
  { name: "Welding Inverters", icon: "🔥", position: 10, children: [
    { name: "ARC Welding Machines", position: 1 }
  ] }
]

categories_data.each do |cat_data|
  children = cat_data.delete(:children) || []

  parent = Category.find_or_create_by!(name: cat_data[:name]) do |c|
    c.slug = cat_data[:name].parameterize
    c.icon = cat_data[:icon]
    c.position = cat_data[:position]
  end
  puts "   ✅ #{parent.name}"

  children.each do |child_data|
    child = Category.find_or_create_by!(name: child_data[:name], parent: parent) do |c|
      c.slug = child_data[:name].parameterize
      c.position = child_data[:position]
    end
    puts "      └── #{child.name}"
  end
end

# =============================================================================
# SAMPLE PRODUCTS (from screenshots)
# =============================================================================
puts "📦 Creating sample products..."

# Get category references
ppe = Category.find_by(name: "PPE Safety Equipment")
helmets = Category.find_by(name: "Safety Helmets")
shoes = Category.find_by(name: "Safety Shoes")
gloves = Category.find_by(name: "Safety Gloves")
cordless_drills = Category.find_by(name: "Cordless Drills")
angle_grinders = Category.find_by(name: "Angle Grinders")
welding = Category.find_by(name: "ARC Welding Machines")

products_data = [
  # PPE Safety Equipment
  {
    name: "Safety Helmet 540-590mm S-RH-G-WHITE",
    sku: "SH-WHITE-540",
    description: "Colour - White Material - HDPE Size - 540mm - 590mm",
    price: 399.00,
    discounted_price: 210.00,
    brand: "Generic",
    category: helmets,
    specifications: { color: "White", material: "HDPE", size: "540mm-590mm" }
  },
  {
    name: "Safety Helmet 540-590mm S-RH-G-YELLOW",
    sku: "SH-YELLOW-540",
    description: "Colour - Yellow Material - HDPE Size - 540mm - 590mm",
    price: 399.00,
    discounted_price: 210.00,
    brand: "Generic",
    category: helmets,
    specifications: { color: "Yellow", material: "HDPE", size: "540mm-590mm" }
  },
  {
    name: "Safety Shoe S-SLS-R7 (8,9,10)",
    sku: "SS-SLS-R7",
    description: "Type - SAFETY SHOE Color - BLACK Toe Cap - Steel",
    price: 899.00,
    discounted_price: 499.00,
    brand: "Generic",
    category: shoes,
    specifications: { type: "Safety Shoe", color: "Black", toe_cap: "Steel", sizes: [ 8, 9, 10 ] }
  },
  {
    name: "Safety Hand Gloves Cut Resistant ETERNITY",
    sku: "SG-ETERNITY",
    description: "Type - Cut Resistant Gloves Ideal For - Men & Women",
    price: 105.00,
    discounted_price: 60.00,
    brand: "ETERNITY",
    category: gloves,
    specifications: { type: "Cut Resistant", ideal_for: "Men & Women" }
  },

  # Cordless Tools
  {
    name: "Cordless Drill 12 Volts PM-CDD-12V-2B",
    sku: "PM-CDD-12V-2B",
    description: "Max Drill Capacity - 10mm Max Torque - 22Nm/8Nm",
    price: 7999.00,
    discounted_price: 5599.00,
    brand: "POLYMAK",
    category: cordless_drills,
    specifications: { voltage: "12V", max_drill_capacity: "10mm", max_torque: "22Nm/8Nm" }
  },
  {
    name: "Cordless Drill Driver 18 Volts PM-CDD-18V-2B",
    sku: "PM-CDD-18V-2B",
    description: "Max Drill Capacity - 10mm Max Torque - 28Nm/10Nm",
    price: 11499.00,
    discounted_price: 8049.00,
    brand: "POLYMAK",
    category: cordless_drills,
    specifications: { voltage: "18V", max_drill_capacity: "10mm", max_torque: "28Nm/10Nm" }
  },

  # Angle Grinders
  {
    name: "Angle Grinder 100mm 710 Watts PMAG4-670S",
    sku: "PMAG4-670S",
    description: "Max Wheel Dia - 100mm Speed (No Load) - 11000 rpm",
    price: 3249.00,
    discounted_price: 2759.00,
    brand: "POLYMAK",
    category: angle_grinders,
    specifications: { wheel_dia: "100mm", power: "710W", speed: "11000 rpm" }
  },
  {
    name: "Angle Grinder 100mm 800 Watts PMAG4-800S",
    sku: "PMAG4-800S",
    description: "Max Wheel Dia - 100mm Speed (No Load) - 11000 rpm",
    price: 4599.00,
    discounted_price: 3679.00,
    brand: "POLYMAK",
    category: angle_grinders,
    specifications: { wheel_dia: "100mm", power: "800W", speed: "11000 rpm" }
  },

  # Welding
  {
    name: "ARC Welding Machine 220A - I Phase PM-MMA220i",
    sku: "PM-MMA220i",
    description: "Rated Input Voltage - AC 220 V ± 10% Rated Input Current",
    price: 16999.00,
    discounted_price: 10199.00,
    brand: "POLYMAK",
    category: welding,
    specifications: { type: "ARC", current: "220A", phase: "Single", voltage: "AC 220V ± 10%" }
  }
]

products_data.each do |product_data|
  product = Product.find_or_create_by!(sku: product_data[:sku]) do |p|
    p.name = product_data[:name]
    p.description = product_data[:description]
    p.price = product_data[:price]
    p.discounted_price = product_data[:discounted_price]
    p.brand = product_data[:brand]
    p.category = product_data[:category]
    p.specifications = product_data[:specifications]
    p.published = true
  end
  puts "   ✅ #{product.name}"
end

# =============================================================================
# SITE SETTINGS (auto-seeded via model)
# =============================================================================
puts "⚙️  Seeding site settings..."

SiteSetting::SYSTEM_KEYS.each do |key|
  SiteSetting.get(key)
  puts "   ✅ #{key}"
end

# =============================================================================
# DONE
# =============================================================================
puts ""
puts "🎉 Seeding complete!"
puts ""
puts "📊 Summary:"
puts "   Users: #{User.count}"
puts "   Categories: #{Category.count} (#{Category.roots.count} root, #{Category.where.not(parent_id: nil).count} children)"
puts "   Products: #{Product.count}"
puts "   Site Settings: #{SiteSetting.count}"
puts ""
puts "🔐 Login credentials:"
puts "   Super Admin: admin@vegatoolsandhardwares.in / changeme123"
puts "   Demo Admin: demo@vegatoolsandhardwares.in / demo1234"
