import 'dart:math';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:mallory_launcher/routes.dart';
import 'package:provider/provider.dart';

// Filthy global for now
double appWidth = 90;
double maxAmplitude = 10;
// Icon size
double iconSize = 56;
const double textFontSize = 15;
// Number of rows
int numRows = 4;

// test data
int numTestApps = 50;
bool addTestApps = true;

final Future<List<Application>> _getApps = DeviceApps.getInstalledApplications(
  onlyAppsWithLaunchIntent: true,
  includeSystemApps: true,
  includeAppIcons: true,
);

double getWaveHeightAbsolute(index, offset) {
  var maxAmplitudeHere = 1;
  //print("Offset: " + offset.toString());
  double frequency = 0.002; //five wobbles across the screen
  double xValue = 0;
  xValue = (index * appWidth) - offset;
  double yValue = (maxAmplitudeHere * sin(frequency * xValue));
  //print("X: " + xValue.toString());
  //print("Y: " + yValue.toString());

  return yValue;
}

class SineWaveModel extends ChangeNotifier {
  final List<double> _appHeights = [];

  double getAppHeight(index) => _appHeights[index];

  void initAppHeights(appCount) {
    for (int i = 0; i < appCount; i++) {
      _appHeights.add(getWaveHeightAbsolute(i, 0));
    }
    //notifyListeners();
  }

  void handleScrollEvent(offsetPixels) {
    for (MapEntry entry in _appHeights.asMap().entries) {
      _appHeights[entry.key] = getWaveHeightAbsolute(entry.key, offsetPixels);
    }
    notifyListeners();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(ChangeNotifierProvider(
      create: (context) => SineWaveModel(), child: const MyApp()));
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
        body: Center(
      child: appGridWidget(),
    ));
  }

  Widget appGridWidget() {
    return FutureBuilder(
        future: _getApps,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Provider.of<SineWaveModel>(context, listen: false)
            //    .initAppHeights(snapshot.data!.length);
            Provider.of<SineWaveModel>(context, listen: false)
                .initAppHeights(numTestApps);
            return NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification is ScrollStartNotification) {
                  //_onStartScroll(scrollNotification.metrics);
                } else if (scrollNotification is ScrollUpdateNotification) {
                  Provider.of<SineWaveModel>(context, listen: false)
                      .handleScrollEvent(scrollNotification.metrics.pixels);
                } else if (scrollNotification is ScrollEndNotification) {
                  Provider.of<SineWaveModel>(context, listen: false)
                      .handleScrollEvent(scrollNotification.metrics.pixels);
                }
                return false;
              },
              child: GridView.count(
                childAspectRatio: 2,
                mainAxisSpacing: 10,
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                crossAxisCount: numRows,
                physics: const BouncingScrollPhysics(),
                children: List.generate(snapshot.data!.length, (index) {
                      ApplicationWithIcon current =
                          snapshot.data![index] as ApplicationWithIcon;
                      return iconContainer(current, index);
                    }) +
                    List.generate(numTestApps, (index) {
                      return iconContainer(
                          snapshot
                              .data![index.remainder(snapshot.data!.length)],
                          index); // Use the first
                    }),
                //children:
                //    List.generate(numTestApps, (index) => basicText(index)),
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  Widget iconContainer(currentApp, index) {
    return Consumer<SineWaveModel>(builder: (context, heights, child) {
      double waveAppHeight = heights.getAppHeight(index);
      return Container(
        //height: 100,
        child: Align(
          alignment: Alignment(0, waveAppHeight),
          child: appIconWidget(waveAppHeight, currentApp),
        ),
      );
    });
  }

  Widget appIconWidget(waveAppHeight, currentApp) {
    return Wrap(
      direction: Axis.vertical,
      spacing: 5,
      alignment: WrapAlignment.center,
      children: [
        Image.memory(currentApp.icon,
            width: iconSize,
            height: iconSize,
            alignment: Alignment.centerRight,
            gaplessPlayback: true),
        Text(
          currentApp.appName,
          style: const TextStyle(fontSize: textFontSize),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
