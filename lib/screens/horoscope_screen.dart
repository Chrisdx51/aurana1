import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'package:aurana/database/database_helper.dart';

class HoroscopeScreen extends StatefulWidget {
  final String zodiacSign;

  const HoroscopeScreen({Key? key, required this.zodiacSign}) : super(key: key);

  @override
  _HoroscopeScreenState createState() => _HoroscopeScreenState();
}

class _HoroscopeScreenState extends State<HoroscopeScreen> {
  String? dailyHoroscope;

  @override
  void initState() {
    super.initState();
    _loadHoroscope();
  }

  Future<void> _loadHoroscope() async {
    final dbHelper = DatabaseHelper();
    final horoscope = await dbHelper.fetchHoroscope(widget.zodiacSign);

    if (horoscope != null) {
      setState(() {
        dailyHoroscope = horoscope;
      });
    } else {
      // If no horoscope is found, set a placeholder or fetch from an API
      setState(() {
        dailyHoroscope = 'Your horoscope is on its way!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Horoscope'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: dailyHoroscope == null
            ? CircularProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            dailyHoroscope!,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
