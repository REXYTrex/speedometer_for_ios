import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

void main() => runApp(SpeedometerApp());

class SpeedometerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Speedometer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SpeedometerHome(),
    );
  }
}

class SpeedometerHome extends StatefulWidget {
  @override
  _SpeedometerHomeState createState() => _SpeedometerHomeState();
}

class _SpeedometerHomeState extends State<SpeedometerHome> {
  double speed = 0.0;
  double distance = 0.0;
  Position? lastPosition;
  Color speedometerColor = Colors.blue;
  bool isDigital = true;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      setState(() {
        speed = position.speed * 3.6; // m/s to km/h
        if (lastPosition != null) {
          distance += Geolocator.distanceBetween(
                  lastPosition!.latitude,
                  lastPosition!.longitude,
                  position.latitude,
                  position.longitude) /
              1000; // meters to km
        }
        lastPosition = position;
      });
    });
  }

  void pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Speedometer Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: speedometerColor,
            onColorChanged: (color) => setState(() => speedometerColor = color),
            showLabel: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Done'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GPS Speedometer'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              showModalBottomSheet(
                  context: context,
                  builder: (_) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: Text('Digital Mode'),
                            trailing: Switch(
                                value: isDigital,
                                onChanged: (val) => setState(() => isDigital = val),
                                activeColor: speedometerColor),
                          ),
                          ListTile(
                            title: Text('Change Color'),
                            trailing: Icon(Icons.color_lens),
                            onTap: pickColor,
                          ),
                        ],
                      ));
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isDigital
                ? Text('${speed.toStringAsFixed(1)} km/h',
                    style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: speedometerColor))
                : CustomPaint(
                    size: Size(200, 200),
                    painter: AnalogSpeedometerPainter(speed, speedometerColor),
                  ),
            SizedBox(height: 20),
            Text('Distance: ${distance.toStringAsFixed(2)} km',
                style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

class AnalogSpeedometerPainter extends CustomPainter {
  final double speed;
  final Color color;

  AnalogSpeedometerPainter(this.speed, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    double centerX = size.width / 2;
    double centerY = size.height / 2;
    double radius = min(centerX, centerY);

    var paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(centerX, centerY), radius, paint);

    double angle = (speed / 120) * pi; // max 120 km/h
    var needlePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3;

    double needleX = centerX + radius * cos(pi / 2 - angle);
    double needleY = centerY - radius * sin(pi / 2 - angle);

    canvas.drawLine(Offset(centerX, centerY), Offset(needleX, needleY), needlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
