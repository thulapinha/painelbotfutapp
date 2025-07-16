class DiaStats {
  final String data;
  final int green;
  final int red;

  DiaStats({required this.data, required this.green, required this.red});

  int get total => green + red;

  double get pctGreen => total == 0 ? 0 : (green / total) * 100;
}
