# calorie_calculator_backend.rb
class CalorieCalculator
    def calculate_calories(calories_per_100g, weight)
      # Calculate total calories based on calories per 100g and weight
      (calories_per_100g * weight) / 100.0
    end
  end
  