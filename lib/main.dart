import 'package:flutter/material.dart';
import 'package:gsm_app/const.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const MyApp());
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
      home: const MyHomePage(title: 'GSMm1'),
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

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: const MainWidget()
    );
  }
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => _MainState();
}

class _MainState extends State<MainWidget> {
  late Response request;
  bool autoSMS = false;
  bool dat = false;
  late List data;

  void _sendRequest() async {

    try{
      Dio dio = Dio();
      request = await dio.get('https://hvarna.ru/api/v1/gsm/sms');
      dat = true;
      data = request.data;
      print(request.data);

    }catch(e){
      print(e);
    }
    
  }
  


  @override
  Widget build(BuildContext context) {
    return Column(
      children:  [
        const SizedBox(height: 20),
        ProfileButton( title: 'Auto mode', isButtonActive: autoSMS, onTap: (value) {
           setState(() {
                autoSMS=value;
                _sendRequest();
        
              });
                }
                ),
        Expanded(
          child: Row(
            children: const [
              Expanded(child: Center(
                child: Text('Отправлено'),
              )),
              Expanded(child: Center(
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
              const SizedBox(height: 20),
              dat  ? ListView.builder(
                itemBuilder: ( BuildContext context, int index) {
                  return SmsHistory( id: '1', number: '8119014', text: 'Ambar', date: 'date', status: '0');
                
                }
              ):        
              const Text('Пока данных нет'),       
              //const SmsHistory( id: '1', number: '8119014', text: 'Ambar', date: 'date', status: '0'),
            ],
          ),
        ),         
        

      ],
    );
  }
}

class SmsHistory extends StatelessWidget {
  final String id;
  final String number;
  final String text;
  final String date;
  final String status;
  const SmsHistory({
    Key? key, required this.id, required this.number, required this.text, required this.date, required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(id)),
        Expanded(child: Text(number)),
        Expanded(child: Text(text)),
        Expanded(child: Text(date)),
        Expanded(child: Text(status))
      ],
    );
  }
}

class ProfileButton extends StatelessWidget {
  final String title;
  bool isButtonActive;
  final Function onTap;
  ProfileButton({ required this.title, required this.onTap, required this.isButtonActive});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10.0,
          vertical: isButtonActive  ? 5.0 : 15.0,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child:  Row(children: [
          const Icon(Icons.sms_rounded, size: 25),
           const SizedBox(width: 10.0),
          Expanded(child: Text(title, style: robotoRegular)),
          Switch(
            value: isButtonActive,
            onChanged: (bool isActive) => onTap(isActive),
            activeColor: Theme.of(context).primaryColor,
            activeTrackColor: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
        ]),
      );

  }
}
