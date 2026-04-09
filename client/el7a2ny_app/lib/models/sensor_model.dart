// ─────────────────────────────────────────────────────────
//  SENSOR MODELS  — matches Django REST Framework response
//
//  Expected Django endpoint: GET /api/sensors/
//  Expected JSON:
//  [
//    {
//      "id": 1,
//      "type": "gas",          // "gas" | "heat" | "smartwatch"
//      "value": "71",
//      "unit": "ppm",
//      "status": "normal",    // "normal" | "warning" | "danger"
//      "lat": 30.0444,
//      "lng": 31.2357,
//      "updated_at": "2024-01-01T12:00:00Z"
//    }, ...
//  ]
// ─────────────────────────────────────────────────────────

class SensorModel {
  final int id;
  final String type;       // "gas" | "heat" | "smartwatch"
  final String value;
  final String unit;
  final String status;     // "normal" | "warning" | "danger"
  final double lat;
  final double lng;
  final DateTime? updatedAt;

  const SensorModel({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.status,
    required this.lat,
    required this.lng,
    this.updatedAt,
  });

  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      id: json['id'] as int,
      type: json['type'] as String,
      value: json['value'].toString(),
      unit: json['unit'] as String,
      status: json['status'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'value': value,
        'unit': unit,
        'status': status,
        'lat': lat,
        'lng': lng,
        'updated_at': updatedAt?.toIso8601String(),
      };

  SensorModel copyWith({String? status, String? value}) => SensorModel(
        id: id,
        type: type,
        value: value ?? this.value,
        unit: unit,
        status: status ?? this.status,
        lat: lat,
        lng: lng,
        updatedAt: updatedAt,
      );
}

// ─────────────────────────────────────────────────────────
//  EMERGENCY REPORT MODEL
//
//  POST /api/emergency-reports/
//  Body: { sensor_id, type, lat, lng, message }
//  Response: { id, status, dispatched_at }
// ─────────────────────────────────────────────────────────

class EmergencyReportModel {
  final int? id;
  final int sensorId;
  final String type;
  final double lat;
  final double lng;
  final String message;
  final String? status;
  final DateTime? dispatchedAt;

  const EmergencyReportModel({
    this.id,
    required this.sensorId,
    required this.type,
    required this.lat,
    required this.lng,
    required this.message,
    this.status,
    this.dispatchedAt,
  });

  Map<String, dynamic> toJson() => {
        'sensor_id': sensorId,
        'type': type,
        'lat': lat,
        'lng': lng,
        'message': message,
      };

  factory EmergencyReportModel.fromJson(Map<String, dynamic> json) {
    return EmergencyReportModel(
      id: json['id'] as int?,
      sensorId: json['sensor_id'] as int,
      type: json['type'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      message: json['message'] as String,
      status: json['status'] as String?,
      dispatchedAt: json['dispatched_at'] != null
          ? DateTime.tryParse(json['dispatched_at'] as String)
          : null,
    );
  }
}
