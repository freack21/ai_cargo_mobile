class CommandModel {
  final String type;
  final double duration;

  CommandModel({
    required this.type,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'duration': duration,
    };
  }

  factory CommandModel.fromJson(Map<String, dynamic> json) {
    return CommandModel(
      type: json['type'] ?? 'stop',
      duration: (json['duration'] ?? 1.0).toDouble(),
    );
  }

  @override
  String toString() {
    return 'CommandModel(type: $type, duration: $duration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommandModel &&
        other.type == type &&
        other.duration == duration;
  }

  @override
  int get hashCode => type.hashCode ^ duration.hashCode;
}
