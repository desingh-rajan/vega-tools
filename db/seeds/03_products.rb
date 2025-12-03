# =============================================================================
# PRODUCTS SEED - Products with images
# =============================================================================
puts "📦 Creating products..."

# Image directory path
IMAGES_DIR = ENV.fetch("SEED_IMAGES_DIR", Rails.root.join("client-resources/TOOLS images").to_s)

# Collect all valid image files (excluding .psd, .pdf, .HEIC)
ALL_IMAGES = if File.directory?(IMAGES_DIR)
  Dir.glob(File.join(IMAGES_DIR, "*.{jpg,jpeg,png,webp}")).select { |f| File.file?(f) }
else
  []
end

# Group images by category for smarter random assignment
CATEGORY_IMAGE_KEYWORDS = {
  "Safety Helmets" => %w[HELMET],
  "Safety Shoes" => %w[Shoe],
  "Safety Gloves" => %w[Gloves],
  "Safety Harness" => %w[Belt Harness],
  "Reflective Jackets" => %w[Reflective Jacket],
  "Cordless Drills" => %w[CDD],
  "Cordless Impact Drivers" => %w[CID],
  "Cordless Impact Wrenches" => %w[CIW],
  "Cordless Angle Grinders" => %w[CAG],
  "Cordless Rotary Hammers" => %w[CRH],
  "Electric Drills" => %w[Drill],
  "Impact Drills" => %w[ID],
  "Diamond Core Drills" => %w[Core KBM],
  "Magnetic Core Drills" => %w[Core KBM MG],
  "Rotary Hammers" => %w[RH],
  "Demolition Hammers" => %w[DH Demolition HDM],
  "Concrete Cutters" => %w[Cutter Marble],
  "Wall Chasers" => %w[WC],
  "Concrete Vibrators" => %w[CV],
  "Electric Mixers" => %w[EM Mixer],
  "Wall Sanders" => %w[WS Sander],
  "Chemical Anchors" => %w[mortar Resi injection],
  "Angle Grinders" => %w[AG Grinder PMAG],
  "Chop Saws" => %w[CHOP Chop CUT],
  "Laser Distance Meters" => %w[Laser LDM],
  "Measuring Tapes" => %w[TAPE Tape],
  "Spirit Levels" => %w[Level Spirit],
  "Vacuum Cleaners" => %w[VC Vacuum],
  "Air Compressors" => %w[AC Compressor],
  "Car Polishers" => %w[CP Polisher],
  "Hydraulic Jacks" => %w[Jack Hydraulic],
  "ARC Welding Machines" => %w[ARC MMA TOSHAN Welding]
}.freeze

# Helper to find images for a category
def images_for_category(category_name)
  keywords = CATEGORY_IMAGE_KEYWORDS[category_name] || []
  return ALL_IMAGES if keywords.empty?

  matched = ALL_IMAGES.select do |path|
    filename = File.basename(path)
    keywords.any? { |kw| filename.downcase.include?(kw.downcase) }
  end
  matched.empty? ? ALL_IMAGES : matched
end

# Helper to attach images - tries patterns first, then category-based random
def attach_product_images(product, patterns, category_name)
  return unless File.directory?(IMAGES_DIR)
  attached = false

  # First try specific patterns
  patterns.each do |pattern|
    Dir.glob(File.join(IMAGES_DIR, pattern)).each do |path|
      next unless File.exist?(path) && path =~ /\.(jpg|jpeg|png|webp)$/i
      content_type = case path.downcase
      when /\.png$/ then "image/png"
      when /\.webp$/ then "image/webp"
      else "image/jpeg"
      end
      product.images.attach(io: File.open(path), filename: File.basename(path), content_type: content_type)
      attached = true
    end
  end

  # If no images attached, pick 1-3 random images from category or all
  unless attached
    category_images = images_for_category(category_name)
    random_images = category_images.sample(rand(1..3))
    random_images.each do |path|
      content_type = case path.downcase
      when /\.png$/ then "image/png"
      when /\.webp$/ then "image/webp"
      else "image/jpeg"
      end
      product.images.attach(io: File.open(path), filename: File.basename(path), content_type: content_type)
    end
  end
rescue => e
  puts "      ⚠️  Image attach error for #{product.name}: #{e.message}"
end

# Helper to find category
def find_cat(name)
  Category.find_by(name: name)
end

