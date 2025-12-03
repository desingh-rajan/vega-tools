# =============================================================================
# CATEGORIES SEED
# =============================================================================
puts "📁 Creating categories..."

CATEGORIES_DATA = [
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
].freeze

# Preload existing categories to minimize database queries
# Use composite key (parent_id, name) for children to handle same-named children under different parents
existing_by_name = Category.all.index_by(&:name)
existing_by_parent_and_name = Category.all.index_by { |c| [c.parent_id, c.name] }

CATEGORIES_DATA.each do |cat_data|
  children = cat_data[:children] || []

  parent = existing_by_name[cat_data[:name]] || Category.find_or_create_by!(name: cat_data[:name]) do |c|
    c.slug = cat_data[:name].parameterize
    c.icon = cat_data[:icon]
    c.position = cat_data[:position]
  end
  existing_by_name[cat_data[:name]] = parent
  existing_by_parent_and_name[[nil, cat_data[:name]]] = parent
  puts "   ✅ #{parent.name}"

  children.each do |child_data|
    child_key = [parent.id, child_data[:name]]
    child = existing_by_parent_and_name[child_key] || Category.find_or_create_by!(name: child_data[:name], parent: parent) do |c|
      c.slug = child_data[:name].parameterize
      c.position = child_data[:position]
    end
    existing_by_parent_and_name[child_key] = child
    puts "      └── #{child_data[:name]}"
  end
end

puts "   📊 Total categories: #{Category.count} (#{Category.roots.count} root, #{Category.where.not(parent_id: nil).count} children)"
