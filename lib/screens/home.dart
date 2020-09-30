import 'package:cabdriver/helpers/constants.dart';
import 'package:cabdriver/helpers/style.dart';
import 'package:cabdriver/providers/app_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import "package:google_maps_webservice/places.dart";

GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: GOOGLE_MAPS_API_KEY);


class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var scaffoldState = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          key: scaffoldState,
          drawer: Drawer(
            child: Scaffold(
              appBar: AppBar(
                title: Text("Settings"),
              ),
            ),
          ),
          body: Map(scaffoldState)),
    );
  }
}

class Map extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldState;

  Map(this.scaffoldState);

  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> {
  GoogleMapsPlaces googlePlaces;
  TextEditingController destinationController = TextEditingController();
  Color darkBlue = Colors.black;
  Color grey = Colors.grey;
  GlobalKey<ScaffoldState> scaffoldSate = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    scaffoldSate = widget.scaffoldState;
  }

  @override
  Widget build(BuildContext context) {
    AppStateProvider appState = Provider.of<AppStateProvider>(context);
    return appState.center == null
        ? Container(
            alignment: Alignment.center,
            child: Center(child: CircularProgressIndicator()),
          )
        : Stack(
            children: <Widget>[
              GoogleMap(
                initialCameraPosition:
                CameraPosition(target: appState.center, zoom: 13),
                onMapCreated: appState.onCreate,
                myLocationEnabled: true,
                mapType: MapType.normal,
                compassEnabled: true,
                markers: appState.markers,
                onCameraMove: appState.onCameraMove,
                polylines: appState.poly,
              ),
              Positioned(
                top: 10,
                left: 15,
                child: IconButton(
                    icon: Icon(
                      Icons.menu,
                      color: primary,
                      size: 30,
                    ),
                    onPressed: () {
                      scaffoldSate.currentState.openDrawer();
                    }),
              ),

              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.only(left:15.0, right: 15.0),
                    child: RaisedButton(onPressed: ()async{
                        GeoFirePoint point = GeoFirePoint(appState.center.latitude, appState.center.longitude);
                        Firestore.instance.collection("locations").add({
                          "points": point.data,
                          "name": "Taxi Driver"
                        });
                        print("it all worked");


                    }, color: darkBlue,
                      child: Text("Confirm Booking", style: TextStyle(color: white, fontSize: 16),),),
                  ),
                ),)
            ],
          );
  }

  Future<Null> displayPrediction(Prediction p) async {
       if (p != null) {
         PlacesDetailsResponse detail =
         await places.getDetailsByPlaceId(p.placeId);

         var placeId = p.placeId;
         double lat = detail.result.geometry.location.lat;
         double lng = detail.result.geometry.location.lng;

         var address = await Geocoder.local.findAddressesFromQuery(p.description);

         print(lat);
         print(lng);
       }
  }

}
