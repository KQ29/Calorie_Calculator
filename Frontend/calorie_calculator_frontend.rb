# calorie_calculator_frontend.rb
require 'tk'
require 'tkextlib/tile'  # For ttk widgets
require_relative '../Backend/calorie_calculator_backend'
require_relative '../Backend/calorie_calculator_database'

# Initialize the CalorieDatabase and CalorieCalculator instances as constants
DATABASE = CalorieDatabase.new
CALCULATOR = CalorieCalculator.new

# Ensure the database connection is closed when the application exits
at_exit do
  DATABASE.close
end

# Set up the main window
root = TkRoot.new { title "Calorie Calculator" }
root.geometry("400x300")

# Set a default font for the application
default_font = TkFont.new('family' => 'Helvetica', 'size' => 12)
TkOption.add('*Font', default_font)

# Main Menu Frame
menu_frame = Tk::Tile::Frame.new(root) { padding "20 20 20 20" }.pack(fill: 'both', expand: true)

# Title Label
Tk::Tile::Label.new(menu_frame) { text "Welcome to the Calorie Calculator"; font 'Helvetica 16 bold' }.pack(pady: 10)

# Configure the button style
Tk::Tile::Style.configure('Menu.TButton', font: default_font, padding: 5)

operations = [
  { text: 'Calculate Calories', command: proc { open_calculate_window } },
  { text: 'Add New Product', command: proc { open_add_window } },
  { text: 'Update Product', command: proc { open_update_window } },
  { text: 'Delete Product', command: proc { open_delete_window } }
]

operations.each do |op|
  Tk::Tile::Button.new(menu_frame, text: op[:text], style: 'Menu.TButton', command: op[:command]).pack(fill: 'x', pady: 5)
end

# --- Function Definitions ---

def open_calculate_window
  # Create a new top-level window
  calc_win = TkToplevel.new { title "Calculate Calories" }
  calc_win.geometry("400x300")
  
  # Close window when this window is closed
  calc_win.protocol("WM_DELETE_WINDOW") { calc_win.destroy }
  
  # Calculation UI elements
  frame = Tk::Tile::Frame.new(calc_win) { padding "10 10 10 10" }.pack(fill: 'both', expand: true)
  
  Tk::Tile::Label.new(frame) { text 'Product:' }.grid(row: 0, column: 0, sticky: 'w')
  product_entry = Tk::Tile::Entry.new(frame)
  product_entry.grid(row: 0, column: 1, pady: 5, sticky: 'we')
  
  Tk::Tile::Label.new(frame) { text 'Weight (grams):' }.grid(row: 1, column: 0, sticky: 'w')
  weight_entry = Tk::Tile::Entry.new(frame)
  weight_entry.grid(row: 1, column: 1, pady: 5, sticky: 'we')
  
  result_label = Tk::Tile::Label.new(frame) { text 'Result will be displayed here.' }
  result_label.grid(row: 3, column: 0, columnspan: 2, pady: 10)
  
  calc_button = Tk::Tile::Button.new(frame, text: 'Calculate', style: 'Menu.TButton', command: proc {
    product = product_entry.get.strip.downcase
    weight = weight_entry.get.to_f

    begin
      calories_per_100g = DATABASE.fetch_calories(product)

      if calories_per_100g
        total_calories = CALCULATOR.calculate_calories(calories_per_100g, weight)
        result_message = "#{weight}g of #{product} has #{total_calories.round(2)} calories."
        result_label.text = result_message

        # Output to file
        File.open('search_results.txt', 'a') do |file|
          file.puts("#{Time.now}: #{result_message}")
        end
      else
        result_label.text = "Product '#{product}' not found in the database."
      end
    rescue SQLite3::BusyException
      result_label.text = "Database is busy. Please try again."
    end
  })
  calc_button.grid(row: 2, column: 0, columnspan: 2, pady: 10)

  frame.grid_columnconfigure(1, weight: 1)
end

