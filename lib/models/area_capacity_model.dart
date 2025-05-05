class AreaCapacity {
  final int id;
  final int areaId;
  final int maxPeople;

  AreaCapacity({
    required this.id,
    required this.areaId,
    required this.maxPeople,
  });

  factory AreaCapacity.fromJson(Map<String, dynamic> json) {
    return AreaCapacity(
      id: json['id'],
      areaId: json['area_comun_id'],
      maxPeople: json['max_personas'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'area_comun_id': areaId,
      'max_personas': maxPeople,
    };
  }
}
