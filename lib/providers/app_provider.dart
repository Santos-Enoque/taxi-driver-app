import 'dart:async';

import 'package:cabdriver/helpers/constants.dart';
import 'package:cabdriver/helpers/style.dart';
import 'package:cabdriver/models/ride_Request.dart';
import 'package:cabdriver/models/rider.dart';
import 'package:cabdriver/models/route.dart';
import 'package:cabdriver/services/map_requests.dart';
import 'package:cabdriver/services/ride_request.dart';
import 'package:cabdriver/services/rider.dart';
import 'package:cabdriver/services/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';

enum Show { RIDER, TRIP }

class AppStateProvider with ChangeNotifier {
  static const ACCEPTED = 'accepted';
  static const CANCELLED = 'cancelled';
  static const PENDING = 'pending';
  static const EXPIRED = 'expired';
  // ANCHOR: VARIABLES DEFINITION
  Set<Marker> _markers = {};
  Set<Polyline> _poly = {};
  GoogleMapsServices _googleMapsServices = GoogleMapsServices();
  GoogleMapController _mapController;
  Position position;
  static LatLng _center;
  LatLng _lastPosition = _center;
  TextEditingController _locationController = TextEditingController();
  TextEditingController destinationController = TextEditingController();

  LatLng get center => _center;
  LatLng get lastPosition => _lastPosition;
  TextEditingController get locationController => _locationController;
  Set<Marker> get markers => _markers;
  Set<Polyline> get poly => _poly;
  GoogleMapController get mapController => _mapController;
  RouteModel routeModel;
  SharedPreferences prefs;

  Location location = new Location();
  bool hasNewRideRequest = false;
  UserServices _userServices = UserServices();
  RideRequestModel rideRequestModel;
  RequestModelFirebase requestModelFirebase;

  RiderModel riderModel;
  RiderServices _riderServices = RiderServices();
  double distanceFromRider = 0;
  double totalRideDistance = 0;
  StreamSubscription<QuerySnapshot> requestStream;
  int timeCounter = 0;
  double percentage = 0;
  Timer periodicTimer;
  RideRequestServices _requestServices = RideRequestServices();
  Show show;

  AppStateProvider() {
//    _subscribeUser();
    _saveDeviceToken();
    fcm.configure(
//      this callback is used when the app runs on the foreground
        onMessage: handleOnMessage,
//        used when the app is closed completely and is launched using the notification
        onLaunch: handleOnLaunch,
//        when its on the background and opened using the notification drawer
        onResume: handleOnResume);
    _getUserLocation();
    Geolocator().getPositionStream().listen(_userCurrentLocationUpdate);
  }

  // ANCHOR LOCATION METHODS
  _userCurrentLocationUpdate(Position updatedPosition) async {
    double distance = await Geolocator().distanceBetween(
        prefs.getDouble('lat'),
        prefs.getDouble('lng'),
        updatedPosition.latitude,
        updatedPosition.longitude);
    Map<String, dynamic> values = {
      "id": prefs.getString("id"),
      "position": updatedPosition.toJson()
    };
    if (distance >= 50) {
      if(show == Show.RIDER){
        sendRequest(coordinates: requestModelFirebase.getCoordinates());
      }
      _userServices.updateUserData(values);
      await prefs.setDouble('lat', updatedPosition.latitude);
      await prefs.setDouble('lng', updatedPosition.longitude);
    }
  }

  _getUserLocation() async {
    prefs = await SharedPreferences.getInstance();
    position = await Geolocator().getCurrentPosition();
    List<Placemark> placemark = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    _center = LatLng(position.latitude, position.longitude);
    await prefs.setDouble('lat', position.latitude);
    await prefs.setDouble('lng', position.longitude);
    _locationController.text = placemark[0].name;
    notifyListeners();
  }

  // ANCHOR MAPS METHODS

  onCreate(GoogleMapController controller) {
    _mapController = controller;
    notifyListeners();
  }

  setLastPosition(LatLng position) {
    _lastPosition = position;
    notifyListeners();
  }

  onCameraMove(CameraPosition position) {
    _lastPosition = position.target;
    notifyListeners();
  }

  void sendRequest({String intendedLocation, LatLng coordinates}) async {
    LatLng origin = LatLng(position.latitude, position.longitude);

    LatLng destination = coordinates;
    RouteModel route =
        await _googleMapsServices.getRouteByCoordinates(origin, destination);
    routeModel = route;
    addLocationMarker(
        destination, routeModel.endAddress, routeModel.distance.text);
    _center = destination;
    destinationController.text = routeModel.endAddress;

    _createRoute(route.points);
    notifyListeners();
  }

