import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideRequestModel {
  static const ID = "id";
  static const USERNAME = "username";
  static const USER_ID = "userId";
  static const DESTINATION = "destination";
  static const DESTINATION_LAT = "destination_latitude";
  static const DESTINATION_LNG = "destination_longitude";
  static const USER_LAT = "user_latitude";
  static const USER_LNG = "user_longitude";
  static const DISTANCE_TEXT = "distance_text";
  static const DISTANCE_VALUE = "distance_value";

  String _id;
  String _username;
  String _userId;
  String _destination;
  double _dLatitude;
  double _dLongitude;
  double _uLatitude;
  double _uLongitude;
  Distance _distance;

  String get id => _id;

  String get username => _username;

  String get userId => _userId;

  String get destination => _destination;

  double get dLatitude => _dLatitude;

  double get dLongitude => _dLongitude;

  double get uLatitude => _uLatitude;

  double get uLongitude => _uLongitude;

  Distance get distance => _distance;

  RideRequestModel.fromMap(Map data) {
    String _d = data[DESTINATION];
    _id = data[ID];
    _username = data[USERNAME];
    _userId = data[USER_ID];
    _destination = _d.substring(0, _d.indexOf(','));
    _dLatitude = double.parse(data[DESTINATION_LAT]);
    _dLongitude = double.parse(data[DESTINATION_LNG]);
    _uLatitude = double.parse(data[USER_LAT]);
    _uLongitude = double.parse(data[USER_LAT]);
    _distance = Distance.fromMap({
      "text": data[DISTANCE_TEXT],
      "value": int.parse(data[DISTANCE_VALUE])
    });
  }
}

class Distance {
  String text;
  int value;

  Distance.fromMap(Map data) {
    text = data["text"];
    value = data["value"];
  }

  Map toJson() => {"text": text, "value": value};
}

class RequestModelFirebase {
  static const ID = "id";
  static const USERNAME = "username";
  static const USER_ID = "userId";
  static const DRIVER_ID = "driverId";
  static const STATUS = "status";
  static const POSITION = "position";
  static const DESTINATION = "destination";

  String _id;
  String _username;
  String _userId;
  String _driverId;
  String _status;
  Map _position;
  Map _destination;

  String get id => _id;
  String get username => _username;
  String get userId => _userId;
  String get driverId => _driverId;
  String get status => _status;
  Map get position => _position;
  Map get destination => _destination;

  RequestModelFirebase.fromSnapshot(DocumentSnapshot snapshot) {
    _id = snapshot.data()[ID];
    _username = snapshot.data()[USERNAME];
    _userId = snapshot.data()[USER_ID];
    _driverId = snapshot.data()[DRIVER_ID];
    _status = snapshot.data()[STATUS];
    _position = snapshot.data()[POSITION];
    _destination = snapshot.data()[DESTINATION];
  }

  LatLng getCoordinates() => LatLng(_position['latitude'], _position['longitude']);
}
