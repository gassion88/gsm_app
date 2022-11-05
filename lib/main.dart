import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import 'package:gsm_app/const.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'GSMm1'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: MainWidget());
  }
}

class MainWidget extends StatefulWidget {
  MainWidget({super.key});

  @override
  State<MainWidget> createState() => _MainState();
}

class _MainState extends State<MainWidget> with SingleTickerProviderStateMixin {
  late Response request;
  late bool autoSMS = false;
  late bool dat = false;
  late List data;
  late Animation<double> animation;
  late AnimationController controller;
  late bool doun = false;
  late bool sending = false;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(vsync: this, duration: Duration(seconds: 10));
    Tween<double> tween = Tween<double>(begin: 0.0, end: 1.0);
    animation = tween.animate(controller);
    animation.addListener(() {
      setState(() {});
    });
    controller.forward();
    animation.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        await _sendRequest();
        _sendSMS();
      } else if (status == AnimationStatus.dismissed) controller.forward();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<List> _sendRequest() async {
    try {
      setState(() {
        doun = true;
        print('Получение данных');
      });
      Dio dio = Dio();
      request = await dio.get('https://hvarna.ru/api/v1/gsm/sms');
      dat = true;

      //print(data);
      setState(() {
        doun = false;
        print('Завершение получения данных');
      });

      return data = request.data;
    } catch (e) {
      throw Text('${e}');
    }
  }

  void _sendSMS() async {
    setState(() {
      sending = true;
      print('Отправка смс');
    });

    timer = Timer(const Duration(milliseconds: 2000), () {
      setState(() {
        sending = false;
        print('Завершение отправки');
        controller.value = 0.0;
        controller.forward();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        ProfileButton(
            title: 'Auto mode',
            isButtonActive: autoSMS,
            onTap: (value) {
              dat = value;
              autoSMS = value;
              //_sendRequest();
            }),
        Expanded(
          child: Row(
            children: const [
              Expanded(
                  child: Center(
                child: Text('Отправлено'),
              )),
              Expanded(
                  child: Center(
                child: Text('Ошибки'),
              ))
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('История'),
                ],
              ),
              const SizedBox(height: 10),
              doun
                  ? const Text(
                      'Получение данных...',
                      style: TextStyle(color: Colors.orange),
                    )
                  : const SizedBox(
                      height: 5,
                    ),
              sending
                  ? const Text(
                      'Отправка смс...',
                      style: TextStyle(color: Colors.green),
                    )
                  : const SizedBox(
                      height: 5,
                    ),

              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: animation.value,
              ),
              dat
                  ? Expanded(
                      child: SizedBox(
                        height: 90.0,
                        child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: data.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 10),
                                  child: SmsHistory(
                                      id: data[index]['id'].toString(),
                                      number: data[index]['number'].toString(),
                                      text: data[index]['text'],
                                      date: data[index]['date'],
                                      status:
                                          data[index]['status'].toString()));
                            }),
                      ),
                    )
                  : const Text('Пока данных нет'),
              //const SmsHistory( id: '1', number: '8119014', text: 'Ambar', date: 'date', status: '0'),
            ],
          ),
        ),
      ],
    );
  }
}

class SmsHistory extends StatefulWidget {
  final String id;
  final String number;
  final String text;
  final String date;
  final String status;
  SmsHistory({
    required this.id,
    required this.number,
    required this.text,
    required this.date,
    required this.status,
  });

  @override
  State<SmsHistory> createState() => _SmsHistoryState();
}

class _SmsHistoryState extends State<SmsHistory> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(widget.id)),
        Expanded(child: Text(widget.number)),
        Expanded(child: Text(widget.text)),
        Expanded(child: Text(widget.date)),
        Expanded(child: Text(widget.status))
      ],
    );
  }
}

class ProfileButton extends StatefulWidget {
  final String title;
  final bool isButtonActive;
  final Function onTap;
  ProfileButton(
      {required this.title, required this.onTap, required this.isButtonActive});

  @override
  State<ProfileButton> createState() => _ProfileButtonState();
}

class _ProfileButtonState extends State<ProfileButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical: widget.isButtonActive ? 5.0 : 15.0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Row(children: [
        const Icon(Icons.sms_rounded, size: 25),
        const SizedBox(width: 10.0),
        Expanded(child: Text(widget.title, style: robotoRegular)),
        Switch(
          value: widget.isButtonActive,
          onChanged: (bool isActive) => widget.onTap(isActive),
          activeColor: Theme.of(context).primaryColor,
          activeTrackColor: Theme.of(context).primaryColor.withOpacity(0.5),
        ),
      ]),
    );
  }
}
