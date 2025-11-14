class CommandModel {
  final String type;
  final double duration;
  final int speed;
  final int max_distance;

  CommandModel({
    required this.type,
    required this.duration,
    required this.speed,
    required this.max_distance,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'duration': duration,
      'speed': speed,
      'max_distance': max_distance,
    };
  }

  factory CommandModel.fromJson(Map<String, dynamic> json) {
    return CommandModel(
      type: json['type'] ?? 'stop',
      duration: (json['duration'] ?? 1.0).toDouble(),
      speed: (json['speed'] ?? 1.0).toInt(),
      max_distance: (json['max_distance'] ?? 10.0).toInt(),
    );
  }

  @override
  String toString() {
    return 'CommandModel(type: $type, duration: $duration, speed: $speed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommandModel &&
        other.type == type &&
        other.duration == duration &&
        other.speed == speed &&
        other.max_distance == max_distance;
  }

  @override
  int get hashCode => type.hashCode ^ duration.hashCode;
}
