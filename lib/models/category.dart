class Category {
  final int id;
  final String categoryName;

  Category({required this.id, required this.categoryName});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        categoryName: json['category_name'],
      );
}
