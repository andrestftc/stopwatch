import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock/wakelock.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASG Timer++++++.',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Mega Timer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int? _startTime;
  int? _lapStartTime;
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  int _dSeconds = 0;
  int _lapHours = 0;
  int _lapMinutes = 0;
  int _lapSeconds = 0;
  int _lapdSeconds = 0;
  Timer? _timer;

  late FlutterTts flutterTts;

  List<String> _times = [];

  @override
  initState() {
    super.initState();
    initTts();
  }

  initTts() async {
    flutterTts = FlutterTts();

    _setAwaitOptions();

    if (Platform.isAndroid) {
      _getDefaultEngine();
    }

    await flutterTts.setLanguage("es-MX");
    await flutterTts.setVolume(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }

  Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  void _solveTime() {
    final startTime = _startTime;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (startTime != null) {
      var elapsedTime = now - startTime;
      setState(() {
        _hours = elapsedTime ~/ 3600000;
        elapsedTime %= 3600000;
        _minutes = elapsedTime ~/ 60000;
        elapsedTime %= 60000;
        _seconds = elapsedTime ~/ 1000;
        elapsedTime %= 1000;
        _dSeconds = elapsedTime ~/ 100;
      });

      final lapStartTime = _lapStartTime ?? startTime;
      elapsedTime = now - lapStartTime;
      setState(() {
        _lapHours = elapsedTime ~/ 3600000;
        elapsedTime %= 3600000;
        _lapMinutes = elapsedTime ~/ 60000;
        elapsedTime %= 60000;
        _lapSeconds = elapsedTime ~/ 1000;
        elapsedTime %= 1000;
        _lapdSeconds = elapsedTime ~/ 100;
      });
    }
  }

  String _timeString() {
    final minutes = _minutes.toString().padLeft(_hours > 0 ? 2 : 1, '0');
    final seconds = _seconds.toString().padLeft(_hours > 0 || _minutes > 0 ? 2 : 1, '0');
    var timeString = "";

    if (_hours > 0) {
      timeString += "$_hours:";
    }
    if (_hours > 0 || _minutes > 0) {
      timeString += "$minutes:";
    }
    return "$timeString$seconds.$_dSeconds";
  }

  String _lapTimeString() {
    final minutes = _lapMinutes.toString().padLeft(_lapHours > 0 ? 2 : 1, '0');
    final seconds = _lapSeconds.toString().padLeft(_lapHours > 0 || _lapMinutes > 0 ? 2 : 1, '0');
    var timeString = "";

    if (_lapHours > 0) {
      timeString += "$_lapHours:";
    }
    if (_lapHours > 0 || _lapMinutes > 0) {
      timeString += "$minutes:";
    }
    return "$timeString$seconds.$_lapdSeconds";
  }

  void _speakTime() async {
    var speech = "";

    if (_hours > 0) {
      speech += "$_hours hora${_hours == 1 ? "" : "s"},";
    }
    if (_hours > 0 || _minutes > 0) {
      speech += "$_minutes minuto${_minutes == 1 ? "" : "s"} y";
    }

    speech += "$_seconds punto $_dSeconds segundos";

    await flutterTts.speak(speech);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        title: Text(widget.title),
      ),
      backgroundColor: Colors.green[100],
      body: SafeArea(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    if (_startTime == null) {
                      _startTime = DateTime.now().millisecondsSinceEpoch;
                      _lapStartTime = null;
                      flutterTts.speak("Inicio");
                      Wakelock.enable();
                      _timer = Timer.periodic(const Duration(milliseconds: 100), (Timer t) => _solveTime());

                      setState(() {
                        _times = [];
                      });
                    } else {
                      _startTime = null;
                      _lapStartTime = null;
                      _timer?.cancel();

                      Wakelock.disable();
                      _speakTime();
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AutoSizeText(
                        _timeString(),
                        style: const TextStyle(fontFamily: "Courier", fontSize: 200),
                        maxLines: 1,
                      ),
                      if (_lapStartTime != null)
                        AutoSizeText(
                          _lapTimeString(),
                          style: const TextStyle(fontFamily: "Courier", fontSize: 50, color: Colors.blue),
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),
              ),
              Flexible(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    if (_startTime != null) {
                      setState(() {
                        _lapStartTime = DateTime.now().millisecondsSinceEpoch;
                        _times.add("${_timeString()} - ${_lapTimeString()}");
                      });
                    }
                  },
                  child: Container(
                    color: const Color(0xAAFFFFFF),
                    child: ListView.builder(
                      itemCount: _times.length,
                      itemBuilder: (context, index) => Text(
                        "${index + 1}) ${_times[index]}",
                        style: const TextStyle(fontFamily: "Courier", fontSize: 28),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
