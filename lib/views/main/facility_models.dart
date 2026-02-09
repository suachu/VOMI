class Facility {
  final String name;
  final String address;
  final String description;
  final String? phone;
  final String? hours;

  const Facility({
    required this.name,
    required this.address,
    required this.description,
    this.phone,
    this.hours,
  });
}
