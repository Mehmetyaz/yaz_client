///
extension DateDifference on DateTime {
  ///
  bool operator >(DateTime other) {
    return millisecondsSinceEpoch > other.millisecondsSinceEpoch;
  }

  ///
  bool operator <(DateTime other) {
    return millisecondsSinceEpoch < other.millisecondsSinceEpoch;
  }

  ///
  bool operator >=(DateTime other) {
    return millisecondsSinceEpoch >= other.millisecondsSinceEpoch;
  }

  ///
  bool operator <=(DateTime other) {
    return millisecondsSinceEpoch <= other.millisecondsSinceEpoch;
  }

  ///
  Duration operator -(DateTime other) {
    if (this <= other) {
      return Duration(
          milliseconds:
              (other.millisecondsSinceEpoch - millisecondsSinceEpoch));
    } else {
      return Duration(
          milliseconds:
              (millisecondsSinceEpoch - other.millisecondsSinceEpoch));
    }
  }
}
