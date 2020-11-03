import 'package:cabdriver/providers/app_provider.dart';
import 'package:cabdriver/providers/user.dart';
import 'package:cabdriver/screens/login.dart';
import 'package:cabdriver/screens/splash.dart';
import 'package:flutter/material.dart';
import 'helpers/constants.dart';
import 'locators/service_locator.dart';
import 'screens/home.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();

  return runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<AppStateProvider>.value(
        value: AppStateProvider(),
      ),
      ChangeNotifierProvider.value(value: UserProvider.initialize()),
    ],
    child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primaryColor: Colors.deepOrange),
        title: "Flutter Taxi",
        home: MyApp()),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    UserProvider auth = Provider.of<UserProvider>(context);

    return FutureBuilder(
      // Initialize FlutterFire:
      future: initialization,
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          return Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text("Something went wrong")],
            ),
          );
        }

        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          switch (auth.status) {
            case Status.Uninitialized:
              return Splash();
            case Status.Unauthenticated:
            case Status.Authenticating:
              return LoginScreen();
            case Status.Authenticated:
              return MyHomePage();
            default:
              return LoginScreen();
          }
        }

        // Otherwise, show something whilst waiting for initialization to complete
        return Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [CircularProgressIndicator()],
          ),
        );
      },
    );
  }
}
