// lib/screens/recipes_screen
import 'package:flutter/material.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends StatelessWidget {
  final List<dynamic> recipes;

  const RecipesScreen({Key? key, required this.recipes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suggested Recipes'),
        backgroundColor: Colors.blue[900],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[900]!, Colors.blue[300]!],
          ),
        ),
        child:
            recipes.isEmpty
                ? Center(
                  child: Text(
                    'No recipes found',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
                : ListView.builder(
                  padding: EdgeInsets.all(16.0),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    // Extract used and missed ingredients
                    final usedIngredients =
                        recipe['usedIngredients'] as List<dynamic>? ?? [];
                    final missedIngredients =
                        recipe['missedIngredients'] as List<dynamic>? ?? [];

                    // Convert ingredient lists to comma-separated strings
                    final usedIngredientsString = usedIngredients
                        .map((ingredient) => ingredient['name'] ?? 'Unknown')
                        .join(', ');
                    final missedIngredientsString = missedIngredients
                        .map((ingredient) => ingredient['name'] ?? 'Unknown')
                        .join(', ');

                    return GestureDetector(
                      onTap: () {
                        // Pass the recipe ID as a string
                        final recipeId = recipe['id'].toString();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    RecipeDetailScreen(recipeId: recipeId),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.blue[900]!, Colors.blue[300]!],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Recipe Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    recipe['image'] ??
                                        'https://via.placeholder.com/150',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.broken_image,
                                          color: Colors.white,
                                          size: 80,
                                        ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                // Recipe Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe['title'] ?? 'Untitled Recipe',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      // Display Used Ingredients
                                      Text(
                                        'Used Ingredients:',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        usedIngredientsString.isEmpty
                                            ? 'None'
                                            : usedIngredientsString,
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      SizedBox(height: 8),
                                      // Display Missing Ingredients
                                      Text(
                                        'Missing Ingredients:',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        missedIngredientsString.isEmpty
                                            ? 'None'
                                            : missedIngredientsString,
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      SizedBox(height: 8),
                                      // Display Likes
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.favorite,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            '${recipe['likes'] ?? 0} Likes',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
