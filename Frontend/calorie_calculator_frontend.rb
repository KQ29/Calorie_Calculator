# calorie_calculator_frontend.rb
require 'tk'
require_relative '../Backend/calorie_calculator_backend'
require_relative '../Backend/calorie_calculator_database'

# Initialize the CalorieDatabase and CalorieCalculator instances
database = CalorieDatabase.new
calculator = CalorieCalculator.new

# Main window
root = TkRoot.new { title "Calorie Calculator" }
root.geometry("400x600")  # Adjusted height to accommodate all widgets

# Label and entry for product name
TkLabel.new(root) { text 'Product:' }.pack(padx: 15, pady: 5, side: 'top')
product_entry = TkEntry.new(root)
product_entry.pack(padx: 15, pady: 5, side: 'top')

# Label and entry for weight
TkLabel.new(root) { text 'Weight (grams):' }.pack(padx: 15, pady: 5, side: 'top')
weight_entry = TkEntry.new(root)
weight_entry.pack(padx: 15, pady: 5, side: 'top')

# Label to display the result
result_label = TkLabel.new(root) { text 'Result: ' }
result_label.pack(padx: 15, pady: 10, side: 'top')

# Button to calculate calories
TkButton.new(root) do
  text 'Calculate Calories'
  command do
    product = product_entry.get.strip.downcase
    weight = weight_entry.get.to_f

    # Fetch calories per 100g from the database
    calories_per_100g = database.fetch_calories(product)

    if calories_per_100g
      # Calculate total calories using backend
      total_calories = calculator.calculate_calories(calories_per_100g, weight)
      result_label.text = "Result: #{weight}g of #{product} has #{total_calories.round(2)} calories."
    else
      result_label.text = "Product '#{product}' not found in the database."
    end
  end
  pack(padx: 15, pady: 10, side: 'top')
end

# Separator
TkLabel.new(root) { text '--- Add New Product ---' }.pack(padx: 15, pady: 15, side: 'top')

# Label and entries for adding a new product to the database
TkLabel.new(root) { text 'New Product Name:' }.pack(padx: 15, pady: 5, side: 'top')
new_product_entry = TkEntry.new(root)
new_product_entry.pack(padx: 15, pady: 5, side: 'top')

TkLabel.new(root) { text 'Calories per 100g:' }.pack(padx: 15, pady: 5, side: 'top')
new_calories_entry = TkEntry.new(root)
new_calories_entry.pack(padx: 15, pady: 5, side: 'top')

# Button to add a new product
TkButton.new(root) do
  text 'Add Product'
  command do
    new_product = new_product_entry.get.strip.downcase
    calories_per_100g = new_calories_entry.get.to_i

    if new_product.empty? || calories_per_100g <= 0
      result_label.text = "Please enter a valid product name and calorie value."
    else
      database.add_product(new_product, calories_per_100g)
      result_label.text = "Added '#{new_product}' with #{calories_per_100g} calories per 100g."
      # Clear the entry fields
      new_product_entry.delete(0, 'end')
      new_calories_entry.delete(0, 'end')
    end
  end
  pack(padx: 15, pady: 10, side: 'top')
end

Tk.mainloop
