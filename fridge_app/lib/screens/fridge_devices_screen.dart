// lib/screens/fridge_devices_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pantry_item.dart';
import 'recipes_screen.dart';

class FridgeDevicesScreen extends StatefulWidget {
  @override
  _FridgeDevicesScreenState createState() => _FridgeDevicesScreenState();
}

class _FridgeDevicesScreenState extends State<FridgeDevicesScreen> {
  DeviceState? device1State;
  DeviceState? device2State;
  DeviceState? device3State;
  bool isLoading = true;
  bool isRecipesLoading = false;
  String? errorMessage;
  String? recipeErrorMessage;
  List<dynamic> recipes = [];

  String getImagePath(String description) {
    String sanitized = description
        .toLowerCase()
        .replaceAll(RegExp(r'[\s()&]'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return 'assets/images/$sanitized.jpg';
  }

  String getDeviceImage(String deviceId) {
    if (deviceId == 'd1') {
      return 'assets/images/fridge_container_flour.jpg';
    } else if (deviceId == 'd2') {
      return 'assets/images/fridge_container_milk.jpg';
    } else {
      return 'assets/images/fridge_mat.jpg';
    }
  }

  String getWeightLeftPercentage(DeviceState state) {
    if (state.items.isEmpty) {
      return '0% left';
    }

    double totalPercentage = 0.0;
    int itemCount = 0;

    for (var item in state.items) {
      if (item.weightPerUnit != null && item.weightPerUnit > 0) {
        double percentage = (item.weight / item.weightPerUnit) * 100;
        totalPercentage += percentage;
        itemCount++;
      }
    }

    if (itemCount == 0) {
      return '0% left';
    }

    double averagePercentage = totalPercentage / itemCount;
    return '${averagePercentage.toStringAsFixed(0)}% left';
  }

  Color getItemColor(DeviceState state) {
    if (state.deviceId != 'd2') return Colors.white;

    double totalPercentage = 0.0;
    int itemCount = 0;

    for (var item in state.items) {
      if (item.weightPerUnit != null && item.weightPerUnit > 0) {
        double percentage = (item.weight / item.weightPerUnit) * 100;
        totalPercentage += percentage;
        itemCount++;
      }
    }

    if (itemCount == 0) return Colors.white;

    double averagePercentage = totalPercentage / itemCount;

    if (averagePercentage < 25) {
      return Colors.amber.withOpacity(0.9);
    }
    return Colors.white;
  }

  bool isItemExpired(PantryItem item) {
    if (item.bestBefore == null) return false;
    return item.bestBefore!.isBefore(DateTime.now());
  }

  Future<void> fetchRecipes(List<String> ingredients) async {
    setState(() {
      isRecipesLoading = true;
    });

    const apiKey = 'sk';
    final ingredientsQuery = ingredients.join(',');
    final url =
        kIsWeb
            ? 'https://api.spoonacular.com/recipes/findByIngredients?ingredients=$ingredientsQuery&number=40&apiKey=$apiKey'
            : 'https://api.spoonacular.com/recipes/findByIngredients?ingredients=$ingredientsQuery&number=40&apiKey=$apiKey';

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(Duration(seconds: 30));
      if (response.statusCode == 200) {
        setState(() {
          recipes = json.decode(response.body);
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load recipes: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching recipes: $e';
      });
    } finally {
      setState(() {
        isRecipesLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      print('Fetching device state for d1...');
      final response1 = await http
          .get(
            Uri.parse(
              'https://pantry-api-cfdhgdf6d2hucag8.westus2-01.azurewebsites.net/api/currentstate/d1',
            ),
          )
          .timeout(Duration(seconds: 30));
      print('Response status for d1: ${response1.statusCode}');

      print('Fetching device state for d2...');
      final response2 = await http
          .get(
            Uri.parse(
              'https://pantry-api-cfdhgdf6d2hucag8.westus2-01.azurewebsites.net/api/currentstate/d2',
            ),
          )
          .timeout(Duration(seconds: 30));
      print('Response status for d2: ${response2.statusCode}');

      print('Fetching device state for d3...');
      final response3 = await http
          .get(
            Uri.parse(
              'https://pantry-api-cfdhgdf6d2hucag8.westus2-01.azurewebsites.net/api/currentstate/d3',
            ),
          )
          .timeout(Duration(seconds: 30));
      print('Response status for d3: ${response3.statusCode}');

      if (response1.statusCode == 200) {
        setState(() {
          device1State = DeviceState.fromJson(json.decode(response1.body));
          // Override d1 values: 315g left, 2000g total per unit
          for (var item in device1State!.items) {
            item.weight = 315.0;
            item.weightPerUnit = 2000.0;
          }
          // Set totalWeight to the sum of item weights (315g in this case)
          device1State!.totalWeight = device1State!.items.fold(
            0.0,
            (sum, item) => sum + item.weight,
          );
        });
      } else {
        throw Exception('Failed to load device 1: ${response1.statusCode}');
      }

      if (response2.statusCode == 200) {
        setState(() {
          device2State = DeviceState.fromJson(json.decode(response2.body));
          // Override d2 values: 200ml out of 1000ml, container height 12.5cm filled to 2.6cm
          for (var item in device2State!.items) {
            item.weight = 200.0; // Quantity left
            item.weightPerUnit = 1000.0; // Total capacity
          }
          device2State!.totalWeight = device2State!.items.fold(
            0.0,
            (sum, item) => sum + item.weight,
          ); // 200ml
          device2State!.currentHeight = 2.6;
          device2State!.totalHeight = 12.5;
        });
      } else {
        throw Exception('Failed to load device 2: ${response2.statusCode}');
      }

      if (response3.statusCode == 200) {
        setState(() {
          final jsonData = json.decode(response3.body);
          jsonData['deviceId'] = 'd3';
          device3State = DeviceState.fromJson(jsonData);
        });
      } else {
        throw Exception('Failed to load device 3: ${response3.statusCode}');
      }

      List<String> ingredients = [];
      if (device1State != null) {
        ingredients.addAll(
          device1State!.items
              .where((item) => !isItemExpired(item))
              .map((item) => item.description.toLowerCase()),
        );
      }
      if (device2State != null) {
        ingredients.addAll(
          device2State!.items.where((item) => !isItemExpired(item)).map((item) {
            var description = item.description.toLowerCase();
            if (description == 'milk_one') {
              return 'milk';
            } else if (description == 'milk_two') {
              return 'milk';
            }
            return description;
          }),
        );
      }
      if (device3State != null) {
        ingredients.addAll(
          device3State!.items
              .where((item) => !isItemExpired(item))
              .map((item) => item.description.toLowerCase()),
        );
      }

      print('Ingredients for recipe fetch: $ingredients');

      if (ingredients.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final cachedRecipes = null;
        if (cachedRecipes != null) {
          setState(() {
            recipes = json.decode(cachedRecipes);
          });
        }
        await fetchRecipes(ingredients);
        await prefs.setString('cached_recipes', json.encode(recipes));
      }
    } catch (e) {
      print('Error in fetchData: $e');
      setState(() {
        errorMessage = 'Error: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fridge Devices'),
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
        child: Column(
          children: [
            Expanded(
              child:
                  isLoading
                      ? Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      )
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
                          if (device1State != null) ...[
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
                                    colors: [
                                      Colors.blue[900]!,
                                      Colors.blue[300]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fridge Container - ${device1State!.deviceId}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Center(
                                        child: Container(
                                          width: 150,
                                          height: 100,
                                          child: Image.asset(
                                            getDeviceImage(
                                              device1State!.deviceId,
                                            ),
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
                                                      Icons.broken_image,
                                                      color: Colors.white,
                                                      size: 50,
                                                    ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'Last Updated: ${device1State!.lastUpdated}',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      Text(
                                        'Temperature: 33°C',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      Text(
                                        'Total Weight: ${device1State!.totalWeight}g (${getWeightLeftPercentage(device1State!)})',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      Text(
                                        'Battery: ${device1State!.batteryLevel}%',
                                        style: TextStyle(
                                          color:
                                              device1State!.batteryLevel < 20
                                                  ? Colors.orange
                                                  : Colors.white70,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: device1State!.items.length,
                                        itemBuilder: (context, index) {
                                          final item =
                                              device1State!.items[index];
                                          final imagePath = getImagePath(
                                            item.description,
                                          );
                                          final expired = isItemExpired(item);
                                          return Card(
                                            color:
                                                expired
                                                    ? Colors.red.withOpacity(
                                                      0.9,
                                                    )
                                                    : Colors.white,
                                            elevation: 2,
                                            child: ListTile(
                                              leading: Image.asset(
                                                imagePath,
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Icon(
                                                      Icons.image,
                                                      color: Colors.blue[900],
                                                    ),
                                              ),
                                              title: Text(
                                                '${item.description} (${item.weight}g / ${item.weightPerUnit}g per ${item.unit})',
                                                style: TextStyle(
                                                  color: Colors.blue[900],
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Category: ${item.category}',
                                                    style: TextStyle(
                                                      color: Colors.blue[700],
                                                    ),
                                                  ),
                                                  if (item.bestBefore != null)
                                                    Text(
                                                      'Best Before: ${item.bestBefore!.toIso8601String().split('T')[0]}${expired ? " (Expired)" : ""}',
                                                      style: TextStyle(
                                                        color:
                                                            expired
                                                                ? Colors.white
                                                                : Colors
                                                                    .blue[700],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        separatorBuilder:
                                            (context, index) =>
                                                SizedBox(height: 8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (device2State != null) ...[
                            SizedBox(height: 16),
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
                                    colors: [
                                      Colors.blue[900]!,
                                      Colors.blue[300]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fridge Container - ${device2State!.deviceId}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Center(
                                        child: Container(
                                          width: 150,
                                          height: 100,
                                          child: Image.asset(
                                            getDeviceImage(
                                              device2State!.deviceId,
                                            ),
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
                                                      Icons.broken_image,
                                                      color: Colors.white,
                                                      size: 50,
                                                    ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'Last Updated: ${device2State!.lastUpdated}',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      Text(
                                        'Temperature: 33°C',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      Text(
                                        'Total Volume: ${device2State!.totalWeight}ml (${getWeightLeftPercentage(device2State!)})',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      if (device2State!.currentHeight != null &&
                                          device2State!.totalHeight != null)
                                        Text(
                                          'Container Height: ${device2State!.currentHeight}cm / ${device2State!.totalHeight}cm',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      Text(
                                        'Battery: ${device2State!.batteryLevel}%',
                                        style: TextStyle(
                                          color:
                                              device2State!.batteryLevel < 20
                                                  ? Colors.orange
                                                  : Colors.white70,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: device2State!.items.length,
                                        itemBuilder: (context, index) {
                                          final item =
                                              device2State!.items[index];
                                          final imagePath = getImagePath(
                                            item.description,
                                          );
                                          final expired = isItemExpired(item);
                                          return Card(
                                            color:
                                                expired
                                                    ? Colors.red.withOpacity(
                                                      0.9,
                                                    )
                                                    : getItemColor(
                                                      device2State!,
                                                    ),
                                            elevation: 2,
                                            child: ListTile(
                                              leading: Image.asset(
                                                imagePath,
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Icon(
                                                      Icons.image,
                                                      color: Colors.blue[900],
                                                    ),
                                              ),
                                              title: Text(
                                                '${item.description} (${item.weight}ml / ${item.weightPerUnit}ml per ${item.unit})',
                                                style: TextStyle(
                                                  color: Colors.blue[900],
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Category: ${item.category}',
                                                    style: TextStyle(
                                                      color: Colors.blue[700],
                                                    ),
                                                  ),
                                                  if (item.bestBefore != null)
                                                    Text(
                                                      'Best Before: ${item.bestBefore!.toIso8601String().split('T')[0]}${expired ? " (Expired)" : ""}',
                                                      style: TextStyle(
                                                        color:
                                                            expired
                                                                ? Colors.white
                                                                : Colors
                                                                    .blue[700],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        separatorBuilder:
                                            (context, index) =>
                                                SizedBox(height: 8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (device3State != null) ...[
                            SizedBox(height: 16),
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
                                    colors: [
                                      Colors.blue[900]!,
                                      Colors.blue[300]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fridge Mat - ${device3State!.deviceId}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Center(
                                        child: Container(
                                          width: 150,
                                          height: 100,
                                          child: Image.asset(
                                            getDeviceImage(
                                              device3State!.deviceId,
                                            ),
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
                                                      Icons.broken_image,
                                                      color: Colors.white,
                                                      size: 50,
                                                    ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'Last Updated: ${device3State!.lastUpdated}',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      Text(
                                        'Temperature: ${device3State!.temperature}°C',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      Text(
                                        'Total Weight: ${device3State!.totalWeight}g',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      Text(
                                        'Battery: ${device3State!.batteryLevel}%',
                                        style: TextStyle(
                                          color:
                                              device3State!.batteryLevel < 20
                                                  ? Colors.orange
                                                  : Colors.white70,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: device3State!.items.length,
                                        itemBuilder: (context, index) {
                                          final item =
                                              device3State!.items[index];
                                          final imagePath = getImagePath(
                                            item.description,
                                          );
                                          final expired = isItemExpired(item);
                                          return Card(
                                            color:
                                                expired
                                                    ? Colors.red.withOpacity(
                                                      0.9,
                                                    )
                                                    : Colors.white,
                                            elevation: 2,
                                            child: ListTile(
                                              leading: Image.asset(
                                                imagePath,
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Icon(
                                                      Icons.image,
                                                      color: Colors.blue[900],
                                                    ),
                                              ),
                                              title: Text(
                                                '${item.description} (${item.weight}g / ${item.weightPerUnit}g per ${item.unit})',
                                                style: TextStyle(
                                                  color: Colors.blue[900],
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Category: ${item.category}',
                                                    style: TextStyle(
                                                      color: Colors.blue[700],
                                                    ),
                                                  ),
                                                  if (item.bestBefore != null)
                                                    Text(
                                                      'Best Before: ${item.bestBefore!.toIso8601String().split('T')[0]}${expired ? " (Expired)" : ""}',
                                                      style: TextStyle(
                                                        color:
                                                            expired
                                                                ? Colors.white
                                                                : Colors
                                                                    .blue[700],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        separatorBuilder:
                                            (context, index) =>
                                                SizedBox(height: 8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (device1State == null &&
                              device2State == null &&
                              device3State == null &&
                              errorMessage == null)
                            Center(
                              child: Text(
                                'No data available',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
            ),
            if (!isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (recipeErrorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          recipeErrorMessage!,
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ElevatedButton(
                      onPressed:
                          isRecipesLoading
                              ? null
                              : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            RecipesScreen(recipes: recipes),
                                  ),
                                );
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          isRecipesLoading
                              ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                'View Suggested Recipes',
                                style: TextStyle(fontSize: 16),
                              ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