# =============================================================================
# PRODUCTS DATA
# =============================================================================
PRODUCTS_DATA = [
  # ============ PPE Safety Equipment ============
  { name: "Safety Helmet S-RH-G WHITE", sku: "SH-WHITE-01", brand: "Generic", category: "Safety Helmets",
    price: 399, discounted_price: 210,
    description: "Premium HDPE safety helmet. Color: White. Size: 540mm-590mm. Adjustable headband with ratchet suspension.",
    specifications: { color: "White", material: "HDPE", size: "540-590mm" },
    images: [ "SAFETY HELMET S-RH-G-WHITE*.jpg" ] },

  { name: "Safety Helmet S-RH-G YELLOW", sku: "SH-YELLOW-01", brand: "Generic", category: "Safety Helmets",
    price: 399, discounted_price: 210,
    description: "Premium HDPE safety helmet. Color: Yellow. Size: 540mm-590mm.",
    specifications: { color: "Yellow", material: "HDPE", size: "540-590mm" },
    images: [ "SAFETY HELMET S-RH-G-YELLOW*.jpg" ] },

  { name: "Safety Helmet S-RH-G ORANGE", sku: "SH-ORANGE-01", brand: "Generic", category: "Safety Helmets",
    price: 399, discounted_price: 210,
    description: "Premium HDPE safety helmet. Color: Orange.",
    specifications: { color: "Orange", material: "HDPE" }, images: [] },

  { name: "Safety Helmet S-RH-G BLUE", sku: "SH-BLUE-01", brand: "Generic", category: "Safety Helmets",
    price: 399, discounted_price: 210,
    description: "Premium HDPE safety helmet. Color: Blue.",
    specifications: { color: "Blue", material: "HDPE" }, images: [] },

  { name: "Safety Helmet S-RH-G RED", sku: "SH-RED-01", brand: "Generic", category: "Safety Helmets",
    price: 399, discounted_price: 210,
    description: "Premium HDPE safety helmet. Color: Red.",
    specifications: { color: "Red", material: "HDPE" }, images: [] },

  # Safety Shoes
  { name: "Safety Shoe S-SLS-R7 Black", sku: "SS-SLS-R7-BLK", brand: "Generic", category: "Safety Shoes",
    price: 899, discounted_price: 499,
    description: "Steel toe safety shoe with anti-slip sole. Available in sizes 8, 9, 10.",
    specifications: { color: "Black", toe_cap: "Steel", sizes: "8,9,10" },
    images: [ "Safety Shoe S-SLS-R7*.jpg" ] },

  { name: "ALKO PLUS Safety Shoe APS K3", sku: "SS-ALKO-K3", brand: "ALKO PLUS", category: "Safety Shoes",
    price: 1299, discounted_price: 899,
    description: "Premium ALKO PLUS safety shoes. Black-Grey color. Sizes 8, 9, 10.",
    specifications: { color: "Black-Grey", toe_cap: "Steel", sizes: "8,9,10" },
    images: [ "Safety Shoe ALKO PLUS APS K3*.jpg" ] },

  { name: "Hillson WeFly Safety Shoe WF01", sku: "SS-HILLSON-WF01", brand: "Hillson", category: "Safety Shoes",
    price: 1599, discounted_price: 1199,
    description: "Hillson WeFly premium safety shoe. Lightweight with steel toe.",
    specifications: { color: "Black", toe_cap: "Steel", sizes: "8,9" },
    images: [ "Safety Shoe Hillson WeFly WF01*.jpg" ] },

  { name: "Safety Shoe Steel Toe Brown", sku: "SS-BROWN-01", brand: "Generic", category: "Safety Shoes",
    price: 999, discounted_price: 699, description: "Steel Toe Safety Shoe Brown.",
    specifications: { color: "Brown", toe_cap: "Steel" }, images: [] },

  { name: "Safety Shoe High Ankle", sku: "SS-HIGH-01", brand: "Generic", category: "Safety Shoes",
    price: 1499, discounted_price: 1049, description: "High Ankle Safety Boot.",
    specifications: { type: "High Ankle" }, images: [] },

  # Safety Gloves
  { name: "Cut Resistant Safety Gloves", sku: "SG-CUT-01", brand: "Generic", category: "Safety Gloves",
    price: 149, discounted_price: 89,
    description: "Cut resistant hand gloves. Ideal for handling sharp materials.",
    specifications: { type: "Cut Resistant", material: "HPPE" },
    images: [ "Safety Gloves*.jpg" ] },

  { name: "Leather Work Gloves", sku: "SG-LEATHER-01", brand: "Generic", category: "Safety Gloves",
    price: 249, discounted_price: 179, description: "Premium leather work gloves.",
    specifications: { material: "Leather" }, images: [] },

  { name: "Nitrile Coated Gloves", sku: "SG-NITRILE-01", brand: "Generic", category: "Safety Gloves",
    price: 99, discounted_price: 69, description: "Nitrile coated work gloves. Oil resistant.",
    specifications: { coating: "Nitrile" }, images: [] },

  { name: "PVC Coated Gloves", sku: "SG-PVC-01", brand: "Generic", category: "Safety Gloves",
    price: 129, discounted_price: 89, description: "PVC coated chemical resistant gloves.",
    specifications: { coating: "PVC" }, images: [] },

  # Safety Harness
  { name: "Full Body Safety Harness Belt", sku: "SH-BELT-01", brand: "Generic", category: "Safety Harness",
    price: 1999, discounted_price: 1499,
    description: "Full body safety harness with adjustable straps.",
    specifications: { type: "Full Body", material: "Polyester" },
    images: [ "Safety Belt*.jpg" ] },

  { name: "Half Body Safety Harness", sku: "SH-HALF-01", brand: "Generic", category: "Safety Harness",
    price: 1499, discounted_price: 1049, description: "Half Body Safety Harness.",
    specifications: { type: "Half Body" }, images: [] },

  { name: "Fall Arrest Lanyard", sku: "FAL-01", brand: "Generic", category: "Safety Harness",
    price: 799, discounted_price: 559, description: "Fall Arrest Lanyard with shock absorber.",
    specifications: { type: "Lanyard" }, images: [] },

  # Reflective Jackets
  { name: "High Visibility Reflective Jacket", sku: "RJ-HV-01", brand: "Generic", category: "Reflective Jackets",
    price: 499, discounted_price: 349,
    description: "High visibility reflective safety jacket.",
    specifications: { color: "Fluorescent Yellow", reflective_strips: "Yes" },
    images: [ "Reflective Jacket.jpg" ] },

  # ============ Cordless Tools ============
  { name: "Cordless Drill 12V PM-CDD-12V-2B", sku: "PM-CDD-12V-2B", brand: "POLYMAK", category: "Cordless Drills",
    price: 7999, discounted_price: 5599,
    description: "12V Cordless Drill with 2 batteries. Max drill capacity 10mm.",
    specifications: { voltage: "12V", max_drill: "10mm", torque: "22Nm/8Nm", batteries: "2" },
    images: [ "PM-CDD-12V-2B*.jpg" ] },

  { name: "Cordless Drill 18V PM-CDD-18V-2B", sku: "PM-CDD-18V-2B", brand: "POLYMAK", category: "Cordless Drills",
    price: 11499, discounted_price: 8049,
    description: "18V Cordless Drill Driver with 2 batteries.",
    specifications: { voltage: "18V", max_drill: "10mm", torque: "28Nm/10Nm", batteries: "2" },
    images: [ "PM-CDD-18V-2B*.jpg" ] },

  { name: "Cordless Drill 20V Heavy Duty", sku: "CD-20V-HD", brand: "POLYMAK", category: "Cordless Drills",
    price: 14999, discounted_price: 11999, description: "20V Heavy Duty Cordless Drill.",
    specifications: { voltage: "20V", torque: "45Nm" }, images: [] },

  { name: "Cordless Impact Driver 18V PM-CID-18VB-2B", sku: "PM-CID-18VB-2B", brand: "POLYMAK", category: "Cordless Impact Drivers",
    price: 12999, discounted_price: 9099,
    description: "18V Cordless Impact Driver. High torque for driving screws.",
    specifications: { voltage: "18V", max_torque: "160Nm", speed: "3000 rpm" },
    images: [ "PM-CID-18VB-2B.jpg" ] },

  { name: "Cordless Impact Wrench 18V PM-CIW-18V-2BL", sku: "PM-CIW-18V-2BL", brand: "POLYMAK", category: "Cordless Impact Wrenches",
    price: 15999, discounted_price: 11199,
    description: "18V Brushless Cordless Impact Wrench. 1/2\" square drive.",
    specifications: { voltage: "18V", drive: "1/2\"", max_torque: "280Nm", motor: "Brushless" },
    images: [ "PM-CIW-18V-2BL.jpg" ] },

  { name: "Cordless Angle Grinder 18V PM-CAG-18VB-2B", sku: "PM-CAG-18VB-2B", brand: "POLYMAK", category: "Cordless Angle Grinders",
    price: 13999, discounted_price: 9799,
    description: "18V Cordless Angle Grinder 100mm. Brushless motor.",
    specifications: { voltage: "18V", disc_dia: "100mm", speed: "8500 rpm" },
    images: [ "PM-CAG-18VB-2B.jpg" ] },

  { name: "Cordless Rotary Hammer 20V", sku: "CRH-20V", brand: "POLYMAK", category: "Cordless Rotary Hammers",
    price: 18999, discounted_price: 15199, description: "20V Cordless Rotary Hammer. SDS-Plus.",
    specifications: { voltage: "20V", chuck: "SDS-Plus" }, images: [] },

  # ============ Angle Grinders ============
  { name: "Angle Grinder 100mm 710W PMAG4-670S", sku: "PMAG4-670S", brand: "POLYMAK", category: "Angle Grinders",
    price: 3249, discounted_price: 2759,
    description: "100mm Angle Grinder 710 Watts. Compact design.",
    specifications: { disc_dia: "100mm", power: "710W", speed: "11000 rpm" },
    images: [ "PMAG4-670S*.jpg" ] },

  { name: "Angle Grinder 100mm 800W PMAG4-800S", sku: "PMAG4-800S", brand: "POLYMAK", category: "Angle Grinders",
    price: 4599, discounted_price: 3679,
    description: "100mm Angle Grinder 800 Watts. Heavy duty motor.",
    specifications: { disc_dia: "100mm", power: "800W", speed: "11000 rpm" },
    images: [ "PMAG4-800S*.jpg" ] },

  { name: "Angle Grinder 100mm 850W PMAG4-850B", sku: "PMAG4-850B", brand: "POLYMAK", category: "Angle Grinders",
    price: 4999, discounted_price: 3999,
    description: "100mm Angle Grinder 850 Watts. Back switch design.",
    specifications: { disc_dia: "100mm", power: "850W", speed: "11000 rpm" },
    images: [ "PMAG4-850B*.jpg" ] },

  { name: "Angle Grinder 100mm 1000W PMAG4-803DY", sku: "PMAG4-803DY", brand: "POLYMAK", category: "Angle Grinders",
    price: 5499, discounted_price: 4399,
    description: "100mm Angle Grinder 1000 Watts. Variable speed.",
    specifications: { disc_dia: "100mm", power: "1000W", variable_speed: "Yes" },
    images: [ "PMAG4-803DY*.jpg" ] },

  { name: "Angle Grinder 180mm 2600W PMAG180", sku: "PMAG180", brand: "POLYMAK", category: "Angle Grinders",
    price: 8999, discounted_price: 7199,
    description: "180mm Heavy Duty Angle Grinder 2600 Watts.",
    specifications: { disc_dia: "180mm", power: "2600W", speed: "8500 rpm" },
    images: [ "PMAG180*.jpg" ] },

  { name: "Angle Grinder CAG 100-850W", sku: "CAG-100-850W", brand: "Generic", category: "Angle Grinders",
    price: 3999, discounted_price: 2999,
    description: "100mm Angle Grinder 850 Watts.",
    specifications: { disc_dia: "100mm", power: "850W" },
    images: [ "Angle Grinder CAG 100-850W.jpg" ] },

  { name: "Angle Grinder CPAG 4-1200W", sku: "CPAG-4-1200W", brand: "Generic", category: "Angle Grinders",
    price: 5999, discounted_price: 4499,
    description: "100mm Angle Grinder 1200 Watts. High power.",
    specifications: { disc_dia: "100mm", power: "1200W" },
    images: [ "Angle Grinder CPAG 4-1200W.jpg" ] },

  { name: "KEN Angle Grinder 180mm 2450W 9180B", sku: "KEN-9180B", brand: "KEN", category: "Angle Grinders",
    price: 9499, discounted_price: 7599,
    description: "KEN 180mm Angle Grinder 2450 Watts. Soft start.",
    specifications: { disc_dia: "180mm", power: "2450W", soft_start: "Yes" },
    images: [ "KEN Angle Grinder 180mm 2450W 9180B.jpg" ] },

  { name: "Angle Grinder 115mm 900W", sku: "AG-115-900W", brand: "Generic", category: "Angle Grinders",
    price: 3499, discounted_price: 2799, description: "115mm Angle Grinder 900 Watts.",
    specifications: { disc_dia: "115mm", power: "900W" }, images: [] },

  { name: "Angle Grinder 125mm 1100W", sku: "AG-125-1100W", brand: "Generic", category: "Angle Grinders",
    price: 4299, discounted_price: 3439, description: "125mm Angle Grinder 1100 Watts.",
    specifications: { disc_dia: "125mm", power: "1100W" }, images: [] },

  { name: "Angle Grinder 230mm 2200W", sku: "AG-230-2200W", brand: "Generic", category: "Angle Grinders",
    price: 7999, discounted_price: 6399, description: "230mm Angle Grinder 2200 Watts.",
    specifications: { disc_dia: "230mm", power: "2200W" }, images: [] },

  # ============ Core Drills ============
  { name: "Diamond Core Drill PM250DCD", sku: "PM250DCD", brand: "POLYMAK", category: "Diamond Core Drills",
    price: 24999, discounted_price: 19999,
    description: "Diamond Core Drill Machine. 250mm max core diameter.",
    specifications: { max_core: "250mm", power: "2500W" },
    images: [ "Core Drill PM250DCD.jpg" ] },

  { name: "Magnetic Core Drill KBM 38", sku: "KBM-38", brand: "Generic", category: "Magnetic Core Drills",
    price: 34999, discounted_price: 27999,
    description: "Magnetic Base Core Drill. 38mm max drill capacity.",
    specifications: { max_drill: "38mm", magnet: "Electromagnetic", power: "1100W" },
    images: [ "Core Drill KBM 38*.jpg" ] },

  { name: "Magnetic Core Drill MG-40-O", sku: "MG-40-O", brand: "Generic", category: "Magnetic Core Drills",
    price: 32999, discounted_price: 26399,
    description: "Magnetic Core Drill. 40mm max drill capacity.",
    specifications: { max_drill: "40mm", power: "1200W" },
    images: [ "Core Drill MG-40-O.jpg" ] },

  # ============ Construction Tools ============
  { name: "Rotary Hammer 25mm PM25RH-DY", sku: "PM25RH-DY", brand: "POLYMAK", category: "Rotary Hammers",
    price: 8999, discounted_price: 7199,
    description: "25mm Rotary Hammer with 3 functions.",
    specifications: { max_drill_concrete: "25mm", power: "800W", impact_energy: "2.6J" },
    images: [ "PM25RH-DY.jpg" ] },

  { name: "Rotary Hammer 20mm 650W", sku: "RH-20-650W", brand: "Generic", category: "Rotary Hammers",
    price: 5999, discounted_price: 4799, description: "20mm Rotary Hammer 650 Watts.",
    specifications: { drill_dia: "20mm", power: "650W" }, images: [] },

  { name: "Rotary Hammer 26mm 850W", sku: "RH-26-850W", brand: "Generic", category: "Rotary Hammers",
    price: 7499, discounted_price: 5999, description: "26mm Rotary Hammer 850 Watts.",
    specifications: { drill_dia: "26mm", power: "850W" }, images: [] },

  { name: "Rotary Hammer 32mm 1100W", sku: "RH-32-1100W", brand: "Generic", category: "Rotary Hammers",
    price: 9999, discounted_price: 7999, description: "32mm Rotary Hammer 1100 Watts.",
    specifications: { drill_dia: "32mm", power: "1100W" }, images: [] },

  { name: "Rotary Hammer 40mm 1500W", sku: "RH-40-1500W", brand: "POLYMAK", category: "Rotary Hammers",
    price: 14999, discounted_price: 11999, description: "40mm Rotary Hammer 1500 Watts.",
    specifications: { drill_dia: "40mm", power: "1500W" }, images: [] },

  { name: "Demolition Hammer 5KG PMDH05-2P", sku: "PMDH05-2P", brand: "POLYMAK", category: "Demolition Hammers",
    price: 11999, discounted_price: 9599,
    description: "5KG Demolition Hammer. Powerful for breaking concrete.",
    specifications: { impact_energy: "8J", power: "1050W", blows: "2800 bpm" },
    images: [ "PMDH05-2P.jpg" ] },

  { name: "Demolition Hammer 10KG PM10HDM", sku: "PM10HDM", brand: "POLYMAK", category: "Demolition Hammers",
    price: 18999, discounted_price: 15199,
    description: "10KG Heavy Duty Demolition Hammer.",
    specifications: { impact_energy: "15J", power: "1500W" },
    images: [ "PM10HDM.jpg" ] },

  { name: "Demolition Hammer 11KG PMDH11P", sku: "PMDH11P", brand: "POLYMAK", category: "Demolition Hammers",
    price: 19999, discounted_price: 15999,
    description: "11KG Professional Demolition Hammer.",
    specifications: { impact_energy: "18J", power: "1500W" },
    images: [ "PMDH11P*.jpg" ] },

  { name: "FERM Demolition Hammer 11KG HDM1047P", sku: "FERM-HDM1047P", brand: "FERM", category: "Demolition Hammers",
    price: 22999, discounted_price: 18399,
    description: "FERM 11KG Demolition Hammer 1500W. European quality.",
    specifications: { impact_energy: "20J", power: "1500W" },
    images: [ "FERM Demolition Hammer*.jpg" ] },

  { name: "Marble Cutter 125mm 1200W", sku: "MC-125-1200W", brand: "Generic", category: "Concrete Cutters",
    price: 4999, discounted_price: 3999,
    description: "125mm Marble/Tile Cutter 1200 Watts.",
    specifications: { blade_dia: "125mm", power: "1200W" },
    images: [ "Marble Cutter 125mm 1200 Watts.jpg" ] },

  { name: "Tile Cutter CPTC 110 1150W", sku: "CPTC-110", brand: "Generic", category: "Concrete Cutters",
    price: 4499, discounted_price: 3599,
    description: "Tile Cutter 110mm 1150 Watts.",
    specifications: { blade_dia: "110mm", power: "1150W" },
    images: [ "Tile Cutter CPTC 110*.jpg" ] },

  { name: "Concrete Saw 14\" PMCS14-22DY", sku: "PMCS14-22DY", brand: "POLYMAK", category: "Concrete Cutters",
    price: 14999, discounted_price: 11999,
    description: "Concrete Cutter 14 inch 2200W.",
    specifications: { blade_dia: "14\"", power: "2200W", depth_cut: "125mm" },
    images: [ "PMCS14-22DY*.jpg" ] },

  { name: "Wall Chaser 133mm PM133WC", sku: "PM133WC", brand: "POLYMAK", category: "Wall Chasers",
    price: 12999, discounted_price: 10399,
    description: "Wall Chaser 133mm for electrical and plumbing grooves.",
    specifications: { blade_dia: "133mm", power: "1700W", groove_width: "6-40mm" },
    images: [ "PM133WC.jpg" ] },

  { name: "Wall Chaser 150mm 2100W", sku: "WC-150-2100W", brand: "Generic", category: "Wall Chasers",
    price: 14999, discounted_price: 11999, description: "Wall Chaser 150mm 2100 Watts.",
    specifications: { blade_dia: "150mm", power: "2100W" }, images: [] },

  { name: "Concrete Vibrator 3M PMCV3M Pro", sku: "PMCV3M-PRO", brand: "POLYMAK", category: "Concrete Vibrators",
    price: 8999, discounted_price: 7199,
    description: "Concrete Vibrator with 3M flexible shaft.",
    specifications: { shaft_length: "3M", needle_dia: "35mm", speed: "17000 vpm" },
    images: [ "PMCV3M Pro.jpg" ] },

  { name: "Concrete Mixer 4 Cft PMCM4 PRO", sku: "PMCM4-PRO", brand: "POLYMAK", category: "Electric Mixers",
    price: 34999, discounted_price: 27999,
    description: "Concrete Mixer 4 Cubic Feet Professional.",
    specifications: { capacity: "4 Cft", motor: "1.5 HP" },
    images: [ "PMCM4 PRO*.jpg" ] },

  { name: "Concrete Mixer 4 Cft PMCM4SB", sku: "PMCM4SB", brand: "POLYMAK", category: "Electric Mixers",
    price: 32999, discounted_price: 26399,
    description: "Concrete Mixer 4 Cft Stand model. Portable.",
    specifications: { capacity: "4 Cft", wheels: "Yes" },
    images: [ "PMCM4SB*.jpg" ] },

  { name: "Concrete Mixer 4.15 Cft PMCM415", sku: "PMCM415", brand: "POLYMAK", category: "Electric Mixers",
    price: 36999, discounted_price: 29599,
    description: "Concrete Mixer 4.15 Cubic Feet.",
    specifications: { capacity: "4.15 Cft", motor: "2 HP" },
    images: [ "PMCM415*.jpg" ] },

  { name: "Concrete Mixer 5 Cft PMCM5", sku: "PMCM5", brand: "POLYMAK", category: "Electric Mixers",
    price: 42999, discounted_price: 34399,
    description: "Concrete Mixer 5 Cubic Feet. Heavy duty.",
    specifications: { capacity: "5 Cft", motor: "2 HP" },
    images: [ "PMCM5*.jpg" ] },

  { name: "Wall Sander 7\" PM7WS", sku: "PM7WS", brand: "POLYMAK", category: "Wall Sanders",
    price: 11999, discounted_price: 9599,
    description: "Drywall Sander 7 inch with vacuum attachment.",
    specifications: { pad_dia: "7\"", power: "850W", vacuum: "Attachable" },
    images: [ "PM7WS*.jpg" ] },

  # ============ Chop Saws ============
  { name: "Chop Saw 355mm 2450W COM1008P", sku: "COM1008P", brand: "Generic", category: "Chop Saws",
    price: 8999, discounted_price: 7199,
    description: "Metal Cutting Chop Saw 355mm 2450 Watts.",
    specifications: { blade_dia: "355mm", power: "2450W", speed: "3800 rpm" },
    images: [ "CHOP SAW*355MM COM1008P.jpg" ] },

  { name: "Chop Saw 355mm PM355RS", sku: "PM355RS", brand: "POLYMAK", category: "Chop Saws",
    price: 9499, discounted_price: 7599,
    description: "POLYMAK Metal Chop Saw 355mm.",
    specifications: { blade_dia: "355mm", power: "2400W" },
    images: [ "PM355RS.jpg" ] },

  { name: "Verx Cut Off Machine VCO-1402", sku: "VCO-1402", brand: "Verx", category: "Chop Saws",
    price: 7999, discounted_price: 6399,
    description: "Verx Cut Off Machine 355mm. Compact design.",
    specifications: { blade_dia: "355mm", power: "2200W" },
    images: [ "Verx VCO-1402 Cut Off Machine*.jpg", "Verx chop-saw-machine*.jpg" ] },

  # ============ Drills ============
  { name: "Impact Drill 13mm PM14ID Pro", sku: "PM14ID-PRO", brand: "POLYMAK", category: "Impact Drills",
    price: 4499, discounted_price: 3599,
    description: "13mm Impact Drill Professional. Variable speed.",
    specifications: { chuck: "13mm", power: "750W", impact: "48000 bpm" },
    images: [ "PM14ID Pro.jpg" ] },

  { name: "Impact Drill 10mm 550W", sku: "ID-10-550W", brand: "Generic", category: "Impact Drills",
    price: 2499, discounted_price: 1999, description: "10mm Impact Drill 550 Watts.",
    specifications: { chuck: "10mm", power: "550W" }, images: [] },

  { name: "Impact Drill 13mm 850W", sku: "ID-13-850W", brand: "Generic", category: "Impact Drills",
    price: 3999, discounted_price: 3199, description: "13mm Impact Drill 850 Watts.",
    specifications: { chuck: "13mm", power: "850W" }, images: [] },

  { name: "Electric Drill 12mm PM12EM-DY", sku: "PM12EM-DY", brand: "POLYMAK", category: "Electric Drills",
    price: 3999, discounted_price: 3199,
    description: "12mm Electric Drill. Heavy duty.",
    specifications: { chuck: "12mm", power: "650W" },
    images: [ "PM12EM-DY*.jpg" ] },

  { name: "Electric Drill 10mm 450W", sku: "ED-10-450W", brand: "Generic", category: "Electric Drills",
    price: 1999, discounted_price: 1599, description: "10mm Electric Drill 450 Watts.",
    specifications: { chuck: "10mm", power: "450W" }, images: [] },

  # ============ Measuring Tools ============
  { name: "Laser Distance Meter 100M PM-LDM-100M", sku: "PM-LDM-100M", brand: "POLYMAK", category: "Laser Distance Meters",
    price: 4999, discounted_price: 3999,
    description: "Laser Distance Meter 100M range. Area, volume measurement.",
    specifications: { range: "100M", accuracy: "±2mm", functions: "Area, Volume, Pythagorean" },
    images: [ "Laser Distance Meter (100 Meter) PM-LDM-100M*.jpg" ] },

  { name: "Laser Distance Meter 60M PMLDM6B", sku: "PMLDM6B", brand: "POLYMAK", category: "Laser Distance Meters",
    price: 3499, discounted_price: 2799,
    description: "Compact Laser Distance Meter 60M range.",
    specifications: { range: "60M", accuracy: "±2mm" },
    images: [ "PMLDM6B.jpg" ] },

  { name: "Laser Distance Meter 40M", sku: "LDM-40M", brand: "Generic", category: "Laser Distance Meters",
    price: 2499, discounted_price: 1999, description: "Laser Distance Meter 40M.",
    specifications: { range: "40M" }, images: [] },

  { name: "Laser Distance Meter 80M", sku: "LDM-80M", brand: "Generic", category: "Laser Distance Meters",
    price: 3999, discounted_price: 3199, description: "Laser Distance Meter 80M.",
    specifications: { range: "80M" }, images: [] },

  { name: "Spirit Level with Magnet 300mm", sku: "SL-300-MAG", brand: "Generic", category: "Spirit Levels",
    price: 499, discounted_price: 349,
    description: "Spirit Level 300mm with magnetic base.",
    specifications: { length: "300mm", vials: "3", magnetic: "Yes" },
    images: [ "300mm Sprit Level With Magnet.jpg" ] },

  { name: "Spirit Level 600mm", sku: "SL-600MM", brand: "Generic", category: "Spirit Levels",
    price: 699, discounted_price: 559, description: "Spirit Level 600mm with magnetic base.",
    specifications: { length: "600mm" }, images: [] },

  { name: "Spirit Level 1200mm", sku: "SL-1200MM", brand: "Generic", category: "Spirit Levels",
    price: 999, discounted_price: 799, description: "Spirit Level 1200mm professional.",
    specifications: { length: "1200mm" }, images: [] },

  { name: "Plumbob Caltex", sku: "PB-CALTEX", brand: "Caltex", category: "Spirit Levels",
    price: 149, discounted_price: 99,
    description: "Precision Plumbob for vertical alignment.",
    specifications: { material: "Brass" },
    images: [ "Plumbob Caltex.jpg" ] },

  { name: "Measuring Tape 5M CHAMP", sku: "MT-CHAMP-5M", brand: "CHAMP", category: "Measuring Tapes",
    price: 199, discounted_price: 149,
    description: "Professional Measuring Tape 5M.",
    specifications: { length: "5M", width: "19mm" },
    images: [ "MEASURING TAPE CHAMP.jpg" ] },

  { name: "Measuring Tape 5M WARRIOR LOCK", sku: "HT-P-TPRO-5", brand: "WARRIOR", category: "Measuring Tapes",
    price: 299, discounted_price: 229,
    description: "Professional Measuring Tape 5M with power lock.",
    specifications: { length: "5M", width: "25mm" },
    images: [ "M PROFESSIONAL MEASURING TAPE*WARRIOR LOCK*.jpg" ] },

  { name: "Measuring Tape 3M", sku: "MT-3M", brand: "Generic", category: "Measuring Tapes",
    price: 99, discounted_price: 79, description: "Measuring Tape 3 Meters.",
    specifications: { length: "3M" }, images: [] },

  { name: "Measuring Tape 7.5M", sku: "MT-7.5M", brand: "Generic", category: "Measuring Tapes",
    price: 249, discounted_price: 199, description: "Measuring Tape 7.5 Meters.",
    specifications: { length: "7.5M" }, images: [] },

  { name: "Measuring Tape 10M", sku: "MT-10M", brand: "Generic", category: "Measuring Tapes",
    price: 349, discounted_price: 279, description: "Measuring Tape 10 Meters.",
    specifications: { length: "10M" }, images: [] },

  # ============ Chemical Anchors ============
  { name: "Injection Mortar ResiFIX VY ECO 345SF", sku: "RESIFIX-VY-ECO", brand: "ResiFIX", category: "Chemical Anchors",
    price: 899, discounted_price: 719,
    description: "Chemical Anchor Injection Mortar 345ml. Styrene-free.",
    specifications: { volume: "345ml", type: "Vinylester" },
    images: [ "Injection mortar ResiFIX VY ECO345SF.jpg" ] },

  { name: "Injection Mortar ResiFIX VYSF", sku: "RESIFIX-VYSF", brand: "ResiFIX", category: "Chemical Anchors",
    price: 799, discounted_price: 639,
    description: "Chemical Anchor Injection Mortar for heavy duty anchoring.",
    specifications: { volume: "300ml", type: "Vinylester" },
    images: [ "Injection mortar ResiFIX VYSF.jpg" ] },

  { name: "Injection Mortar 410ml Epoxy", sku: "IM-EPOXY-410", brand: "Generic", category: "Chemical Anchors",
    price: 999, discounted_price: 799, description: "Epoxy Injection Mortar 410ml.",
    specifications: { volume: "410ml", type: "Epoxy" }, images: [] },

  { name: "Injection Mortar 300ml Polyester", sku: "IM-POLY-300", brand: "Generic", category: "Chemical Anchors",
    price: 599, discounted_price: 479, description: "Polyester Injection Mortar 300ml.",
    specifications: { volume: "300ml", type: "Polyester" }, images: [] },

  # ============ Welding Equipment ============
  { name: "ARC Welding Machine 220A PM-MMA220-DY", sku: "PM-MMA220-DY", brand: "POLYMAK", category: "ARC Welding Machines",
    price: 16999, discounted_price: 11899,
    description: "ARC Welding Machine 220A Single Phase. IGBT.",
    specifications: { current: "220A", voltage: "220V", duty_cycle: "60%", technology: "IGBT" },
    images: [ "PM-MMA220-DY*.jpg" ] },

  { name: "TOSHAN ARC Welding Machine 400A MOS", sku: "TOSHAN-400-MOS", brand: "TOSHAN", category: "ARC Welding Machines",
    price: 24999, discounted_price: 19999,
    description: "TOSHAN ARC-400 MOS Welding Machine. 3-phase.",
    specifications: { current: "400A", voltage: "380V", duty_cycle: "80%" },
    images: [ "TOSHAN 400 mos ARC-400*.jpg" ] },

  { name: "TOSHAN ARC Welding Machine 400A IGBT", sku: "TOSHAN-400-IGBT", brand: "TOSHAN", category: "ARC Welding Machines",
    price: 27999, discounted_price: 22399,
    description: "TOSHAN ARC-400 CI IGBT Welding Machine. Premium.",
    specifications: { current: "400A", voltage: "380V", technology: "IGBT" },
    images: [ "TOSHAN 400 IGBT ARC-400 CI*.jpg" ] },

  { name: "ARC Welding Machine 160A", sku: "ARC-160A", brand: "Generic", category: "ARC Welding Machines",
    price: 8999, discounted_price: 7199, description: "ARC Welding Machine 160A.",
    specifications: { current: "160A" }, images: [] },

  { name: "ARC Welding Machine 200A", sku: "ARC-200A", brand: "Generic", category: "ARC Welding Machines",
    price: 11999, discounted_price: 9599, description: "ARC Welding Machine 200A.",
    specifications: { current: "200A" }, images: [] },

  { name: "ARC Welding Machine 250A", sku: "ARC-250A", brand: "Generic", category: "ARC Welding Machines",
    price: 14999, discounted_price: 11999, description: "ARC Welding Machine 250A.",
    specifications: { current: "250A" }, images: [] },

  { name: "ARC Welding Machine 300A", sku: "ARC-300A", brand: "Generic", category: "ARC Welding Machines",
    price: 18999, discounted_price: 15199, description: "ARC Welding Machine 300A 3-Phase.",
    specifications: { current: "300A", phase: "3" }, images: [] },

  # ============ Miscellaneous Tools ============
  { name: "Vacuum Cleaner 70L PMVC70L", sku: "PMVC70L", brand: "POLYMAK", category: "Vacuum Cleaners",
    price: 14999, discounted_price: 11999,
    description: "Industrial Wet & Dry Vacuum Cleaner 70L.",
    specifications: { capacity: "70L", power: "2400W", type: "Wet & Dry" },
    images: [ "PMVC70L.jpg" ] },

  { name: "Vacuum Cleaner 30L", sku: "VC-30L", brand: "Generic", category: "Vacuum Cleaners",
    price: 8999, discounted_price: 7199, description: "Industrial Vacuum Cleaner 30L.",
    specifications: { capacity: "30L" }, images: [] },

  { name: "Vacuum Cleaner 50L", sku: "VC-50L", brand: "Generic", category: "Vacuum Cleaners",
    price: 11999, discounted_price: 9599, description: "Industrial Vacuum Cleaner 50L.",
    specifications: { capacity: "50L" }, images: [] },

  { name: "Air Compressor 50L PMAC-50L", sku: "PMAC-50L", brand: "POLYMAK", category: "Air Compressors",
    price: 18999, discounted_price: 15199,
    description: "Oil-lubricated Air Compressor 50L tank.",
    specifications: { tank: "50L", power: "2HP", pressure: "8 bar" },
    images: [ "PMAC-50L.jpg" ] },

  { name: "Air Compressor 24L", sku: "AC-24L", brand: "Generic", category: "Air Compressors",
    price: 12999, discounted_price: 10399, description: "Air Compressor 24L tank.",
    specifications: { tank: "24L" }, images: [] },

  { name: "Air Compressor 100L", sku: "AC-100L", brand: "Generic", category: "Air Compressors",
    price: 29999, discounted_price: 23999, description: "Air Compressor 100L tank.",
    specifications: { tank: "100L" }, images: [] },

  { name: "Car Polisher 180mm PMCP180", sku: "PMCP180", brand: "POLYMAK", category: "Car Polishers",
    price: 5999, discounted_price: 4799,
    description: "Car Polisher 180mm. Variable speed 600-3000 RPM.",
    specifications: { pad_dia: "180mm", power: "1200W", speed: "600-3000 rpm" },
    images: [ "PMCP180*.jpg" ] },

  { name: "Car Polisher 125mm", sku: "CP-125", brand: "Generic", category: "Car Polishers",
    price: 3999, discounted_price: 3199, description: "Car Polisher 125mm.",
    specifications: { pad_dia: "125mm" }, images: [] },

  { name: "Car Polisher 150mm", sku: "CP-150", brand: "Generic", category: "Car Polishers",
    price: 4499, discounted_price: 3599, description: "Car Polisher 150mm.",
    specifications: { pad_dia: "150mm" }, images: [] },

  { name: "Hydraulic Bottle Jack 2 Ton HBJ2", sku: "HBJ-2T", brand: "Taparia", category: "Hydraulic Jacks",
    price: 899, discounted_price: 719,
    description: "Taparia Hydraulic Bottle Jack 2 Ton.",
    specifications: { capacity: "2 Ton", lift_range: "148-278mm" },
    images: [ "Taparia Hydraulic Bottle Jack, 2 Ton (Hbj 2)*.jpg" ] },

  { name: "Hydraulic Bottle Jack 3 Ton", sku: "HBJ-3T", brand: "Generic", category: "Hydraulic Jacks",
    price: 1099, discounted_price: 879, description: "Hydraulic Bottle Jack 3 Ton.",
    specifications: { capacity: "3 Ton" }, images: [] },

  { name: "Hydraulic Bottle Jack 5 Ton", sku: "HBJ-5T", brand: "Generic", category: "Hydraulic Jacks",
    price: 1499, discounted_price: 1199, description: "Hydraulic Bottle Jack 5 Ton.",
    specifications: { capacity: "5 Ton" }, images: [] },

  { name: "Hydraulic Bottle Jack 10 Ton", sku: "HBJ-10T", brand: "Generic", category: "Hydraulic Jacks",
    price: 2499, discounted_price: 1999, description: "Hydraulic Bottle Jack 10 Ton.",
    specifications: { capacity: "10 Ton" }, images: [] },

  { name: "Hydraulic Bottle Jack 20 Ton", sku: "HBJ-20T", brand: "Generic", category: "Hydraulic Jacks",
    price: 3999, discounted_price: 3199, description: "Hydraulic Bottle Jack 20 Ton.",
    specifications: { capacity: "20 Ton" }, images: [] },

  # ============ ADDITIONAL PRODUCTS FOR VARIETY ============

  # More PPE - Safety Helmets
  { name: "Safety Helmet S-RH-G GREEN", sku: "SH-GREEN-01", brand: "Generic", category: "Safety Helmets",
    price: 399, discounted_price: 210, description: "Premium HDPE safety helmet. Color: Green.",
    specifications: { color: "Green", material: "HDPE" }, images: [] },

  { name: "Safety Helmet with Face Shield WHITE", sku: "SH-FS-WHITE", brand: "Generic", category: "Safety Helmets",
    price: 799, discounted_price: 559, description: "Safety helmet with integrated face shield. White color.",
    specifications: { color: "White", face_shield: "Yes" }, images: [] },

  { name: "Safety Helmet with Face Shield YELLOW", sku: "SH-FS-YELLOW", brand: "Generic", category: "Safety Helmets",
    price: 799, discounted_price: 559, description: "Safety helmet with integrated face shield. Yellow color.",
    specifications: { color: "Yellow", face_shield: "Yes" }, images: [] },

  { name: "Ventilated Safety Helmet WHITE", sku: "SH-VENT-WHITE", brand: "Generic", category: "Safety Helmets",
    price: 549, discounted_price: 385, description: "Ventilated safety helmet for better airflow. White color.",
    specifications: { color: "White", ventilated: "Yes" }, images: [] },

  { name: "Ventilated Safety Helmet YELLOW", sku: "SH-VENT-YEL", brand: "Generic", category: "Safety Helmets",
    price: 549, discounted_price: 385, description: "Ventilated safety helmet for better airflow. Yellow color.",
    specifications: { color: "Yellow", ventilated: "Yes" }, images: [] },

  # More Safety Shoes
  { name: "Safety Shoe Low Ankle Black Size 6", sku: "SS-LOW-BLK-6", brand: "Generic", category: "Safety Shoes",
    price: 799, discounted_price: 559, description: "Low ankle steel toe safety shoe. Size 6.",
    specifications: { color: "Black", size: "6", ankle: "Low" }, images: [] },

  { name: "Safety Shoe Low Ankle Black Size 7", sku: "SS-LOW-BLK-7", brand: "Generic", category: "Safety Shoes",
    price: 799, discounted_price: 559, description: "Low ankle steel toe safety shoe. Size 7.",
    specifications: { color: "Black", size: "7", ankle: "Low" }, images: [] },

  { name: "Safety Shoe Low Ankle Black Size 11", sku: "SS-LOW-BLK-11", brand: "Generic", category: "Safety Shoes",
    price: 799, discounted_price: 559, description: "Low ankle steel toe safety shoe. Size 11.",
    specifications: { color: "Black", size: "11", ankle: "Low" }, images: [] },

  { name: "Executive Safety Shoe Black", sku: "SS-EXEC-BLK", brand: "Generic", category: "Safety Shoes",
    price: 1999, discounted_price: 1399, description: "Executive style safety shoe with steel toe.",
    specifications: { color: "Black", style: "Executive" }, images: [] },

  { name: "Ladies Safety Shoe Black", sku: "SS-LADIES-BLK", brand: "Generic", category: "Safety Shoes",
    price: 1299, discounted_price: 909, description: "Ladies safety shoe with steel toe protection.",
    specifications: { color: "Black", gender: "Ladies" }, images: [] },

  # More Safety Gloves
  { name: "Welding Leather Gloves 14\"", sku: "SG-WELD-14", brand: "Generic", category: "Safety Gloves",
    price: 349, discounted_price: 245, description: "14 inch welding leather gloves. Heat resistant.",
    specifications: { length: "14\"", type: "Welding" }, images: [] },

  { name: "Welding Leather Gloves 16\"", sku: "SG-WELD-16", brand: "Generic", category: "Safety Gloves",
    price: 449, discounted_price: 315, description: "16 inch welding leather gloves. Extended protection.",
    specifications: { length: "16\"", type: "Welding" }, images: [] },

  { name: "Cotton Hand Gloves (Dozen)", sku: "SG-COTTON-DZ", brand: "Generic", category: "Safety Gloves",
    price: 199, discounted_price: 139, description: "Cotton hand gloves. Pack of 12 pairs.",
    specifications: { pack: "12 pairs", material: "Cotton" }, images: [] },

  { name: "Rubber Coated Gloves", sku: "SG-RUBBER", brand: "Generic", category: "Safety Gloves",
    price: 129, discounted_price: 89, description: "Rubber coated work gloves. Good grip.",
    specifications: { coating: "Rubber" }, images: [] },

  { name: "Anti-Vibration Gloves", sku: "SG-ANTIVIB", brand: "Generic", category: "Safety Gloves",
    price: 599, discounted_price: 419, description: "Anti-vibration gloves for power tool users.",
    specifications: { type: "Anti-Vibration" }, images: [] },

  # More Safety Harness
  { name: "Tower Climbing Harness", sku: "SH-TOWER", brand: "Generic", category: "Safety Harness",
    price: 3999, discounted_price: 2799, description: "Professional tower climbing safety harness.",
    specifications: { type: "Tower Climbing" }, images: [] },

  { name: "Rescue Harness", sku: "SH-RESCUE", brand: "Generic", category: "Safety Harness",
    price: 4999, discounted_price: 3499, description: "Rescue harness with multiple attachment points.",
    specifications: { type: "Rescue" }, images: [] },

  { name: "Safety Harness Double Lanyard", sku: "SH-DOUBLE-LAN", brand: "Generic", category: "Safety Harness",
    price: 2999, discounted_price: 2099, description: "Safety harness with double lanyard.",
    specifications: { lanyard: "Double" }, images: [] },

  # More Reflective Jackets
  { name: "Reflective Jacket Orange", sku: "RJ-ORANGE", brand: "Generic", category: "Reflective Jackets",
    price: 499, discounted_price: 349, description: "High visibility reflective jacket. Orange color.",
    specifications: { color: "Orange" }, images: [] },

  { name: "Reflective Safety Vest Green", sku: "RJ-VEST-GREEN", brand: "Generic", category: "Reflective Jackets",
    price: 299, discounted_price: 209, description: "Reflective safety vest. Green color.",
    specifications: { color: "Green", type: "Vest" }, images: [] },

  { name: "Winter Reflective Jacket", sku: "RJ-WINTER", brand: "Generic", category: "Reflective Jackets",
    price: 999, discounted_price: 699, description: "Insulated winter reflective jacket.",
    specifications: { type: "Winter", insulated: "Yes" }, images: [] },

  # More Cordless Drills
  { name: "Cordless Drill 14.4V", sku: "CD-14.4V", brand: "Generic", category: "Cordless Drills",
    price: 6999, discounted_price: 5599, description: "14.4V Cordless Drill with battery.",
    specifications: { voltage: "14.4V" }, images: [] },

  { name: "Cordless Drill 21V Heavy Duty", sku: "CD-21V-HD", brand: "Generic", category: "Cordless Drills",
    price: 12999, discounted_price: 10399, description: "21V Heavy Duty Cordless Drill with 2 batteries.",
    specifications: { voltage: "21V", batteries: "2" }, images: [] },

  { name: "Cordless Drill Brushless 20V", sku: "CD-20V-BL", brand: "POLYMAK", category: "Cordless Drills",
    price: 15999, discounted_price: 12799, description: "20V Brushless Cordless Drill. Longer life motor.",
    specifications: { voltage: "20V", motor: "Brushless" }, images: [] },

  # More Cordless Impact Drivers
  { name: "Cordless Impact Driver 12V", sku: "CID-12V", brand: "Generic", category: "Cordless Impact Drivers",
    price: 7999, discounted_price: 6399, description: "12V Cordless Impact Driver. Compact design.",
    specifications: { voltage: "12V" }, images: [] },

  { name: "Cordless Impact Driver 20V Brushless", sku: "CID-20V-BL", brand: "POLYMAK", category: "Cordless Impact Drivers",
    price: 14999, discounted_price: 11999, description: "20V Brushless Cordless Impact Driver.",
    specifications: { voltage: "20V", motor: "Brushless" }, images: [] },

  # More Cordless Impact Wrenches
  { name: "Cordless Impact Wrench 1/2\" 20V", sku: "CIW-20V-12", brand: "Generic", category: "Cordless Impact Wrenches",
    price: 13999, discounted_price: 11199, description: "20V Cordless Impact Wrench 1/2\" drive.",
    specifications: { voltage: "20V", drive: "1/2\"" }, images: [] },

  { name: "Cordless Impact Wrench 3/4\" 20V", sku: "CIW-20V-34", brand: "POLYMAK", category: "Cordless Impact Wrenches",
    price: 18999, discounted_price: 15199, description: "20V Cordless Impact Wrench 3/4\" drive. Heavy duty.",
    specifications: { voltage: "20V", drive: "3/4\"" }, images: [] },

  # More Cordless Angle Grinders
  { name: "Cordless Angle Grinder 20V 115mm", sku: "CAG-20V-115", brand: "Generic", category: "Cordless Angle Grinders",
    price: 11999, discounted_price: 9599, description: "20V Cordless Angle Grinder 115mm disc.",
    specifications: { voltage: "20V", disc_dia: "115mm" }, images: [] },

  { name: "Cordless Angle Grinder 20V 125mm Brushless", sku: "CAG-20V-125-BL", brand: "POLYMAK", category: "Cordless Angle Grinders",
    price: 15999, discounted_price: 12799, description: "20V Brushless Cordless Angle Grinder 125mm.",
    specifications: { voltage: "20V", disc_dia: "125mm", motor: "Brushless" }, images: [] },

  # More Cordless Rotary Hammers
  { name: "Cordless Rotary Hammer 18V SDS-Plus", sku: "CRH-18V-SDS", brand: "Generic", category: "Cordless Rotary Hammers",
    price: 16999, discounted_price: 13599, description: "18V Cordless Rotary Hammer. SDS-Plus chuck.",
    specifications: { voltage: "18V", chuck: "SDS-Plus" }, images: [] },

  { name: "Cordless Rotary Hammer 20V Brushless", sku: "CRH-20V-BL", brand: "POLYMAK", category: "Cordless Rotary Hammers",
    price: 21999, discounted_price: 17599, description: "20V Brushless Cordless Rotary Hammer.",
    specifications: { voltage: "20V", motor: "Brushless" }, images: [] },

  # More Angle Grinders - Electric
  { name: "Angle Grinder 100mm 650W Economy", sku: "AG-100-650W-ECO", brand: "Generic", category: "Angle Grinders",
    price: 1999, discounted_price: 1599, description: "Economy 100mm Angle Grinder 650 Watts.",
    specifications: { disc_dia: "100mm", power: "650W" }, images: [] },

  { name: "Angle Grinder 100mm 720W", sku: "AG-100-720W", brand: "Generic", category: "Angle Grinders",
    price: 2499, discounted_price: 1999, description: "100mm Angle Grinder 720 Watts.",
    specifications: { disc_dia: "100mm", power: "720W" }, images: [] },

  { name: "Angle Grinder 100mm 950W Heavy Duty", sku: "AG-100-950W-HD", brand: "POLYMAK", category: "Angle Grinders",
    price: 4299, discounted_price: 3439, description: "Heavy Duty 100mm Angle Grinder 950 Watts.",
    specifications: { disc_dia: "100mm", power: "950W", type: "Heavy Duty" }, images: [] },

  { name: "Angle Grinder 125mm 1400W", sku: "AG-125-1400W", brand: "POLYMAK", category: "Angle Grinders",
    price: 5999, discounted_price: 4799, description: "125mm Angle Grinder 1400 Watts. High power.",
    specifications: { disc_dia: "125mm", power: "1400W" }, images: [] },

  { name: "Angle Grinder 150mm 1800W", sku: "AG-150-1800W", brand: "POLYMAK", category: "Angle Grinders",
    price: 6999, discounted_price: 5599, description: "150mm Angle Grinder 1800 Watts.",
    specifications: { disc_dia: "150mm", power: "1800W" }, images: [] },

  { name: "Angle Grinder 180mm 2200W Variable Speed", sku: "AG-180-2200W-VS", brand: "POLYMAK", category: "Angle Grinders",
    price: 8499, discounted_price: 6799, description: "180mm Angle Grinder with variable speed control.",
    specifications: { disc_dia: "180mm", power: "2200W", variable_speed: "Yes" }, images: [] },

  { name: "Angle Grinder 230mm 2600W", sku: "AG-230-2600W", brand: "POLYMAK", category: "Angle Grinders",
    price: 9999, discounted_price: 7999, description: "230mm Angle Grinder 2600 Watts. Industrial grade.",
    specifications: { disc_dia: "230mm", power: "2600W" }, images: [] },

  # More Core Drills
  { name: "Diamond Core Drill 160mm", sku: "DCD-160", brand: "Generic", category: "Diamond Core Drills",
    price: 18999, discounted_price: 15199, description: "Diamond Core Drill Machine. 160mm max core.",
    specifications: { max_core: "160mm", power: "2000W" }, images: [] },

  { name: "Diamond Core Drill 200mm", sku: "DCD-200", brand: "Generic", category: "Diamond Core Drills",
    price: 21999, discounted_price: 17599, description: "Diamond Core Drill Machine. 200mm max core.",
    specifications: { max_core: "200mm", power: "2200W" }, images: [] },

  { name: "Diamond Core Drill 300mm Professional", sku: "DCD-300-PRO", brand: "POLYMAK", category: "Diamond Core Drills",
    price: 34999, discounted_price: 27999, description: "Professional Diamond Core Drill 300mm.",
    specifications: { max_core: "300mm", power: "3200W" }, images: [] },

  { name: "Diamond Core Bit 50mm", sku: "DCB-50", brand: "Generic", category: "Diamond Core Drills",
    price: 1499, discounted_price: 1199, description: "Diamond Core Bit 50mm for concrete.",
    specifications: { diameter: "50mm" }, images: [] },

  { name: "Diamond Core Bit 75mm", sku: "DCB-75", brand: "Generic", category: "Diamond Core Drills",
    price: 1999, discounted_price: 1599, description: "Diamond Core Bit 75mm for concrete.",
    specifications: { diameter: "75mm" }, images: [] },

  { name: "Diamond Core Bit 100mm", sku: "DCB-100", brand: "Generic", category: "Diamond Core Drills",
    price: 2499, discounted_price: 1999, description: "Diamond Core Bit 100mm for concrete.",
    specifications: { diameter: "100mm" }, images: [] },

  { name: "Diamond Core Bit 150mm", sku: "DCB-150", brand: "Generic", category: "Diamond Core Drills",
    price: 3999, discounted_price: 3199, description: "Diamond Core Bit 150mm for concrete.",
    specifications: { diameter: "150mm" }, images: [] },

  # More Magnetic Core Drills
  { name: "Magnetic Core Drill 25mm", sku: "MCD-25", brand: "Generic", category: "Magnetic Core Drills",
    price: 24999, discounted_price: 19999, description: "Magnetic Base Core Drill. 25mm capacity.",
    specifications: { max_drill: "25mm", power: "900W" }, images: [] },

  { name: "Magnetic Core Drill 50mm", sku: "MCD-50", brand: "Generic", category: "Magnetic Core Drills",
    price: 44999, discounted_price: 35999, description: "Magnetic Base Core Drill. 50mm capacity.",
    specifications: { max_drill: "50mm", power: "1500W" }, images: [] },

  { name: "Annular Cutter Set HSS", sku: "AC-SET-HSS", brand: "Generic", category: "Magnetic Core Drills",
    price: 8999, discounted_price: 7199, description: "HSS Annular Cutter Set for magnetic drills.",
    specifications: { material: "HSS", pieces: "6" }, images: [] },

  # More Rotary Hammers
  { name: "Rotary Hammer 22mm 650W", sku: "RH-22-650W", brand: "Generic", category: "Rotary Hammers",
    price: 5499, discounted_price: 4399, description: "22mm Rotary Hammer 650 Watts.",
    specifications: { drill_dia: "22mm", power: "650W" }, images: [] },

  { name: "Rotary Hammer 24mm 780W", sku: "RH-24-780W", brand: "POLYMAK", category: "Rotary Hammers",
    price: 6499, discounted_price: 5199, description: "24mm Rotary Hammer 780 Watts.",
    specifications: { drill_dia: "24mm", power: "780W" }, images: [] },

  { name: "Rotary Hammer 28mm 950W", sku: "RH-28-950W", brand: "POLYMAK", category: "Rotary Hammers",
    price: 8499, discounted_price: 6799, description: "28mm Rotary Hammer 950 Watts.",
    specifications: { drill_dia: "28mm", power: "950W" }, images: [] },

  { name: "Rotary Hammer 38mm 1200W SDS-Max", sku: "RH-38-1200W-MAX", brand: "POLYMAK", category: "Rotary Hammers",
    price: 12999, discounted_price: 10399, description: "38mm Rotary Hammer SDS-Max chuck.",
    specifications: { drill_dia: "38mm", power: "1200W", chuck: "SDS-Max" }, images: [] },

  { name: "Rotary Hammer 45mm 1350W", sku: "RH-45-1350W", brand: "POLYMAK", category: "Rotary Hammers",
    price: 16999, discounted_price: 13599, description: "45mm Heavy Duty Rotary Hammer.",
    specifications: { drill_dia: "45mm", power: "1350W" }, images: [] },

  # More Demolition Hammers
  { name: "Demolition Hammer 3KG 650W", sku: "DH-3KG", brand: "Generic", category: "Demolition Hammers",
    price: 7999, discounted_price: 6399, description: "3KG Light Demolition Hammer.",
    specifications: { weight: "3KG", power: "650W" }, images: [] },

  { name: "Demolition Hammer 6KG 1100W", sku: "DH-6KG", brand: "Generic", category: "Demolition Hammers",
    price: 12999, discounted_price: 10399, description: "6KG Demolition Hammer 1100 Watts.",
    specifications: { weight: "6KG", power: "1100W" }, images: [] },

  { name: "Demolition Hammer 8KG 1300W", sku: "DH-8KG", brand: "POLYMAK", category: "Demolition Hammers",
    price: 15999, discounted_price: 12799, description: "8KG Demolition Hammer 1300 Watts.",
    specifications: { weight: "8KG", power: "1300W" }, images: [] },

  { name: "Demolition Hammer 15KG 1600W", sku: "DH-15KG", brand: "POLYMAK", category: "Demolition Hammers",
    price: 24999, discounted_price: 19999, description: "15KG Heavy Duty Demolition Hammer.",
    specifications: { weight: "15KG", power: "1600W" }, images: [] },

  { name: "Demolition Hammer 16KG 1600W Pro", sku: "DH-16KG-PRO", brand: "POLYMAK", category: "Demolition Hammers",
    price: 27999, discounted_price: 22399, description: "16KG Professional Demolition Hammer.",
    specifications: { weight: "16KG", power: "1600W" }, images: [] },

  # More Concrete Cutters
  { name: "Marble Cutter 110mm 1050W", sku: "MC-110-1050W", brand: "Generic", category: "Concrete Cutters",
    price: 3999, discounted_price: 3199, description: "110mm Marble Cutter 1050 Watts.",
    specifications: { blade_dia: "110mm", power: "1050W" }, images: [] },

  { name: "Marble Cutter 150mm 1500W", sku: "MC-150-1500W", brand: "POLYMAK", category: "Concrete Cutters",
    price: 5999, discounted_price: 4799, description: "150mm Marble Cutter 1500 Watts.",
    specifications: { blade_dia: "150mm", power: "1500W" }, images: [] },

  { name: "Concrete Saw 12\" 2000W", sku: "CS-12-2000W", brand: "Generic", category: "Concrete Cutters",
    price: 11999, discounted_price: 9599, description: "12 inch Concrete Saw 2000 Watts.",
    specifications: { blade_dia: "12\"", power: "2000W" }, images: [] },

  { name: "Concrete Saw 16\" 2600W", sku: "CS-16-2600W", brand: "POLYMAK", category: "Concrete Cutters",
    price: 18999, discounted_price: 15199, description: "16 inch Concrete Saw 2600 Watts.",
    specifications: { blade_dia: "16\"", power: "2600W" }, images: [] },

  # More Wall Chasers
  { name: "Wall Chaser 125mm 1500W", sku: "WC-125-1500W", brand: "Generic", category: "Wall Chasers",
    price: 10999, discounted_price: 8799, description: "Wall Chaser 125mm 1500 Watts.",
    specifications: { blade_dia: "125mm", power: "1500W" }, images: [] },

  { name: "Wall Chaser 180mm 2500W", sku: "WC-180-2500W", brand: "POLYMAK", category: "Wall Chasers",
    price: 17999, discounted_price: 14399, description: "Wall Chaser 180mm 2500 Watts. Heavy duty.",
    specifications: { blade_dia: "180mm", power: "2500W" }, images: [] },

  # More Concrete Vibrators
  { name: "Concrete Vibrator 1M Shaft", sku: "CV-1M", brand: "Generic", category: "Concrete Vibrators",
    price: 5999, discounted_price: 4799, description: "Concrete Vibrator with 1M flexible shaft.",
    specifications: { shaft_length: "1M" }, images: [] },

  { name: "Concrete Vibrator 2M Shaft", sku: "CV-2M", brand: "Generic", category: "Concrete Vibrators",
    price: 6999, discounted_price: 5599, description: "Concrete Vibrator with 2M flexible shaft.",
    specifications: { shaft_length: "2M" }, images: [] },

  { name: "Concrete Vibrator 4M Shaft", sku: "CV-4M", brand: "POLYMAK", category: "Concrete Vibrators",
    price: 9999, discounted_price: 7999, description: "Concrete Vibrator with 4M flexible shaft.",
    specifications: { shaft_length: "4M" }, images: [] },

  { name: "Concrete Vibrator Needle 35mm", sku: "CVN-35", brand: "Generic", category: "Concrete Vibrators",
    price: 1999, discounted_price: 1599, description: "Replacement vibrator needle 35mm.",
    specifications: { needle_dia: "35mm" }, images: [] },

  { name: "Concrete Vibrator Needle 50mm", sku: "CVN-50", brand: "Generic", category: "Concrete Vibrators",
    price: 2499, discounted_price: 1999, description: "Replacement vibrator needle 50mm.",
    specifications: { needle_dia: "50mm" }, images: [] },

  # More Electric Mixers
  { name: "Concrete Mixer 3 Cft Economy", sku: "CM-3CFT-ECO", brand: "Generic", category: "Electric Mixers",
    price: 24999, discounted_price: 19999, description: "Economy Concrete Mixer 3 Cubic Feet.",
    specifications: { capacity: "3 Cft" }, images: [] },

  { name: "Concrete Mixer 6 Cft", sku: "CM-6CFT", brand: "POLYMAK", category: "Electric Mixers",
    price: 49999, discounted_price: 39999, description: "Concrete Mixer 6 Cubic Feet. Heavy duty.",
    specifications: { capacity: "6 Cft", motor: "3 HP" }, images: [] },

  { name: "Mortar Mixer 120L", sku: "MM-120L", brand: "Generic", category: "Electric Mixers",
    price: 34999, discounted_price: 27999, description: "Mortar Mixer 120 Liter capacity.",
    specifications: { capacity: "120L" }, images: [] },

  { name: "Paint Mixer Electric", sku: "PM-ELEC", brand: "Generic", category: "Electric Mixers",
    price: 4999, discounted_price: 3999, description: "Electric Paint Mixer with paddle.",
    specifications: { power: "1200W" }, images: [] },

  # More Drills
  { name: "Electric Drill 6mm 350W", sku: "ED-6-350W", brand: "Generic", category: "Electric Drills",
    price: 1299, discounted_price: 1039, description: "6mm Electric Drill 350 Watts.",
    specifications: { chuck: "6mm", power: "350W" }, images: [] },

  { name: "Electric Drill 13mm 550W", sku: "ED-13-550W", brand: "Generic", category: "Electric Drills",
    price: 2299, discounted_price: 1839, description: "13mm Electric Drill 550 Watts.",
    specifications: { chuck: "13mm", power: "550W" }, images: [] },

  { name: "Electric Drill 13mm Reversible 750W", sku: "ED-13-750W-REV", brand: "POLYMAK", category: "Electric Drills",
    price: 3499, discounted_price: 2799, description: "13mm Reversible Electric Drill 750 Watts.",
    specifications: { chuck: "13mm", power: "750W", reversible: "Yes" }, images: [] },

  { name: "Impact Drill 16mm 1050W", sku: "ID-16-1050W", brand: "POLYMAK", category: "Impact Drills",
    price: 4999, discounted_price: 3999, description: "16mm Impact Drill 1050 Watts. Heavy duty.",
    specifications: { chuck: "16mm", power: "1050W" }, images: [] },

  { name: "Impact Drill 13mm Variable Speed", sku: "ID-13-VS", brand: "POLYMAK", category: "Impact Drills",
    price: 3799, discounted_price: 3039, description: "13mm Impact Drill with variable speed.",
    specifications: { chuck: "13mm", variable_speed: "Yes" }, images: [] },

  # More Chop Saws
  { name: "Chop Saw 355mm 2200W Economy", sku: "CS-355-2200W-ECO", brand: "Generic", category: "Chop Saws",
    price: 6999, discounted_price: 5599, description: "Economy Metal Chop Saw 355mm.",
    specifications: { blade_dia: "355mm", power: "2200W" }, images: [] },

  { name: "Chop Saw 400mm 3000W Heavy Duty", sku: "CS-400-3000W-HD", brand: "POLYMAK", category: "Chop Saws",
    price: 12999, discounted_price: 10399, description: "Heavy Duty Chop Saw 400mm 3000 Watts.",
    specifications: { blade_dia: "400mm", power: "3000W" }, images: [] },

  { name: "Cut Off Wheel 355mm (Pack of 10)", sku: "COW-355-10", brand: "Generic", category: "Chop Saws",
    price: 999, discounted_price: 799, description: "Cut Off Wheels 355mm. Pack of 10.",
    specifications: { diameter: "355mm", pack: "10" }, images: [] },

  # More Measuring Tools
  { name: "Laser Distance Meter 20M", sku: "LDM-20M", brand: "Generic", category: "Laser Distance Meters",
    price: 1499, discounted_price: 1199, description: "Compact Laser Distance Meter 20M range.",
    specifications: { range: "20M" }, images: [] },

  { name: "Laser Distance Meter 50M Bluetooth", sku: "LDM-50M-BT", brand: "POLYMAK", category: "Laser Distance Meters",
    price: 2999, discounted_price: 2399, description: "Laser Distance Meter with Bluetooth connectivity.",
    specifications: { range: "50M", bluetooth: "Yes" }, images: [] },

  { name: "Laser Distance Meter 150M Professional", sku: "LDM-150M-PRO", brand: "POLYMAK", category: "Laser Distance Meters",
    price: 6999, discounted_price: 5599, description: "Professional Laser Distance Meter 150M.",
    specifications: { range: "150M" }, images: [] },

  { name: "Laser Level Cross Line", sku: "LL-CROSS", brand: "Generic", category: "Laser Distance Meters",
    price: 2999, discounted_price: 2399, description: "Cross Line Laser Level. Self-leveling.",
    specifications: { type: "Cross Line" }, images: [] },

  { name: "Laser Level 5 Lines", sku: "LL-5LINE", brand: "POLYMAK", category: "Laser Distance Meters",
    price: 5999, discounted_price: 4799, description: "5 Line Laser Level with tripod.",
    specifications: { lines: "5" }, images: [] },

  { name: "Spirit Level 450mm", sku: "SL-450MM", brand: "Generic", category: "Spirit Levels",
    price: 599, discounted_price: 479, description: "Spirit Level 450mm.",
    specifications: { length: "450mm" }, images: [] },

  { name: "Spirit Level 900mm", sku: "SL-900MM", brand: "Generic", category: "Spirit Levels",
    price: 899, discounted_price: 719, description: "Spirit Level 900mm professional.",
    specifications: { length: "900mm" }, images: [] },

  { name: "Spirit Level 1800mm", sku: "SL-1800MM", brand: "Generic", category: "Spirit Levels",
    price: 1299, discounted_price: 1039, description: "Spirit Level 1800mm professional.",
    specifications: { length: "1800mm" }, images: [] },

  { name: "Torpedo Spirit Level 9\"", sku: "SL-TORPEDO-9", brand: "Generic", category: "Spirit Levels",
    price: 299, discounted_price: 239, description: "Torpedo Spirit Level 9 inch. Magnetic.",
    specifications: { length: "9\"", type: "Torpedo" }, images: [] },

  { name: "Measuring Tape 8M Steel", sku: "MT-8M-STEEL", brand: "Generic", category: "Measuring Tapes",
    price: 299, discounted_price: 239, description: "Steel Measuring Tape 8 Meters.",
    specifications: { length: "8M", material: "Steel" }, images: [] },

  { name: "Measuring Tape 30M Fiberglass", sku: "MT-30M-FG", brand: "Generic", category: "Measuring Tapes",
    price: 499, discounted_price: 399, description: "Fiberglass Measuring Tape 30 Meters.",
    specifications: { length: "30M", material: "Fiberglass" }, images: [] },

  { name: "Measuring Tape 50M Fiberglass", sku: "MT-50M-FG", brand: "Generic", category: "Measuring Tapes",
    price: 699, discounted_price: 559, description: "Fiberglass Measuring Tape 50 Meters.",
    specifications: { length: "50M", material: "Fiberglass" }, images: [] },

  { name: "Measuring Tape 100M Fiberglass", sku: "MT-100M-FG", brand: "Generic", category: "Measuring Tapes",
    price: 999, discounted_price: 799, description: "Fiberglass Measuring Tape 100 Meters.",
    specifications: { length: "100M", material: "Fiberglass" }, images: [] },

  # More Chemical Anchors
  { name: "Chemical Anchor Capsule M10", sku: "CAC-M10", brand: "Generic", category: "Chemical Anchors",
    price: 99, discounted_price: 79, description: "Chemical Anchor Capsule M10 size.",
    specifications: { size: "M10" }, images: [] },

  { name: "Chemical Anchor Capsule M12", sku: "CAC-M12", brand: "Generic", category: "Chemical Anchors",
    price: 129, discounted_price: 99, description: "Chemical Anchor Capsule M12 size.",
    specifications: { size: "M12" }, images: [] },

  { name: "Chemical Anchor Capsule M16", sku: "CAC-M16", brand: "Generic", category: "Chemical Anchors",
    price: 179, discounted_price: 139, description: "Chemical Anchor Capsule M16 size.",
    specifications: { size: "M16" }, images: [] },

  { name: "Chemical Anchor Capsule M20", sku: "CAC-M20", brand: "Generic", category: "Chemical Anchors",
    price: 249, discounted_price: 199, description: "Chemical Anchor Capsule M20 size.",
    specifications: { size: "M20" }, images: [] },

  { name: "Injection Gun for Mortar", sku: "IG-MORTAR", brand: "Generic", category: "Chemical Anchors",
    price: 1999, discounted_price: 1599, description: "Injection Gun for chemical mortar cartridges.",
    specifications: { type: "Manual" }, images: [] },

  { name: "Mixing Nozzle for Injection Mortar (Pack of 10)", sku: "MN-10PACK", brand: "Generic", category: "Chemical Anchors",
    price: 299, discounted_price: 239, description: "Mixing nozzles for injection mortar. Pack of 10.",
    specifications: { pack: "10" }, images: [] },

  # More Welding Equipment
  { name: "ARC Welding Machine 180A IGBT", sku: "ARC-180A-IGBT", brand: "Generic", category: "ARC Welding Machines",
    price: 9999, discounted_price: 7999, description: "ARC Welding Machine 180A IGBT technology.",
    specifications: { current: "180A", technology: "IGBT" }, images: [] },

  { name: "ARC Welding Machine 200A Dual Voltage", sku: "ARC-200A-DV", brand: "POLYMAK", category: "ARC Welding Machines",
    price: 13999, discounted_price: 11199, description: "ARC Welding Machine 200A. Dual voltage 110V/220V.",
    specifications: { current: "200A", voltage: "110V/220V" }, images: [] },

  { name: "ARC Welding Machine 350A 3-Phase", sku: "ARC-350A-3PH", brand: "Generic", category: "ARC Welding Machines",
    price: 21999, discounted_price: 17599, description: "ARC Welding Machine 350A 3-Phase. Industrial.",
    specifications: { current: "350A", phase: "3" }, images: [] },

  { name: "TIG Welding Machine 200A", sku: "TIG-200A", brand: "Generic", category: "ARC Welding Machines",
    price: 18999, discounted_price: 15199, description: "TIG Welding Machine 200A with torch.",
    specifications: { current: "200A", type: "TIG" }, images: [] },

  { name: "MIG Welding Machine 200A", sku: "MIG-200A", brand: "Generic", category: "ARC Welding Machines",
    price: 24999, discounted_price: 19999, description: "MIG Welding Machine 200A with wire feeder.",
    specifications: { current: "200A", type: "MIG" }, images: [] },

  { name: "Welding Cable 25mm (per meter)", sku: "WC-25MM", brand: "Generic", category: "ARC Welding Machines",
    price: 89, discounted_price: 69, description: "Welding cable 25mm. Price per meter.",
    specifications: { size: "25mm" }, images: [] },

  { name: "Welding Cable 35mm (per meter)", sku: "WC-35MM", brand: "Generic", category: "ARC Welding Machines",
    price: 119, discounted_price: 95, description: "Welding cable 35mm. Price per meter.",
    specifications: { size: "35mm" }, images: [] },

  { name: "Electrode Holder 300A", sku: "EH-300A", brand: "Generic", category: "ARC Welding Machines",
    price: 399, discounted_price: 319, description: "Electrode holder 300A capacity.",
    specifications: { capacity: "300A" }, images: [] },

  { name: "Earth Clamp 300A", sku: "EC-300A", brand: "Generic", category: "ARC Welding Machines",
    price: 299, discounted_price: 239, description: "Earth clamp 300A for welding.",
    specifications: { capacity: "300A" }, images: [] },

  { name: "Welding Rod 6013 2.5mm (5kg)", sku: "WR-6013-25-5KG", brand: "Generic", category: "ARC Welding Machines",
    price: 599, discounted_price: 479, description: "Welding electrodes 6013 2.5mm. 5kg pack.",
    specifications: { type: "6013", size: "2.5mm", weight: "5kg" }, images: [] },

  { name: "Welding Rod 6013 3.2mm (5kg)", sku: "WR-6013-32-5KG", brand: "Generic", category: "ARC Welding Machines",
    price: 649, discounted_price: 519, description: "Welding electrodes 6013 3.2mm. 5kg pack.",
    specifications: { type: "6013", size: "3.2mm", weight: "5kg" }, images: [] },

  # More Miscellaneous Tools
  { name: "Industrial Vacuum Cleaner 15L", sku: "VC-15L", brand: "Generic", category: "Vacuum Cleaners",
    price: 5999, discounted_price: 4799, description: "Compact Industrial Vacuum 15L.",
    specifications: { capacity: "15L" }, images: [] },

  { name: "Industrial Vacuum Cleaner 80L", sku: "VC-80L", brand: "POLYMAK", category: "Vacuum Cleaners",
    price: 17999, discounted_price: 14399, description: "Heavy Duty Industrial Vacuum 80L.",
    specifications: { capacity: "80L", power: "3000W" }, images: [] },

  { name: "Vacuum Cleaner with Blower 35L", sku: "VCB-35L", brand: "Generic", category: "Vacuum Cleaners",
    price: 9999, discounted_price: 7999, description: "Vacuum Cleaner with blower function. 35L.",
    specifications: { capacity: "35L", blower: "Yes" }, images: [] },

  { name: "Air Compressor Oil-Free 30L", sku: "AC-30L-OF", brand: "Generic", category: "Air Compressors",
    price: 14999, discounted_price: 11999, description: "Oil-Free Air Compressor 30L tank.",
    specifications: { tank: "30L", type: "Oil-Free" }, images: [] },

  { name: "Air Compressor Belt Drive 100L", sku: "AC-100L-BD", brand: "POLYMAK", category: "Air Compressors",
    price: 34999, discounted_price: 27999, description: "Belt Drive Air Compressor 100L tank. 3HP motor.",
    specifications: { tank: "100L", motor: "3HP", type: "Belt Drive" }, images: [] },

  { name: "Air Compressor 200L Industrial", sku: "AC-200L-IND", brand: "POLYMAK", category: "Air Compressors",
    price: 54999, discounted_price: 43999, description: "Industrial Air Compressor 200L. 5HP motor.",
    specifications: { tank: "200L", motor: "5HP" }, images: [] },

  { name: "Spray Gun HVLP", sku: "SG-HVLP", brand: "Generic", category: "Air Compressors",
    price: 1999, discounted_price: 1599, description: "HVLP Spray Gun for painting.",
    specifications: { type: "HVLP" }, images: [] },

  { name: "Air Blow Gun", sku: "ABG", brand: "Generic", category: "Air Compressors",
    price: 299, discounted_price: 239, description: "Air Blow Gun with nozzle.",
    specifications: {}, images: [] },

  { name: "Air Hose 10M", sku: "AH-10M", brand: "Generic", category: "Air Compressors",
    price: 699, discounted_price: 559, description: "Air Hose 10 Meters with fittings.",
    specifications: { length: "10M" }, images: [] },

  { name: "Car Buffer 150mm Variable Speed", sku: "CB-150-VS", brand: "Generic", category: "Car Polishers",
    price: 4499, discounted_price: 3599, description: "Car Buffer 150mm with variable speed.",
    specifications: { pad_dia: "150mm", variable_speed: "Yes" }, images: [] },

  { name: "Car Polisher Dual Action", sku: "CP-DA", brand: "POLYMAK", category: "Car Polishers",
    price: 7999, discounted_price: 6399, description: "Dual Action Car Polisher. Swirl-free finish.",
    specifications: { type: "Dual Action" }, images: [] },

  { name: "Polishing Pad Wool 180mm", sku: "PP-WOOL-180", brand: "Generic", category: "Car Polishers",
    price: 399, discounted_price: 319, description: "Wool Polishing Pad 180mm.",
    specifications: { diameter: "180mm", material: "Wool" }, images: [] },

  { name: "Polishing Pad Foam 180mm", sku: "PP-FOAM-180", brand: "Generic", category: "Car Polishers",
    price: 299, discounted_price: 239, description: "Foam Polishing Pad 180mm.",
    specifications: { diameter: "180mm", material: "Foam" }, images: [] },

  { name: "Hydraulic Floor Jack 2 Ton", sku: "HFJ-2T", brand: "Generic", category: "Hydraulic Jacks",
    price: 2999, discounted_price: 2399, description: "Hydraulic Floor Jack 2 Ton capacity.",
    specifications: { capacity: "2 Ton", type: "Floor Jack" }, images: [] },

  { name: "Hydraulic Floor Jack 3 Ton", sku: "HFJ-3T", brand: "Generic", category: "Hydraulic Jacks",
    price: 3999, discounted_price: 3199, description: "Hydraulic Floor Jack 3 Ton capacity.",
    specifications: { capacity: "3 Ton", type: "Floor Jack" }, images: [] },

  { name: "Hydraulic Trolley Jack 2.5 Ton", sku: "HTJ-2.5T", brand: "POLYMAK", category: "Hydraulic Jacks",
    price: 4999, discounted_price: 3999, description: "Hydraulic Trolley Jack 2.5 Ton.",
    specifications: { capacity: "2.5 Ton", type: "Trolley" }, images: [] },

  { name: "Jack Stand 3 Ton (Pair)", sku: "JS-3T-PAIR", brand: "Generic", category: "Hydraulic Jacks",
    price: 1499, discounted_price: 1199, description: "Jack Stands 3 Ton. Pair.",
    specifications: { capacity: "3 Ton", quantity: "Pair" }, images: [] },

  { name: "Jack Stand 6 Ton (Pair)", sku: "JS-6T-PAIR", brand: "Generic", category: "Hydraulic Jacks",
    price: 2499, discounted_price: 1999, description: "Jack Stands 6 Ton. Pair.",
    specifications: { capacity: "6 Ton", quantity: "Pair" }, images: [] }
].freeze

# =============================================================================
# CREATE PRODUCTS
# =============================================================================
created_count = 0
images_attached_count = 0

PRODUCTS_DATA.each do |data|
  images = data[:images] || []
  category_name = data[:category]
  category = find_cat(category_name)

  product = Product.find_or_initialize_by(sku: data[:sku])

  product.assign_attributes(
    name: data[:name],
    description: data[:description],
    price: data[:price],
    discounted_price: data[:discounted_price],
    brand: data[:brand],
    category: category,
    specifications: data[:specifications] || {},
    published: true
  )
  product.save!

  # Attach images - always attach if product has no images
  unless product.images.attached?
    attach_product_images(product, images, category_name)
    images_attached_count += 1 if product.images.attached?
  end

  created_count += 1
  print "\r   📦 Processing #{created_count}/#{PRODUCTS_DATA.count} products..."
end

puts "\n   ✅ Created/Updated #{created_count} products"
puts "   🖼️  Attached images to #{images_attached_count} products"
puts "   📊 Total products: #{Product.count} (#{Product.joins(:images_attachments).distinct.count} with images)"