def open_add_window
  # Create a new top-level window
  add_win = TkToplevel.new { title "Add New Product" }
  add_win.geometry("400x250")
  
  frame = Tk::Tile::Frame.new(add_win) { padding "10 10 10 10" }.pack(fill: 'both', expand: true)
  
  Tk::Tile::Label.new(frame) { text 'Product Name:' }.grid(row: 0, column: 0, sticky: 'w')
  product_entry = Tk::Tile::Entry.new(frame)
  product_entry.grid(row: 0, column: 1, pady: 5, sticky: 'we')
  
  Tk::Tile::Label.new(frame) { text 'Calories per 100g:' }.grid(row: 1, column: 0, sticky: 'w')
  calories_entry = Tk::Tile::Entry.new(frame)
  calories_entry.grid(row: 1, column: 1, pady: 5, sticky: 'we')
  
  result_label = Tk::Tile::Label.new(frame) { text '' }
  result_label.grid(row: 3, column: 0, columnspan: 2, pady: 10)
  
  add_button = Tk::Tile::Button.new(frame, text: 'Add Product', style: 'Menu.TButton', command: proc {
    product = product_entry.get.strip.downcase
    calories = calories_entry.get.to_i

    if product.empty? || calories <= 0
      result_label.text = "Please enter a valid product name and calorie value."
    else
      begin
        DATABASE.add_product(product, calories)
        result_label.text = "Added '#{product}' with #{calories} calories per 100g."
        product_entry.delete(0, 'end')
        calories_entry.delete(0, 'end')
      rescue SQLite3::BusyException
        result_label.text = "Database is busy. Please try again."
      end
    end
  })
  add_button.grid(row: 2, column: 0, columnspan: 2, pady: 10)

  frame.grid_columnconfigure(1, weight: 1)
end

def open_update_window
  # Create a new top-level window
  update_win = TkToplevel.new { title "Update Product" }
  update_win.geometry("400x300")
  
  frame = Tk::Tile::Frame.new(update_win) { padding "10 10 10 10" }.pack(fill: 'both', expand: true)
  
  Tk::Tile::Label.new(frame) { text 'Product Name:' }.grid(row: 0, column: 0, sticky: 'w')
  product_entry = Tk::Tile::Entry.new(frame)
  product_entry.grid(row: 0, column: 1, pady: 5, sticky: 'we')
  
  Tk::Tile::Label.new(frame) { text 'New Calories per 100g:' }.grid(row: 1, column: 0, sticky: 'w')
  calories_entry = Tk::Tile::Entry.new(frame)
  calories_entry.grid(row: 1, column: 1, pady: 5, sticky: 'we')
  
  result_label = Tk::Tile::Label.new(frame) { text '' }
  result_label.grid(row: 3, column: 0, columnspan: 2, pady: 10)
  
  update_button = Tk::Tile::Button.new(frame, text: 'Update Product', style: 'Menu.TButton', command: proc {
    product = product_entry.get.strip.downcase
    calories = calories_entry.get.to_i

    if product.empty? || calories <= 0
      result_label.text = "Please enter a valid product name and calorie value."
    else
      begin
        if DATABASE.update_product(product, calories)
          result_label.text = "Updated '#{product}' with new calories per 100g: #{calories}."
          product_entry.delete(0, 'end')
          calories_entry.delete(0, 'end')
        else
          result_label.text = "Product '#{product}' not found."
        end
      rescue SQLite3::BusyException
        result_label.text = "Database is busy. Please try again."
      end
    end
  })
  update_button.grid(row: 2, column: 0, columnspan: 2, pady: 10)

  frame.grid_columnconfigure(1, weight: 1)
end

def open_delete_window
  # Create a new top-level window
  delete_win = TkToplevel.new { title "Delete Product" }
  delete_win.geometry("400x200")
  
  frame = Tk::Tile::Frame.new(delete_win) { padding "10 10 10 10" }.pack(fill: 'both', expand: true)
  
  Tk::Tile::Label.new(frame) { text 'Product Name:' }.grid(row: 0, column: 0, sticky: 'w')
  product_entry = Tk::Tile::Entry.new(frame)
  product_entry.grid(row: 0, column: 1, pady: 5, sticky: 'we')
  
  result_label = Tk::Tile::Label.new(frame) { text '' }
  result_label.grid(row: 2, column: 0, columnspan: 2, pady: 10)
  
  delete_button = Tk::Tile::Button.new(frame, text: 'Delete Product', style: 'Menu.TButton', command: proc {
    product = product_entry.get.strip.downcase

    if product.empty?
      result_label.text = "Please enter a product name."
    else
      begin
        if DATABASE.delete_product(product)
          result_label.text = "Deleted product '#{product}'."
          product_entry.delete(0, 'end')
        else
          result_label.text = "Product '#{product}' not found."
        end
      rescue SQLite3::BusyException
        result_label.text = "Database is busy. Please try again."
      end
    end
  })
  delete_button.grid(row: 1, column: 0, columnspan: 2, pady: 10)

  frame.grid_columnconfigure(1, weight: 1)
end

Tk.mainloop
