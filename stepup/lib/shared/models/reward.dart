class Reward {
  final String id, title, brand, category, description;
  final int coinCost, sortOrder;
  final int? stock;
  final String? imageUrl;
  const Reward({required this.id, required this.title, required this.brand, required this.category, required this.description, required this.coinCost, required this.sortOrder, this.stock, this.imageUrl});
  factory Reward.fromJson(Map<String, dynamic> j) => Reward(
    id: j['id'] as String, title: j['title'] as String, brand: j['brand'] as String,
    category: j['category'] as String, description: j['description'] as String,
    coinCost: (j['coin_cost'] as num).toInt(), sortOrder: (j['sort_order'] as num? ?? 0).toInt(),
    stock: (j['stock'] as num?)?.toInt(), imageUrl: j['image_url'] as String?,
  );
}