  void _createRoute(String decodeRoute) {
    _poly = {};
    var uuid = new Uuid();
    String polyId = uuid.v1();
    poly.add(Polyline(
        polylineId: PolylineId(polyId),
        width: 8,
        color: primary,
        onTap: () {},
        points: _convertToLatLong(_decodePoly(decodeRoute))));
    notifyListeners();
  }

  List<LatLng> _convertToLatLong(List points) {
    List<LatLng> result = <LatLng>[];
    for (int i = 0; i < points.length; i++) {
      if (i % 2 != 0) {
        result.add(LatLng(points[i - 1], points[i]));
      }
    }
    return result;
  }

  List _decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = new List();
    int index = 0;
    int len = poly.length;
    int c = 0;
// repeating until all attributes are decoded
    do {
      var shift = 0;
      int result = 0;

      // for decoding value of one attribute
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      /* if value is negetive then bitwise not the value */
      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

/*adding to previous value as done in encoding */
    for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];

    print(lList.toString());

    return lList;
  }

  // ANCHOR MARKERS
  addLocationMarker(LatLng position, String destination, String distance) {
    _markers = {};
    var uuid = new Uuid();
    String markerId = uuid.v1();
    _markers.add(Marker(
        markerId: MarkerId(markerId),
        position: position,
        infoWindow: InfoWindow(title: destination, snippet: distance),
        icon: BitmapDescriptor.defaultMarker));
    notifyListeners();
  }

  Future<Uint8List> getMarker(BuildContext context) async {
    ByteData byteData =
        await DefaultAssetBundle.of(context).load("images/car.png");
    return byteData.buffer.asUint8List();
  }

  clearMarkers() {
    _markers.clear();
    notifyListeners();
  }

  _saveDeviceToken() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs.getString('token') == null) {
      String deviceToken = await fcm.getToken();
      await prefs.setString('token', deviceToken);
    }
  }

// ANCHOR PUSH NOTIFICATION METHODS
  Future handleOnMessage(Map<String, dynamic> data) async {
    _handleNotificationData(data);
  }

  Future handleOnLaunch(Map<String, dynamic> data) async {
    _handleNotificationData(data);
  }

  Future handleOnResume(Map<String, dynamic> data) async {
    _handleNotificationData(data);
  }

  _handleNotificationData(Map<String, dynamic> data) async {
    hasNewRideRequest = true;
    rideRequestModel = RideRequestModel.fromMap(data['data']);
    riderModel = await _riderServices.getRiderById(rideRequestModel.userId);
    notifyListeners();
  }

// ANCHOR RIDE REQUEST METHODS
  changeRideRequestStatus() {
    hasNewRideRequest = false;
    notifyListeners();
  }

  listenToRequest({String id, BuildContext context}) async {
//    requestModelFirebase = await _requestServices.getRequestById(id);
    print("======= LISTENING =======");
    requestStream = _requestServices.requestStream().listen((querySnapshot) {
      querySnapshot.docChanges.forEach((doc) {
        if (doc.doc.data()['id'] == id) {
          requestModelFirebase = RequestModelFirebase.fromSnapshot(doc.doc);
          notifyListeners();
          switch (doc.doc.data()['status']) {
            case CANCELLED:
              print("====== CANCELELD");
              break;
            case ACCEPTED:
              print("====== ACCEPTED");
              break;
            case EXPIRED:
              print("====== EXPIRED");
              break;
            default:
              print("==== PEDING");
              break;
          }
        }
      });
    });
  }

  //  Timer counter for driver request
  percentageCounter({String requestId, BuildContext context}) {
    notifyListeners();
    periodicTimer = Timer.periodic(Duration(seconds: 1), (time) {
      timeCounter = timeCounter + 1;
      percentage = timeCounter / 100;
      print("====== GOOOO $timeCounter");
      if (timeCounter == 100) {
        timeCounter = 0;
        percentage = 0;
        time.cancel();
        hasNewRideRequest = false;
        requestStream.cancel();
      }
      notifyListeners();
    });
  }

  acceptRequest({String requestId, String driverId}) {
    hasNewRideRequest = false;
    _requestServices.updateRequest(
        {"id": requestId, "status": "accepted", "driverId": driverId});
    notifyListeners();
  }

  cancelRequest({String requestId}) {
    hasNewRideRequest = false;
    _requestServices.updateRequest({"id": requestId, "status": "cancelled"});
    notifyListeners();
  }

  //  ANCHOR UI METHODS
  changeWidgetShowed({Show showWidget}) {
    show = showWidget;
    notifyListeners();
  }
}
