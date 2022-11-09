import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import 'package:gsm_app/const.dart';
import 'package:dio/dio.dart';
import 'package:telephony/telephony.dart';

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
  bool? connect;
  bool? sended;
  bool _canSend = false;
  final Telephony telephony = Telephony.instance;
  final SmsSendStatusListener listener = (SendStatus status) {
    print(status);
  };
  String? _output;
  var err;

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
        connect = await _sendRequest();
/*
        if (connect != null && connect == true) {
          sended = await _sendSMS();

          if (sended != null && sended == true) {
            print('Сообщение отправлено');
          } else
            print('Проблемы с отправкой');
        } else
          print('Нет подключения');

        controller.value = 0.0;
        controller.forward();

        //await Future.delayed(const Duration(seconds: 1));*/
        controller.value = 0.0;
        controller.forward();
      } else if (status == AnimationStatus.dismissed) controller.forward();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<bool?> _canSendSMS() async {
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    /*bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    DataState canSms = await telephony.cellularDataState;
    //List<SignalStrength> canSms = await telephony.signalStrengths;
    print(canSms);
    SimState simState = await telephony.simState;
    print(simState);
    return true;*/
    try {
      await telephony.sendSms(
          to: "+79298116987", message: "101", statusListener: listener);
      listener;
    } catch (e) {
      print(e);
      listener;
    }

    return true;
  }

  Future<bool?> _sendRequest() async {
    try {
      setState(() {
        doun = true;
        print('Получение данных');
      });
      Dio dio = Dio();
      request = await dio.get('https://hvarna.ru/api/v1/gsm/sms');
      data = request.data;
      dat = true;

      //print(data);
      setState(() {
        doun = false;
        print('Завершение получения данных');
      });

      return true;
    } on DioError catch (e) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        print(e);
      } else {
        // Something happened in setting up or sending the request that triggered an Error

        if (e.error.osError.errorCode == 11001) {
          print('Нет подключения к интернету');
        }
        err = e;
        return false;
      }
    }
  }

  /*Future<bool?> _sendSMS() async {
    try {
      for (int i = 0; i < data.length - 1; i++) {
        if (data[i]['status'] == 0) {
          setState(() {
            sending = true;
            print('Отправка смс');
          });
          break;
        }
      }
      if (sending) {
        for (int i = 0; i < data.length; i++) {
          if (data[i]['status'] == 0) {
            //Запуск анимации отправки
            setState(() {
              data[i]['status'] = '1';
            });

            //Отправка
            await Future.delayed(const Duration(seconds: 1));
            setState(() {
              data[i]['status'] = '2';
            });
            break;
          }
        }

        timer = Timer(const Duration(milliseconds: 3000), () {
          setState(() {
            sending = false;
            print('Завершение отправки');
            controller.value = 0.0;
            controller.forward();
          });
        });
      } else {}
      return true;
    } catch (e) {
      return false;
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        ProfileButton(
            title: 'Auto mode',
            isButtonActive: autoSMS,
            onTap: (value) {
              setState(() {
                autoSMS = value;
                if (value) _canSendSMS();
              });
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
        Expanded(child: Text(widget.status)),
        widget.status == '0'
            ? Container(child: const Icon(Icons.error))
            : widget.status == '1'
                ? Container(child: const CircularProgressIndicator())
                : Container(child: const Icon(Icons.send_to_mobile))
      ],
    );
  }
}

class ProfileButton extends StatefulWidget {
  final String title;
  late final bool isButtonActive;
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
