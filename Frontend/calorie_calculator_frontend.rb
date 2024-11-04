# calorie_calculator_frontend.rb
require 'tk'
require 'tkextlib/tile'  # Added to support ttk widgets
require_relative '../Backend/calorie_calculator_backend'
require_relative '../Backend/calorie_calculator_database'

# Initialize the CalorieDatabase and CalorieCalculator instances
database = CalorieDatabase.new
calculator = CalorieCalculator.new

# Ensure the database connection is closed when the application exits
at_exit do
  database.close
end

# Main window
root = TkRoot.new { title "Calorie Calculator" }
root.geometry("400x500")  # Adjusted height

# Set a default font for the application
default_font = TkFont.new('family' => 'Helvetica', 'size' => 12)

# Apply the default font to the root window
TkOption.add('*Font', default_font)

# Create frames to organize the layout using ttk widgets
main_frame = Tk::Tile::Frame.new(root) { padding "10 10 10 10" }.pack(fill: 'both', expand: true)
input_frame = Tk::Tile::Labelframe.new(main_frame) { text "Calorie Calculator"; padding "10 10 10 10" }.pack(fill: 'x', padx: 10, pady: 10)
result_frame = Tk::Tile::Frame.new(main_frame).pack(fill: 'x', padx: 10, pady: 5)
add_product_frame = Tk::Tile::Labelframe.new(main_frame) { text "Add New Product"; padding "10 10 10 10" }.pack(fill: 'x', padx: 10, pady: 10)

# Style configurations
button_style = { 'background' => '#4CAF50', 'foreground' => 'white', 'activebackground' => '#45a049', 'width' => 20 }
label_style = { 'anchor' => 'w' }

# --- Input Section ---

# Product Name
Tk::Tile::Label.new(input_frame, label_style) { text 'Product:' }.grid(row: 0, column: 0, sticky: 'w')
product_entry = Tk::Tile::Entry.new(input_frame)
product_entry.grid(row: 0, column: 1, pady: 5, sticky: 'we')

# Weight
Tk::Tile::Label.new(input_frame, label_style) { text 'Weight (grams):' }.grid(row: 1, column: 0, sticky: 'w')
weight_entry = Tk::Tile::Entry.new(input_frame)
weight_entry.grid(row: 1, column: 1, pady: 5, sticky: 'we')

# Calculate Button
Tk::Tile::Button.new(input_frame) do
  text 'Calculate Calories'
  command do
    product = product_entry.get.strip.downcase
    weight = weight_entry.get.to_f

    # Fetch calories per 100g from the database
    begin
      calories_per_100g = database.fetch_calories(product)

      if calories_per_100g
        # Calculate total calories using backend
        total_calories = calculator.calculate_calories(calories_per_100g, weight)
        result_message = "#{weight}g of #{product} has #{total_calories.round(2)} calories."
        result_label.text = result_message
      else
        result_label.text = "Product '#{product}' not found in the database."
      end
    rescue SQLite3::BusyException
      result_label.text = "Database is busy. Please try again."
    end
  end
  grid(row: 2, column: 0, columnspan: 2, pady: 10)
end

# --- Result Section ---

result_label = Tk::Tile::Label.new(result_frame, label_style) { text 'Result will be displayed here.' }
result_label.pack(fill: 'x')

# --- Add Product Section ---

# New Product Name
Tk::Tile::Label.new(add_product_frame, label_style) { text 'New Product Name:' }.grid(row: 0, column: 0, sticky: 'w')
new_product_entry = Tk::Tile::Entry.new(add_product_frame)
new_product_entry.grid(row: 0, column: 1, pady: 5, sticky: 'we')

# Calories per 100g
Tk::Tile::Label.new(add_product_frame, label_style) { text 'Calories per 100g:' }.grid(row: 1, column: 0, sticky: 'w')
new_calories_entry = Tk::Tile::Entry.new(add_product_frame)
new_calories_entry.grid(row: 1, column: 1, pady: 5, sticky: 'we')

# Add Product Button
Tk::Tile::Button.new(add_product_frame) do
  text 'Add Product'
  command do
    new_product = new_product_entry.get.strip.downcase
    calories_per_100g = new_calories_entry.get.to_i

    if new_product.empty? || calories_per_100g <= 0
      result_label.text = "Please enter a valid product name and calorie value."
    else
      begin
        database.add_product(new_product, calories_per_100g)
        result_label.text = "Added '#{new_product}' with #{calories_per_100g} calories per 100g."
        # Clear the entry fields
        new_product_entry.delete(0, 'end')
        new_calories_entry.delete(0, 'end')
      rescue SQLite3::BusyException
        result_label.text = "Database is busy. Please try again."
      end
    end
  end
  grid(row: 2, column: 0, columnspan: 2, pady: 10)
end

# Configure grid weights
input_frame.grid_columnconfigure(1, weight: 1)
add_product_frame.grid_columnconfigure(1, weight: 1)

Tk.mainloop
