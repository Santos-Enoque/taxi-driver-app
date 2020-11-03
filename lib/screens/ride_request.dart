import 'package:cabdriver/helpers/stars_method.dart';
import 'package:cabdriver/helpers/style.dart';
import 'package:cabdriver/providers/app_provider.dart';
import 'package:cabdriver/providers/user.dart';
import 'package:cabdriver/widgets/custom_btn.dart';
import 'package:cabdriver/widgets/custom_text.dart';
import 'package:cabdriver/widgets/stars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

class RideRequestScreen extends StatefulWidget {
  @override
  _RideRequestScreenState createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {

  @override
  void initState() {
    super.initState();
    AppStateProvider _state = Provider.of<AppStateProvider>(context, listen: false);
    _state.listenToRequest(id: _state.rideRequestModel.id, context: context);
  }
  @override
  Widget build(BuildContext context) {
    AppStateProvider appState = Provider.of<AppStateProvider>(context);
    UserProvider userProvider = Provider.of<UserProvider>(context);

    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        centerTitle: true,
        title: CustomText(
          text: "New Ride Request",
          size: 19,
          weight: FontWeight.bold,
        ),
      ),
      backgroundColor: white,
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (appState.riderModel.photo == null)
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(40)),
                    child: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      radius: 45,
                      child: Icon(
                        Icons.person,
                        size: 65,
                        color: white,
                      ),
                    ),
                  ),
                if (appState.riderModel.photo != null)
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(40)),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundImage: NetworkImage(appState.riderModel?.photo),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(text: appState.riderModel?.name ?? "Nada"),
              ],
            ),
            SizedBox(height: 10),
            stars(
                rating: appState.riderModel.rating,
                votes: appState.riderModel.votes),
            Divider(),
            ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    text: "Destiation",
                    color: grey,
                  ),
                ],
              ),
              subtitle: FlatButton.icon(
                  onPressed: () async {
                    LatLng destinationCoordiates = LatLng(
                        appState.rideRequestModel.dLatitude,
                        appState.rideRequestModel.dLongitude);
                    appState.addLocationMarker(
                        destinationCoordiates,
                        appState.rideRequestModel?.destination ?? "Nada",
                        "Destination Location");
                    showModalBottomSheet(
                        context: context,
                        builder: (BuildContext bc) {
                          return Container(
                            height: 400,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                  target: destinationCoordiates, zoom: 13),
                              onMapCreated: appState.onCreate,
                              myLocationEnabled: true,
                              mapType: MapType.normal,
                              tiltGesturesEnabled: true,
                              compassEnabled: false,
                              markers: appState.markers,
                              onCameraMove: appState.onCameraMove,
                              polylines: appState.poly,
                            ),
                          );
                        });
                  },
                  icon: Icon(
                    Icons.location_on,
                  ),
                  label: CustomText(
                    text: appState.rideRequestModel?.destination ?? "Nada",
                    weight: FontWeight.bold,
                  )),
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FlatButton.icon(
                    onPressed: null,
                    icon: Icon(Icons.flag),
                    label: Text('User is near by')),
                FlatButton.icon(
                    onPressed: null,
                    icon: Icon(Icons.attach_money),
                    label: Text(
                        "${appState.rideRequestModel.distance.value / 500} ")),
              ],
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomBtn(
                  text: "Accept",
                  onTap: () async {
                    if (appState.requestModelFirebase.status != "pending") {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      20.0)), //this right here
                              child: Container(
                                height: 200,
                                child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CustomText(
                                            text: "Sorry! Request Expired")
                                      ],
                                    )),
                              ),
                            );
                          });
                    } else {
                      appState.clearMarkers();

                      appState.acceptRequest(
                          requestId: appState.rideRequestModel.id,
                          driverId: userProvider.userModel.id);
                      appState.changeWidgetShowed(showWidget: Show.RIDER);
                      appState.sendRequest(coordinates: appState.requestModelFirebase.getCoordinates());
//                      showDialog(
//                          context: context,
//                          builder: (BuildContext context) {
//                            return Dialog(
//                              shape: RoundedRectangleBorder(
//                                  borderRadius: BorderRadius.circular(
//                                      20.0)), //this right here
//                              child: Container(
//                                height: 200,
//                                child: Padding(
//                                  padding: const EdgeInsets.all(12.0),
//                                  child: Column(
//                                    mainAxisAlignment: MainAxisAlignment.center,
//                                    crossAxisAlignment:
//                                        CrossAxisAlignment.start,
//                                    children: [
//                                      SpinKitWave(
//                                        color: black,
//                                        size: 30,
//                                      ),
//                                      SizedBox(
//                                        height: 10,
//                                      ),
//                                      Row(
//                                        mainAxisAlignment:
//                                            MainAxisAlignment.center,
//                                        children: [
//                                          CustomText(
//                                              text:
//                                                  "Awaiting rider confirmation"),
//                                        ],
//                                      ),
//                                      SizedBox(
//                                        height: 30,
//                                      ),
//                                      LinearPercentIndicator(
//                                        lineHeight: 4,
//                                        animation: true,
//                                        animationDuration: 100000,
//                                        percent: 1,
//                                        backgroundColor:
//                                            Colors.grey.withOpacity(0.2),
//                                        progressColor: Colors.deepOrange,
//                                      ),
//                                      SizedBox(
//                                        height: 20,
//                                      ),
//                                      Row(
//                                        mainAxisAlignment:
//                                            MainAxisAlignment.center,
//                                        children: [
//                                          FlatButton(
//                                              onPressed: () {
//                                                appState.cancelRequest(requestId: appState.rideRequestModel.id);
//                                              },
//                                              child: CustomText(
//                                                text: "Cancel",
//                                                color: Colors.deepOrange,
//                                              )),
//                                        ],
//                                      )
//                                    ],
//                                  ),
//                                ),
//                              ),
//                            );
//                          });
                    }
                  },
                  bgColor: green,
                  shadowColor: Colors.greenAccent,
                ),
                CustomBtn(
                  text: "Reject",
                  onTap: () {
                    appState.clearMarkers();
                    appState.changeRideRequestStatus();
                  },
                  bgColor: red,
                  shadowColor: Colors.redAccent,
                )
              ],
            ),
          ],
        ),
      ),
    ));
  }


}
