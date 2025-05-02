class EducationData {
  final String title;
  final String description;
  final String image;

  EducationData({
    required this.title,
    required this.description,
    required this.image,
  });

  factory EducationData.fromJson(Map<String, dynamic> json) {
    return EducationData(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
    );
  }
}
