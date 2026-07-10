final _naturalParts = RegExp(r'\d+|\D+');

int naturalCompare(String left, String right) {
  final leftValue = left.toLowerCase();
  final rightValue = right.toLowerCase();
  final leftParts = _naturalParts
      .allMatches(leftValue)
      .map((match) => match.group(0)!)
      .toList();
  final rightParts = _naturalParts
      .allMatches(rightValue)
      .map((match) => match.group(0)!)
      .toList();

  final length = leftParts.length < rightParts.length
      ? leftParts.length
      : rightParts.length;
  for (var index = 0; index < length; index++) {
    final leftPart = leftParts[index];
    final rightPart = rightParts[index];
    final leftNumber = BigInt.tryParse(leftPart);
    final rightNumber = BigInt.tryParse(rightPart);
    final comparison = leftNumber != null && rightNumber != null
        ? leftNumber.compareTo(rightNumber)
        : leftPart.compareTo(rightPart);
    if (comparison != 0) return comparison;
    if (leftNumber != null && leftPart.length != rightPart.length) {
      return leftPart.length.compareTo(rightPart.length);
    }
  }
  final partCountComparison = leftParts.length.compareTo(rightParts.length);
  if (partCountComparison != 0) return partCountComparison;
  return leftValue.compareTo(rightValue);
}
