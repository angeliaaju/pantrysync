// This code will populate the master tables...
const { CosmosClient } = require('@azure/cosmos');

// Cosmos DB configuration
const endpoint = ''; // Replace with your endpoint
const key = ''; // Replace with your Cosmos DB key from Azure Portal
const client = new CosmosClient({ endpoint, key });
const database = client.database('cosmicworks'); // Replace with your database ID
const container = database.container('PantryMaster');

// List of pantry items
const pantryItems = [
  // Bakery (I1-I20)
  { id: 'I1', d: 'angeliadevice', description: 'Whole Wheat Bread', category: 'Bakery', unit: 'loaf', weightPerUnit: 500 },
  { id: 'I2', d: 'angeliadevice', description: 'White Bread', category: 'Bakery', unit: 'loaf', weightPerUnit: 450 },
  { id: 'I3', d: 'angeliadevice', description: 'bagels_pack_of_six', category: 'Bakery', unit: 'pack', weightPerUnit: 600 },
  { id: 'I4', d: 'angeliadevice', description: 'Croissants', category: 'Bakery', unit: 'pack', weightPerUnit: 300 },
  { id: 'I5', d: 'angeliadevice', description: 'muffins_pack_of_four', category: 'Bakery', unit: 'pack', weightPerUnit: 400 },
  { id: 'I6', d: 'angeliadevice', description: 'donuts_pack_of_six', category: 'Bakery', unit: 'pack', weightPerUnit: 360 },
  { id: 'I7', d: 'angeliadevice', description: 'Sourdough Bread', category: 'Bakery', unit: 'loaf', weightPerUnit: 600 },
  { id: 'I8', d: 'angeliadevice', description: 'Ciabatta Rolls', category: 'Bakery', unit: 'pack', weightPerUnit: 400 },
  { id: 'I9', d: 'angeliadevice', description: 'Pita Bread', category: 'Bakery', unit: 'pack', weightPerUnit: 300 },
  { id: 'I10', d: 'angeliadevice', description: 'Baguette', category: 'Bakery', unit: 'loaf', weightPerUnit: 250 },
  { id: 'I11', d: 'angeliadevice', description: 'Rye Bread', category: 'Bakery', unit: 'loaf', weightPerUnit: 550 },
  { id: 'I12', d: 'angeliadevice', description: 'English Muffins', category: 'Bakery', unit: 'pack', weightPerUnit: 400 },
  { id: 'I13', d: 'angeliadevice', description: 'Tortilla Wraps', category: 'Bakery', unit: 'pack', weightPerUnit: 500 },
  { id: 'I14', d: 'angeliadevice', description: 'Dinner Rolls', category: 'Bakery', unit: 'pack', weightPerUnit: 300 },
  { id: 'I15', d: 'angeliadevice', description: 'Flatbread', category: 'Bakery', unit: 'pack', weightPerUnit: 400 },
  { id: 'I16', d: 'angeliadevice', description: 'Brioche', category: 'Bakery', unit: 'loaf', weightPerUnit: 400 },
  { id: 'I17', d: 'angeliadevice', description: 'Pretzels', category: 'Bakery', unit: 'pack', weightPerUnit: 300 },
  { id: 'I18', d: 'angeliadevice', description: 'Crackers', category: 'Bakery', unit: 'box', weightPerUnit: 200 },
  { id: 'I19', d: 'angeliadevice', description: 'cookies', category: 'Bakery', unit: 'pack', weightPerUnit: 250 },
  { id: 'I20', d: 'angeliadevice', description: 'Pancake Mix', category: 'Bakery', unit: 'box', weightPerUnit: 500 },

  // Dairy (I21-I40)
  { id: 'I21', d: 'angeliadevice', description: 'milk_one', category: 'Dairy', unit: 'liter', weightPerUnit: 1000 },
  { id: 'I22', d: 'angeliadevice', description: 'Cheese (Cheddar)', category: 'Dairy', unit: 'block', weightPerUnit: 200 },
  { id: 'I23', d: 'angeliadevice', description: 'Yogurt (Plain)', category: 'Dairy', unit: 'cup', weightPerUnit: 150 },
  { id: 'I24', d: 'angeliadevice', description: 'Butter', category: 'Dairy', unit: 'stick', weightPerUnit: 100 },
  { id: 'I25', d: 'angeliadevice', description: 'Cream Cheese', category: 'Dairy', unit: 'pack', weightPerUnit: 250 },
  { id: 'I26', d: 'angeliadevice', description: 'Sour Cream', category: 'Dairy', unit: 'tub', weightPerUnit: 300 },
  { id: 'I27', d: 'angeliadevice', description: 'Whipped Cream', category: 'Dairy', unit: 'can', weightPerUnit: 200 },
  { id: 'I28', d: 'angeliadevice', description: 'Cottage Cheese', category: 'Dairy', unit: 'tub', weightPerUnit: 250 },
  { id: 'I29', d: 'angeliadevice', description: 'Mozzarella', category: 'Dairy', unit: 'block', weightPerUnit: 200 },
  { id: 'I30', d: 'angeliadevice', description: 'Parmesan', category: 'Dairy', unit: 'block', weightPerUnit: 150 },
  { id: 'I31', d: 'angeliadevice', description: 'Greek Yogurt', category: 'Dairy', unit: 'cup', weightPerUnit: 170 },
  { id: 'I32', d: 'angeliadevice', description: 'Creamer', category: 'Dairy', unit: 'bottle', weightPerUnit: 500 },
  { id: 'I33', d: 'angeliadevice', description: 'Ricotta', category: 'Dairy', unit: 'tub', weightPerUnit: 250 },
  { id: 'I34', d: 'angeliadevice', description: 'Feta', category: 'Dairy', unit: 'block', weightPerUnit: 200 },
  { id: 'I35', d: 'angeliadevice', description: 'Half & Half', category: 'Dairy', unit: 'bottle', weightPerUnit: 300 },
  { id: 'I36', d: 'angeliadevice', description: 'Ice Cream', category: 'Dairy', unit: 'pint', weightPerUnit: 500 },
  { id: 'I37', d: 'angeliadevice', description: 'Gouda', category: 'Dairy', unit: 'block', weightPerUnit: 200 },
  { id: 'I38', d: 'angeliadevice', description: 'Provolone', category: 'Dairy', unit: 'block', weightPerUnit: 200 },
  { id: 'I39', d: 'angeliadevice', description: 'Brie', category: 'Dairy', unit: 'wheel', weightPerUnit: 150 },
  { id: 'I40', d: 'angeliadevice', description: 'milk_two', category: 'Dairy', unit: 'liter', weightPerUnit: 2000 },

  // Fruit & Vegetables (I41-I60)
  { id: 'I41', d: 'angeliadevice', description: 'Apples', category: 'Fruit', unit: 'kg', weightPerUnit: 1000 },
  { id: 'I42', d: 'angeliadevice', description: 'Bananas', category: 'Fruit', unit: 'bunch', weightPerUnit: 700 },
  { id: 'I43', d: 'angeliadevice', description: 'Oranges', category: 'Fruit', unit: 'kg', weightPerUnit: 1000 },
  { id: 'I44', d: 'angeliadevice', description: 'Grapes', category: 'Fruit', unit: 'kg', weightPerUnit: 1000 },
  { id: 'I45', d: 'angeliadevice', description: 'Strawberries', category: 'Fruit', unit: 'punnet', weightPerUnit: 400 },
  { id: 'I46', d: 'angeliadevice', description: 'Carrots', category: 'Vegetables', unit: 'bag', weightPerUnit: 500 },
  { id: 'I47', d: 'angeliadevice', description: 'Broccoli', category: 'Vegetables', unit: 'head', weightPerUnit: 300 },
  { id: 'I48', d: 'angeliadevice', description: 'Spinach', category: 'Vegetables', unit: 'bag', weightPerUnit: 200 },
  { id: 'I49', d: 'angeliadevice', description: 'Tomatoes', category: 'Vegetables', unit: 'kg', weightPerUnit: 1000 },
  { id: 'I50', d: 'angeliadevice', description: 'Potatoes', category: 'Vegetables', unit: 'bag', weightPerUnit: 2000 },
  { id: 'I51', d: 'angeliadevice', description: 'Lettuce', category: 'Vegetables', unit: 'head', weightPerUnit: 300 },
  { id: 'I52', d: 'angeliadevice', description: 'Cucumbers', category: 'Vegetables', unit: 'each', weightPerUnit: 200 },
  { id: 'I53', d: 'angeliadevice', description: 'Bell Peppers', category: 'Vegetables', unit: 'kg', weightPerUnit: 1000 },
  { id: 'I54', d: 'angeliadevice', description: 'Onions', category: 'Vegetables', unit: 'bag', weightPerUnit: 1000 },
  { id: 'I55', d: 'angeliadevice', description: 'Garlic', category: 'Vegetables', unit: 'bulb', weightPerUnit: 50 },
  { id: 'I56', d: 'angeliadevice', description: 'Mushrooms', category: 'Vegetables', unit: 'pack', weightPerUnit: 250 },
  { id: 'I57', d: 'angeliadevice', description: 'Zucchini', category: 'Vegetables', unit: 'each', weightPerUnit: 200 },
  { id: 'I58', d: 'angeliadevice', description: 'Celery', category: 'Vegetables', unit: 'bunch', weightPerUnit: 300 },
  { id: 'I59', d: 'angeliadevice', description: 'Cauliflower', category: 'Vegetables', unit: 'head', weightPerUnit: 600 },
  { id: 'I60', d: 'angeliadevice', description: 'Peaches', category: 'Fruit', unit: 'kg', weightPerUnit: 1000 },

  // Meat & Protein (I61-I80)
  { id: 'I61', d: 'angeliadevice', description: 'Chicken Breast', category: 'Meat', unit: 'kg', weightPerUnit: 1000 },
  { id: 'I62', d: 'angeliadevice', description: 'Ground Beef', category: 'Meat', unit: 'kg', weightPerUnit: 1000 },
  { id: 'I63', d: 'angeliadevice', description: 'Pork Chops', category: 'Meat', unit: 'kg', weightPerUnit: 1000 },
  { id: 'I64', d: 'angeliadevice', description: 'Salmon Fillet', category: 'Seafood', unit: 'kg', weightPerUnit: 1000 },
  { id: 'I65', d: 'angeliadevice', description: 'Shrimp', category: 'Seafood', unit: 'pack', weightPerUnit: 500 },
  { id: 'I66', d: 'angeliadevice', description: 'Eggs (Dozen)', category: 'Protein', unit: 'dozen', weightPerUnit: 600 },
  { id: 'I67', d: 'angeliadevice', description: 'Turkey Slices', category: 'Meat', unit: 'pack', weightPerUnit: 200 },
  { id: 'I68', d: 'angeliadevice', description: 'Bacon', category: 'Meat', unit: 'pack', weightPerUnit: 300 },
  { id: 'I69', d: 'angeliadevice', description: 'Sausages', category: 'Meat', unit: 'pack', weightPerUnit: 400 },
  { id: 'I70', d: 'angeliadevice', description: 'Tofu', category: 'Protein', unit: 'block', weightPerUnit: 300 },
  { id: 'I71', d: 'angeliadevice', description: 'Ham', category: 'Meat', unit: 'pack', weightPerUnit: 200 },
  { id: 'I72', d: 'angeliadevice', description: 'Cod Fillet', category: 'Seafood', unit: 'kg', weightPerUnit: 1000 },
  { id: 'I73', d: 'angeliadevice', description: 'Beef Steak', category: 'Meat', unit: 'kg', weightPerUnit: 1000 },
  { id: 'I74', d: 'angeliadevice', description: 'Lamb Chops', category: 'Meat', unit: 'kg', weightPerUnit: 1000 },
  { id: 'I75', d: 'angeliadevice', description: 'Tuna (Canned)', category: 'Seafood', unit: 'can', weightPerUnit: 150 },
  { id: 'I76', d: 'angeliadevice', description: 'Chicken Thighs', category: 'Meat', unit: 'kg', weightPerUnit: 1000 },
  { id: 'I77', d: 'angeliadevice', description: 'Prawns', category: 'Seafood', unit: 'pack', weightPerUnit: 400 },
  { id: 'I78', d: 'angeliadevice', description: 'Peanut Butter', category: 'Protein', unit: 'jar', weightPerUnit: 500 },
  { id: 'I79', d: 'angeliadevice', description: 'Almonds', category: 'Protein', unit: 'bag', weightPerUnit: 300 },
  { id: 'I80', d: 'angeliadevice', description: 'Lentils', category: 'Protein', unit: 'bag', weightPerUnit: 500 },

  // Beverages & Others (I81-I100)
  { id: 'I81', d: 'angeliadevice', description: 'Orange Juice', category: 'Beverages', unit: 'liter', weightPerUnit: 1000 },
  { id: 'I82', d: 'angeliadevice', description: 'Coffee Beans', category: 'Beverages', unit: 'bag', weightPerUnit: 500 },
  { id: 'I83', d: 'angeliadevice', description: 'Tea Bags', category: 'Beverages', unit: 'box', weightPerUnit: 100 },
  { id: 'I84', d: 'angeliadevice', description: 'Soda (Can)', category: 'Beverages', unit: 'can', weightPerUnit: 330 },
  { id: 'I85', d: 'angeliadevice', description: 'Water (Bottle)', category: 'Beverages', unit: 'bottle', weightPerUnit: 500 },
  { id: 'I86', d: 'angeliadevice', description: 'Wine', category: 'Beverages', unit: 'bottle', weightPerUnit: 750 },
  { id: 'I87', d: 'angeliadevice', description: 'Beer (Can)', category: 'Beverages', unit: 'can', weightPerUnit: 355 },
  { id: 'I88', d: 'angeliadevice', description: 'Olive Oil', category: 'Condiments', unit: 'bottle', weightPerUnit: 500 },
  { id: 'I89', d: 'angeliadevice', description: 'Soy Sauce', category: 'Condiments', unit: 'bottle', weightPerUnit: 300 },
  { id: 'I90', d: 'angeliadevice', description: 'Ketchup', category: 'Condiments', unit: 'bottle', weightPerUnit: 400 },
  { id: 'I91', d: 'angeliadevice', description: 'Mustard', category: 'Condiments', unit: 'bottle', weightPerUnit: 300 },
  { id: 'I92', d: 'angeliadevice', description: 'Vinegar', category: 'Condiments', unit: 'bottle', weightPerUnit: 500 },
  { id: 'I93', d: 'angeliadevice', description: 'Honey', category: 'Condiments', unit: 'jar', weightPerUnit: 250 },
  { id: 'I94', d: 'angeliadevice', description: 'Jam', category: 'Condiments', unit: 'jar', weightPerUnit: 300 },
  { id: 'I95', d: 'angeliadevice', description: 'Salt', category: 'Condiments', unit: 'box', weightPerUnit: 500 },
  { id: 'I96', d: 'angeliadevice', description: 'Pepper', category: 'Condiments', unit: 'box', weightPerUnit: 100 },
  { id: 'I97', d: 'angeliadevice', description: 'Sugar', category: 'Condiments', unit: 'bag', weightPerUnit: 1000 },
  { id: 'I98', d: 'angeliadevice', description: 'Flour', category: 'Condiments', unit: 'bag', weightPerUnit: 2000 },
  { id: 'I99', d: 'angeliadevice', description: 'Rice', category: 'Grains', unit: 'bag', weightPerUnit: 2000 },
  { id: 'I100', d: 'angeliadevice', description: 'Pasta', category: 'Grains', unit: 'bag', weightPerUnit: 1000 },
];

// Function to populate the master list
async function populateMasterList() {
  try {
    for (const item of pantryItems) {
      const { resource } = await container.items.create(item);
      console.log(`Added item: ${item.description} (ID: ${item.id})`);
    }
    console.log('Master list population completed.');
  } catch (error) {
    console.error('Error populating master list:', error.message);
  }
}

// Run the population
populateMasterList();