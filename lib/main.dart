import 'dart:async' show Timer;
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:gsm_app/const.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:sms_advanced/sms_advanced.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    SmsSender sen = SmsSender();
    Dio dio = Dio();
    SmsMessage mess = SmsMessage(message.data['number'], message.data['text']);
    await sen.sendSms(mess);
    await dio.get(
        'https://hvarna.ru/api/v1/gsm/status?id=${message.data['id']}&status=1');
    print('Сообщение отправлено');
  } catch (e) {
    print(e);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final fcmToken = await FirebaseMessaging.instance.getToken();
  FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
    fcmToken = (await FirebaseMessaging.instance.getToken())!;
    print('New token: ${fcmToken}');
    // TODO: If necessary send token to application server.

    // Note: This callback is fired at each app startup and whenever a new
    // token is generated.
  }).onError((err) {
    // Error getting token.
  });
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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
  bool? check;
  bool? sended;
  bool _canSend = false;
  String? _output;
  var err;
  SmsQuery query = new SmsQuery();
  SmsSender sender = SmsSender();
  Dio dio = Dio();

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

        if (connect != null && connect == true) {
          check = await checkSms();
          if (check != null && check == true) {
            if (autoSMS) _sendSMSS();
          }
        }

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

  Future<bool?> checkSms() async {
    try {
      List<SmsMessage> messages =
          await query.querySms(kinds: [SmsQueryKind.Sent]);
      for (int k = 0; k <= data.length - 1; k++) {
        if (data[k]['status'] == 1) {
          late Response req;
          bool sended = false;
          for (int i = 0; i <= messages.length - 1; i++) {
            if (messages[i].body?.compareTo(data[k]['text']) == 0) {
              req = await dio.get(
                  'https://hvarna.ru/api/v1/gsm/status?id=${data[k]['id']}&status=2');
              data[k]['status'] = '2';
              sended = true;
              print('Запрос на сервер');
              return false;
            }
          }
          https: //hvarna.ru/api/v1/gsm/status?id=6&status=3
          if (!sended) {
            req = await dio.get(
                'https://hvarna.ru/api/v1/gsm/status?id=${data[k]['id']}&status=3');
            data[k]['status'] = '3';
            print('Сообщение не отправлено');
            return false;
          }
        }
      }
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  void _sendSMSS() async {
    for (int i = 0; i <= data.length - 1; i++) {
      if (data[i]['status'] == 0) {
        late Response req;
        SmsMessage message = SmsMessage(data[i]['number'], data[i]['text']);
        await sender.sendSms(message);
        req = await dio.get(
            'https://hvarna.ru/api/v1/gsm/status?id=${data[i]['id']}&status=1');
        data[i]['status'] = '1';

        break;
      }
    }
  }

  Future<bool?> _sendRequest() async {
    try {
      setState(() {
        doun = true;
        print('Получение данных');
      });

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
                                      date: data[index]['created_at'],
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
    return InkWell(
      onTap: () {
        if (widget.status == '3') sendByApp(widget.number, widget.text);
      },
      child: Row(
        children: [
          Expanded(child: Text(widget.id)),
          Expanded(child: Text(widget.number)),
          Expanded(child: Text(widget.text)),
          Expanded(child: Text(widget.date)),
          Expanded(child: Text(widget.status)),
          widget.status == '0'
              ? Container(child: const Icon(Icons.fiber_new))
              : widget.status == '1'
                  ? Container(child: const CircularProgressIndicator())
                  : widget.status == '2'
                      ? Container(child: const Icon(Icons.sms_rounded))
                      : Container(child: const Icon(Icons.error))
        ],
      ),
    );
  }

  sendByApp(String number, String text) async {
    try {
      String _result = await sendSMS(message: text, recipients: [number]);
    } catch (e) {
      print(e);
    }
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
