import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nyxx_self/nyxx.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discord Time Status',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromRGBO(104, 211, 137, 1)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Discord Time Status'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int lastMinute = 100;
  bool isBotRunning = false;
  bool isLoading = false;
  var errortext = "";
  var buttontext = "Start...";

  final TextEditingController tokenController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    tokenController.dispose();
    super.dispose();
  }

  void _startDemoBot() {
    if (isLoading) {
      setState(() {
        errortext =
            "Please wait for the status to start, still initializing...";
      });
      return;
    }
    if (isBotRunning) {
      setState(() {
        errortext = "Status is already running...";
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    print("Starting bot");
    final bot = NyxxFactory.createNyxxWebsocket(tokenController.text,
        GatewayIntents.allUnprivileged | GatewayIntents.messageContent)
      ..registerPlugin(Logging()) // Default logging plugin
      ..registerPlugin(
          CliIntegration()) // Cli integration for nyxx allows stopping application via SIGTERM and SIGKILl
      ..registerPlugin(
          IgnoreExceptions()) // Plugin that handles uncaught exceptions that may occur
      ..connect();

    // every 1 second, check if the minute has changed

    // on ready
    bot.onReady.listen((event) {
      print("Bot is ready");
      setState(() {
        isBotRunning = true;
        isLoading = false;
        buttontext = "Started!";
      });

      // find am or pm

      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (lastMinute != DateTime.now().minute) {
          print("Updating presence to ${DateTime.now().minute}");

          var currentHour = 0;
          if (DateTime.now().hour > 12) {
            currentHour = DateTime.now().hour - 12;
          } else {
            currentHour = DateTime.now().hour;
          }

          var currentMinute = "";

          if (DateTime.now().minute < 10) {
            currentMinute = "0${DateTime.now().minute}";
          } else {
            currentMinute = DateTime.now().minute.toString();
          }

          var ampm = "";
          if (DateTime.now().hour > 12) {
            ampm = "PM";
          } else {
            ampm = "AM";
          }

          bot.setPresence(
            PresenceBuilder.of(
              activity: ActivityBuilder.watching(
                  "the time. It's ${currentHour}:$currentMinute $ampm for me."),
            ),
          );
          lastMinute = DateTime.now().minute;
        } else {
          print("${timer.tick} - Not updating presence");
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Spacer(),
            const Text(
              'Enter your Token',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 400,
              child: TextField(
                controller: tokenController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Token',
                ),
              ),
            ),
            // button to start the bot
            Text(
              errortext,
            ),
            ElevatedButton.icon(
                onPressed: _startDemoBot,
                label: isLoading
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          // color: Color.fromRGBO(104, 211, 137, 1),
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.rocket_launch_sharp),
                icon: Text(buttontext)),
            const Spacer(),
            InkWell(
                child:
                    const Text("Made with ❤️ by @9021007, written in Flutter"),
                onTap: () =>
                    launchUrl(Uri.parse("https://links.9021007.xyz/"))),
            // const Text("Made with ❤️ by @9021007, written in Flutter"),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
