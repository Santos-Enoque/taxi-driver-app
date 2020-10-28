import 'package:cabdriver/helpers/constants.dart';
import 'package:cabdriver/helpers/screen_navigation.dart';
import 'package:cabdriver/helpers/style.dart';
import 'package:cabdriver/providers/app_provider.dart';
import 'package:cabdriver/providers/user.dart';
import 'package:cabdriver/screens/login.dart';
import 'package:cabdriver/screens/ride_request.dart';
import 'package:cabdriver/screens/splash.dart';
import 'package:cabdriver/widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import "package:google_maps_webservice/places.dart";
import 'package:shared_preferences/shared_preferences.dart';

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
  void initState() {
    super.initState();
    _deviceToken();
    _updatePosition();
  }

  _deviceToken() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    UserProvider _user = Provider.of<UserProvider>(context, listen: false);

    if (_user.userModel.token != preferences.getString('token')) {
      Provider.of<UserProvider>(context, listen: false).saveDeviceToken();
    }
  }

  _updatePosition() async {
    //    this section down here will update the drivers current position on the DB when the app is opened
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    String _id = _prefs.getString("id");
    UserProvider _user = Provider.of<UserProvider>(context, listen: false);
    AppStateProvider _app =
        Provider.of<AppStateProvider>(context, listen: false);
    _user.updateUserData({"id": _id, "position": _app.position.toJson()});
  }

  @override
  Widget build(BuildContext context) {
    AppStateProvider appState = Provider.of<AppStateProvider>(context);
    UserProvider userProvider = Provider.of<UserProvider>(context);
    Widget home = SafeArea(
      child: Scaffold(
          key: scaffoldState,
          drawer: Drawer(
              child: ListView(
            children: [
              UserAccountsDrawerHeader(
                  accountName: CustomText(
                    text: userProvider.userModel?.name ?? "",
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                  accountEmail: CustomText(
                    text: userProvider.userModel?.email ?? "",
                  )),
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: CustomText(text: "Log out"),
                onTap: () {
                  userProvider.signOut();
                  changeScreenReplacement(context, LoginScreen());
                },
              )
            ],
          )),
          body: Map(scaffoldState)),
    );

    switch (appState.hasNewRideRequest) {
      case false:
        return home;
      case true:
        return RideRequestScreen();
      default:
        return home;
    }
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
  String position = "postion";

  @override
  void initState() {
    super.initState();
    scaffoldSate = widget.scaffoldState;
  }

  @override
  Widget build(BuildContext context) {
    AppStateProvider appState = Provider.of<AppStateProvider>(context);
    return appState.center == null
        ? Splash()
        : Stack(
            children: <Widget>[
              GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: appState.center, zoom: 13),
                onMapCreated: appState.onCreate,
                myLocationEnabled: true,
                mapType: MapType.normal,
                tiltGesturesEnabled: true,
                compassEnabled: false,
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
            ],
          );
  }
}
