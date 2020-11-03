import 'package:cabdriver/widgets/stars.dart';

stars({int votes, double rating}) {
  if (votes == 0) {
    return StarsWidget(
      numberOfStars: 0,
    );
  } else {
    double finalRate = rating / votes;
    return StarsWidget(
      numberOfStars: finalRate.floor(),
    );
  }
}