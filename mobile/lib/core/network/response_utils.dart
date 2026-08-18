List<dynamic> extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    final d = data['data'];
    if (d is List) return d;
    final items = data['items'];
    if (items is List) return items;
    return [];
  }
  return [];
}
