import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:mallory_launcher/routes.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'package:http/http.dart' as http;

// Filthy global for now
double appWidth = 100;
double appHeight = 100;
double maxAmplitude = 30;
double rowHeight = appHeight +
    (iconSize * 2) +
    (maxAmplitude * 2); // apppHeight + 2 * maxAmplitude
// Icon size
double iconSize = 56;
const double textFontSize = 13;
// Number of rows
int numRows = 3;

Future<String> getConfigFile() {
  return http.read(Uri.https('github.com', 'shelson/foobar.txt'));
}

final Future<List<Application>> _getApps = DeviceApps.getInstalledApplications(
  onlyAppsWithLaunchIntent: true,
  includeSystemApps: false,
  includeAppIcons: true,
);

class SineWaveModel extends ChangeNotifier {
  final List<List<double>> _appHeights = [];

  double getAppHeight(row, index) => _appHeights[row][index];

  void initAppHeights(row, appCount) {
    for (int i = 0; i <= numRows; i++) {
      _appHeights.add([]);
    }
    for (int i = 0; i < appCount; i++) {
      _appHeights[row].add(getWaveHeight(row, i, 0));
    }
    //notifyListeners();
  }

  void handleScrollEvent(row, offsetPixels) {
    for (MapEntry entry in _appHeights[row].asMap().entries) {
      _appHeights[row][entry.key] = getWaveHeight(row, entry.key, offsetPixels);
    }
    notifyListeners();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(ChangeNotifierProvider(
      create: (context) => SineWaveModel(), child: const MyApp()));
}

double getWaveHeight(row, index, offset) {
  //print("Offset: " + offset.toString());
  double frequency = 0.009; //five wobbles across the screen
  double xValue = 0;
  xValue = (index * appWidth) - offset;
  double yValue = (maxAmplitude * sin(frequency * xValue)) + maxAmplitude;
  //print("X: " + xValue.toString());
  //print("Y: " + yValue.toString());

  return yValue;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      routes: routes,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Kids launcher'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //_MyHomePageState();

  String message = "";

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              height: rowHeight,
              color: Color.fromARGB(255, 237, 190, 209),
              child: Row(
                children: <Widget>[appListWidget(1)],
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: rowHeight,
              color: Color.fromARGB(255, 213, 235, 188),
              child: Row(
                children: <Widget>[appListWidget(2)],
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: rowHeight,
              color: Color.fromARGB(255, 226, 198, 163),
              child: Row(
                children: <Widget>[appListWidget(3)],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget appListWidget(row) {
    return FutureBuilder(
        future: _getApps,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            print("Apps: " + snapshot.data.toString());
            Provider.of<SineWaveModel>(context, listen: false)
                .initAppHeights(row, snapshot.data!.length);
            return Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is ScrollStartNotification) {
                    //_onStartScroll(scrollNotification.metrics);
                  } else if (scrollNotification is ScrollUpdateNotification) {
                    Provider.of<SineWaveModel>(context, listen: false)
                        .handleScrollEvent(
                            row, scrollNotification.metrics.pixels);
                  } else if (scrollNotification is ScrollEndNotification) {
                    Provider.of<SineWaveModel>(context, listen: false)
                        .handleScrollEvent(
                            row, scrollNotification.metrics.pixels);
                  }
                  return false;
                },
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      ApplicationWithIcon current =
                          snapshot.data![index] as ApplicationWithIcon;
                      return InkWell(
                          onTap: () {
                            DeviceApps.openApp(current.packageName);
                          },
                          child: appStackWidget(current, row, index));
                    }),
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
    return Center(child: CircularProgressIndicator());
  }

  Widget appStackWidget(ApplicationWithIcon currentApp, int row, int index) {
    return Stack(alignment: Alignment.topLeft, children: [
      Consumer<SineWaveModel>(builder: (context, heights, child) {
        return Container(
          width: appWidth,
          height: rowHeight,
          alignment: Alignment.topCenter, //define the size of text widget here
          margin: EdgeInsets.only(left: 15, top: 0, bottom: 0, right: 15),
          padding: EdgeInsets.only(
              left: 0,
              top: appHeight - heights.getAppHeight(row, index),
              bottom: heights.getAppHeight(row, index),
              right: 0),
          child: Column(children: [
            CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: iconSize / 2,
              child: Image.memory(
                currentApp.icon,
                gaplessPlayback: true,
                width: iconSize,
                height: iconSize,
              ),
            ),
            Text(
              currentApp.appName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: textFontSize,
                  fontWeight: FontWeight.normal),
            )
          ]),
        );
      }),
    ]);
  }
}
