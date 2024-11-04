# calorie_calculator_database.rb
require 'sqlite3'

class CalorieDatabase
  def initialize
    # Connect to the SQLite database (calories.db)
    @db = SQLite3::Database.new 'calories.db'
    @db.busy_timeout(1000)  # Wait up to 1000 milliseconds (1 second) if the database is busy
    @db.results_as_hash = true
    setup_database
  end

  # Set up the database with a table for products if it doesn’t exist
  def setup_database
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY,
        name TEXT UNIQUE,
        calories_per_100g INTEGER
      );
    SQL
  end

  # Method to fetch calories per 100g for a given product
  def fetch_calories(product)
    result = @db.get_first_value("SELECT calories_per_100g FROM products WHERE name = ?", product)
    result ? result.to_i : nil
  rescue SQLite3::BusyException
    puts "Database is busy. Please try again."
    nil
  end

  # Method to add a new product to the database
  def add_product(name, calories_per_100g)
    @db.transaction do
      begin
        @db.execute("INSERT INTO products (name, calories_per_100g) VALUES (?, ?)", [name, calories_per_100g])
        puts "Product '#{name}' added with #{calories_per_100g} calories per 100g."
      rescue SQLite3::ConstraintException
        @db.execute("UPDATE products SET calories_per_100g = ? WHERE name = ?", [calories_per_100g, name])
        puts "Product '#{name}' updated with new calorie value: #{calories_per_100g} calories per 100g."
      end
    end
  rescue SQLite3::BusyException
    puts "Database is busy. Please try again."
  end

  # Close the database connection when done
  def close
    @db.close if @db
  end
end
