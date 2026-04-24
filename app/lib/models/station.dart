class Station {
  final String signature;
  final String name;

  Station({required this.signature, required this.name});

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      signature: json['signature'] as String,
      name: json['name'] as String,
    );
  }
}
