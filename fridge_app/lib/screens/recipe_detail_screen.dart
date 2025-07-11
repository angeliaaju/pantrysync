// lib/screens/recipe_detail/screen
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({Key? key, required this.recipeId})
    : super(key: key);

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Map<String, dynamic>? recipeDetails;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchRecipeDetails();
  }

  Future<void> fetchRecipeDetails() async {
    setState(() {
      isLoading = true;
    });

    const apiKey = 'd641881910924ef094291e9c35f267bb';
    final url =
        kIsWeb
            ? 'http://localhost:3000/recipe-info?id=${widget.recipeId}'
            : 'https://api.spoonacular.com/recipes/${widget.recipeId}/information?apiKey=$apiKey';

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(Duration(seconds: 30));
      if (response.statusCode == 200) {
        setState(() {
          recipeDetails = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to load recipe details: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching recipe details: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          recipeDetails != null ? recipeDetails!['title'] : 'Recipe Details',
        ),
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
            isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.orange))
                : errorMessage != null
                ? Center(
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.white),
                  ),
                )
                : ListView(
                  padding: EdgeInsets.all(16.0),
                  children: [
                    Card(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Recipe Image
                              if (recipeDetails!['image'] != null)
                                Center(
                                  child: Image.network(
                                    kIsWeb
                                        ? 'http://localhost:3000/image?url=${Uri.encodeComponent(recipeDetails!['image'])}'
                                        : recipeDetails!['image'],
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.broken_image,
                                          color: Colors.white,
                                          size: 50,
                                        ),
                                  ),
                                ),
                              SizedBox(height: 16),
                              // Recipe Title
                              Text(
                                recipeDetails!['title'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 12),
                              // Servings and Ready Time
                              Text(
                                'Servings: ${recipeDetails!['servings']}',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                'Ready in: ${recipeDetails!['readyInMinutes']} minutes',
                                style: TextStyle(color: Colors.white70),
                              ),
                              SizedBox(height: 12),
                              // Ingredients
                              Text(
                                'Ingredients:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              if (recipeDetails!['extendedIngredients'] != null)
                                ...recipeDetails!['extendedIngredients']
                                    .map<Widget>((ingredient) {
                                      return Text(
                                        '- ${ingredient['original']}',
                                        style: TextStyle(color: Colors.white70),
                                      );
                                    })
                                    .toList(),
                              SizedBox(height: 12),
                              // Instructions
                              Text(
                                'Instructions:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              if (recipeDetails!['analyzedInstructions'] !=
                                      null &&
                                  recipeDetails!['analyzedInstructions']
                                      .isNotEmpty &&
                                  recipeDetails!['analyzedInstructions'][0]['steps'] !=
                                      null)
                                ...recipeDetails!['analyzedInstructions'][0]['steps']
                                    .asMap()
                                    .entries
                                    .map<Widget>((entry) {
                                      int stepNumber = entry.key + 1;
                                      var step = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: Text(
                                          'Step $stepNumber: ${step['step']}',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      );
                                    })
                                    .toList()
                              else
                                Text(
                                  'No instructions available.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
