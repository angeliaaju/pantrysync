// lib/models/pantry_item.dart

// PantryItem class
class PantryItem {
  String description;
  String category;
  double _weight;
  double _weightPerUnit;
  String unit;
  DateTime? bestBefore;

  PantryItem({
    required this.description,
    required this.category,
    required double weight,
    required double weightPerUnit,
    required this.unit,
    this.bestBefore,
  }) : _weight = weight,
       _weightPerUnit = weightPerUnit;

  double get weight => _weight;

  set weight(double value) => _weight = value;

  double get weightPerUnit => _weightPerUnit;

  set weightPerUnit(double value) => _weightPerUnit = value;

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    return PantryItem(
      description: json['description'] as String,
      category: json['category'] as String,
      weight: (json['weight'] as num).toDouble(),
      weightPerUnit: (json['weightPerUnit'] as num).toDouble(),
      unit: json['unit'] as String,
      bestBefore:
          json['bestBefore'] != null
              ? DateTime.parse(json['bestBefore'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'category': category,
      'weight': _weight,
      'weightPerUnit': _weightPerUnit,
      'unit': unit,
      'bestBefore': bestBefore?.toIso8601String(),
    };
  }
}

// DeviceState class
class DeviceState {
  String deviceId;
  DateTime lastUpdated;
  double _totalWeight;
  double? _currentHeight;
  double? _totalHeight;
  int batteryLevel;
  double? temperature;
  List<PantryItem> items;

  DeviceState({
    required this.deviceId,
    required this.lastUpdated,
    required double totalWeight,
    double? currentHeight,
    double? totalHeight,
    required this.batteryLevel,
    this.temperature,
    required this.items,
  }) : _totalWeight = totalWeight {
    // Use setters to assign values
    this.currentHeight = currentHeight;
    this.totalHeight = totalHeight;
  }

  double get totalWeight => _totalWeight;

  set totalWeight(double value) => _totalWeight = value;

  double? get currentHeight => _currentHeight;

  set currentHeight(double? value) => _currentHeight = value;

  double? get totalHeight => _totalHeight;

  set totalHeight(double? value) => _totalHeight = value;

  factory DeviceState.fromJson(Map<String, dynamic> json) {
    return DeviceState(
      deviceId: json['deviceId'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated']),
      totalWeight: (json['totalWeight'] as num).toDouble(),
      currentHeight:
          json['currentHeight'] != null
              ? (json['currentHeight'] as num).toDouble()
              : null,
      totalHeight:
          json['totalHeight'] != null
              ? (json['totalHeight'] as num).toDouble()
              : null,
      batteryLevel: json['batteryLevel'] as int,
      temperature:
          json['temperature'] != null
              ? (json['temperature'] as num).toDouble()
              : null,
      items:
          (json['items'] as List<dynamic>)
              .map((item) => PantryItem.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'lastUpdated': lastUpdated.toIso8601String(),
      'totalWeight': _totalWeight,
      'currentHeight': _currentHeight,
      'totalHeight': _totalHeight,
      'batteryLevel': batteryLevel,
      'temperature': temperature,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
