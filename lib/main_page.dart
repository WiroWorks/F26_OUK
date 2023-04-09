import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dart:async';

import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';


import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  final user = FirebaseAuth.instance.currentUser!;

  bool firstStart = true;

  late String pop;

  bool isAdmin = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
    firebaseFirestore.collection("PopUp").doc("pop").get().then((value) {
      print(value.data()!["pop"]);
      pop = value.data()!["pop"].toString();
    });

    firebaseFirestore.collection("users").doc(user.uid).get().then((value) {
      print(value.data()!["permission"]);
      if (value.data()!["permission"] == "admin") {
        isAdmin = true;
      }
    });

  }


  List pages = [
    Home(),
    Notlar(),
    CalendarPage(),
    AdminPage(),
  ];

  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Center(child: Text("OUK Panel")),
        ) ,
        actions: [
          IconButton(onPressed: () {
            FirebaseAuth.instance.signOut();
          }, icon: Icon(Icons.exit_to_app))
        ],
      ),
      body: pages[currentPageIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.blueGrey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.house), label: "Anasayfa"),
          BottomNavigationBarItem(icon: Icon(Icons.notes), label: "Notlar"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "takvim"),
            if (isAdmin)...[
              BottomNavigationBarItem(
                  icon: Icon(Icons.shield), label: "Admin Paneli")
            ]
        ],
        currentIndex: currentPageIndex,
        onTap: (val) {
          FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
          firebaseFirestore.collection("PopUp").doc("pop").get().then((value) {
            if ( firstStart && value.data()!["pop"] != "" ) {
              pop = value.data()!["pop"];
              firstStart = false;
              Navigator.push(context, MaterialPageRoute(builder: (builder) => PopUpScreen(metin: pop)));
            }else if(value.data()!["pop"] != pop) {
              pop = value.data()!["pop"];
              Navigator.push(context, MaterialPageRoute(builder: (builder) => PopUpScreen(metin: pop)));
            }
          });
          setState(() {
            currentPageIndex = val;
          });
        },
      ),
    );
  }
}
class PopUpScreen extends StatelessWidget {
  final String metin;
  const PopUpScreen({Key? key, required this.metin}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pop-up"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(metin)
          ],
        ),
      ),
    );
  }
}



class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EventSender(),
              Container(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (builder) => EventPage()));
                  },
                  child: Row(
                    children: [
                      Text("Eventleri görüntüle"),
                      Expanded(child: Text("")),
                      Icon(Icons.arrow_right)
                    ],
                  ),
                ),
              ),
              PopupSender(),
            ],
          ),
        ),
    );
  }
}

class EventSender extends StatefulWidget {
  const EventSender({Key? key}) : super(key: key);

  @override
  State<EventSender> createState() => _EventSenderState();
}

class _EventSenderState extends State<EventSender> {
  TextEditingController dateController = TextEditingController();
  TextEditingController eventText = TextEditingController();

  Map<DateTime, List<Event>>? selectedEvents = {};

  String encodeSelectedEvents(Map<DateTime, List<Event>> selectedEvents) {
    Map<String, List<Map<String, dynamic>>> encodedEvents = {};
    selectedEvents.forEach((key, value) {
      encodedEvents[key.toString() + (key.toString().contains("Z") ? "" : "Z")] = value.map((event) => event.toJson()).toList();
    });
    return json.encode(encodedEvents);
  }

  Map<DateTime, List<Event>> decodeSelectedEvents(String jsonString) {
    final decodedData = json.decode(jsonString);
    final selectedEvents = <DateTime, List<Event>>{};
    decodedData.forEach((key, value) {
      final dateTimeKey = DateTime.parse(key);
      final List<dynamic> eventsData = value;
      final events = eventsData.map((eventData) => Event.fromJson(eventData)).toList();
      selectedEvents[dateTimeKey] = events;
    });
    return selectedEvents;
  }

  late DateTime selectedDate;

  void EventGonder() async{
    FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

    firebaseFirestore.collection("Events").doc("All").get().then((value) async {
      print(value.data()!["data"]);
      selectedEvents = decodeSelectedEvents(value.data()!["data"]);

      if (selectedEvents == null) {
        selectedEvents = {selectedDate: [Event(title: eventText.text)]};
      } else if (selectedEvents![selectedDate]?.isNotEmpty ?? false) {
        print("2. giriş");
        selectedEvents![selectedDate]!.add(Event(title: eventText.text));
      } else {
        print("3. giriş");
        selectedEvents![selectedDate] = [Event(title: eventText.text)];
      }
      print(encodeSelectedEvents(selectedEvents!));

      final x = await firebaseFirestore.collection("Events").doc("All").set({
        "data":  encodeSelectedEvents(selectedEvents!)
      });

    });

  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    dateController.text = "";
    initializeDateFormatting("tr_TR");
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    dateController.dispose();
    eventText.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      height: 190,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red, width: 2),
        borderRadius: BorderRadius.all(Radius.circular(5.0)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(left: 9),
            height: 30,
            color: Colors.red,
            child: Row(
              children: [
                Text(
                  "Event Gönderici",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
          Container(
            width: 250,
            height: 70,
            padding: EdgeInsets.all(8),
            child: TextField(
                controller:
                dateController, //editing controller of this TextField
                decoration: const InputDecoration(
                    icon: Icon(Icons.calendar_today), //icon of text field
                    labelText: "Enter Date" //label text of field
                ),
                readOnly: true, // when true user cannot edit text
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                      locale: const Locale("tr", "TR"),
                      context: context,
                      initialDate: DateTime.now(), //get today's date
                      firstDate: DateTime(
                          2023), //DateTime.now() - not to allow to choose before today.
                      lastDate: DateTime(2025));
                  if (pickedDate != null) {
                    print(pickedDate); //get the picked date in the format => 2022-07-04 00:00:00.000

                    print(pickedDate.runtimeType);
                    String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate); // format date in required form here we use yyyy-MM-dd that means time is removed
                    //print(formattedDate); //formatted date output using intl package =>  2022-07-04
                    //print(formattedDate.runtimeType);
                    //You can format date as per your need

                    setState(() {
                      dateController.text =formattedDate; //set foratted date to TextField value.
                      selectedDate = pickedDate;
                    });
                    print("seçildi");
                  } else {
                    print("Tarih seçilmedi");
                  }
                }),
          ),
          Container(
            width: 210,
            height: 40,
            child: TextField(
              decoration: InputDecoration(hintText: "Event adı"),
              controller: eventText,
            ),
          ),
          SizedBox(
            //input ile butonu ayırmak için boşluk
            height: 10,
          ),
          SizedBox(
            width: 250,
            height: 32,
            child: ElevatedButton(
                onPressed: dateController.text == ""
                    ? null
                    : EventGonder,
                child: Text("Gönder")),
          )
        ],
      ),
    );
  }
}

class PopupSender extends StatefulWidget {
  const PopupSender({Key? key}) : super(key: key);

  @override
  State<PopupSender> createState() => _PopupSenderState();
}

class _PopupSenderState extends State<PopupSender> {

  final TextEditingController popUpText = TextEditingController();

  void PopUpGonder() async{
    FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

    final x = await firebaseFirestore.collection("PopUp").doc("pop").set({
      "pop": popUpText.text
    });


  }


  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    popUpText.dispose();
  }

  bool? chBox = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      height: 151,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red, width: 2),
        borderRadius: BorderRadius.all(Radius.circular(5.0)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(left: 9),
            height: 30,
            color: Colors.red,
            child: Row(
              children: [
                Text(
                  "Popup gönderici",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
          Container(
            width: 250,
            height: 40,
            padding: EdgeInsets.all(8),
            child: TextField(
              controller: popUpText,
            ),
          ),
          Container(
            height: 30,
            child: Row(
              children: [
                Checkbox(
                    value: chBox,
                    onChanged: (v) {
                      setState(() {
                        chBox = v;
                      });
                    }),
                Text("Telefona bildirim gönderilsin mi ?")
              ],
            ),
          ),
          SizedBox(
            //input ile butonu ayırmak için boşluk
            height: 10,
          ),
          SizedBox(
            width: 250,
            height: 32,
            child: ElevatedButton(onPressed: PopUpGonder, child: Text("Gönder")),
          )
        ],
      ),
    );
  }
}

class EventPage extends StatefulWidget {
  const EventPage({Key? key}) : super(key: key);

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Eventler"),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.access_time_filled), label: "Geçmiş Eventler"),
          BottomNavigationBarItem(
              icon: Icon(Icons.timer), label: "Gelecek Eventler")
        ],
        currentIndex: currentPage,
        onTap: (val) {
          setState(() {
            currentPage = val;
          });
        },
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: [
              EventHolder(),
              EventHolder(),
              EventHolder(),
              EventHolder(),
              EventHolder(),
              EventHolder(),
              EventHolder(),
              EventHolder(),
              EventHolder(),
              EventHolder(),
              EventHolder(),
            ],
          ),
        ),
      ),
    );
  }
}

class EventHolder extends StatelessWidget {
  const EventHolder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      width: double.infinity,
      padding: EdgeInsets.only(left: 8, right: 8),
      height: 70,
      decoration: BoxDecoration(border: Border.all()),
      child: Row(
        children: [
          SizedBox(
            child: Text("20/12/2023"),
            width: 90,
          ),
          Expanded(
              child: Text(
                "İstanbul buluşması",
                textAlign: TextAlign.center,
              )),
          SizedBox(
              width: 40,
              child: IconButton(onPressed: () {}, icon: Icon(Icons.delete))),
        ],
      ),
    );
  }
}


// Takvim
// Takvim
// Takvim
// Takvim


class Event{
  final String title;
  Event({required this.title});

  Map<String, dynamic> toJson() => {
    'title': title,
  };

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(title: json['title']);
  }

}

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {

  Map<DateTime, List<Event>>? selectedEvents = {};

  String encodeSelectedEvents(Map<DateTime, List<Event>> selectedEvents) {
    Map<String, List<Map<String, dynamic>>> encodedEvents = {};
    selectedEvents.forEach((key, value) {
      encodedEvents[key.toString()] = value.map((event) => event.toJson()).toList();
    });
    return json.encode(encodedEvents);
  }

  Map<DateTime, List<Event>> decodeSelectedEvents(String jsonString) {
    final decodedData = json.decode(jsonString);
    final selectedEvents = <DateTime, List<Event>>{};
    decodedData.forEach((key, value) {
      final dateTimeKey = DateTime.parse(key);
      final List<dynamic> eventsData = value;
      final events = eventsData.map((eventData) => Event.fromJson(eventData)).toList();
      selectedEvents[dateTimeKey] = events;
    });
    return selectedEvents;
  }

  // event kayıt

  String adminSelectedEvents = "{}";

  DateTime today = DateTime.now();

  void _OnDaySelected(DateTime day, DateTime focusedDay) {
    print(encodeSelectedEvents(selectedEvents!));
    setState(() {
      today = day;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeDateFormatting("tr_TR");
    selectedEvents = {};
    testing();
  }


  Future<void> testing() async{

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    String? events = prefs.getString('action');
    print(" cihazda depolanan : " + events!);
    if (events == null) {
      await prefs.setString('action', '{}');
    }else {
      selectedEvents = decodeSelectedEvents(events);
    }

    FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

    var x = await firebaseFirestore.collection("Events").doc("All").get().then((value) => value.data()?["data"]);

    print(x.runtimeType);
    print(x);

    adminSelectedEvents = x;
    selectedEvents?.addAll(decodeSelectedEvents(x));

    setState(() {

    });


/*
    firebaseFirestore.collection("Events").doc("All").get().then((value)  {

      setState(() {
        adminSelectedEvents = value.data()!["data"];
        selectedEvents?.addAll(decodeSelectedEvents(adminSelectedEvents));
      });

      print("testing2 nin içindeki : " + value.data()!["data"]);



      print(encodeSelectedEvents(selectedEvents!));

    });

 */
    print(encodeSelectedEvents(selectedEvents!));

  }



  List<Event> _getEventsfromDay(DateTime day) {
    return selectedEvents![day]?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              TableCalendar(
                locale: "tr_TR",
                firstDay: DateTime.utc(2023, 01, 01),
                lastDay: DateTime.utc(2025, 01, 01),
                focusedDay: today,
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                availableGestures: AvailableGestures.all,
                rowHeight: 35,
                onDaySelected: _OnDaySelected,
                selectedDayPredicate: (day) =>isSameDay(day,today),
                eventLoader: _getEventsfromDay,
              ),
              ElevatedButton(onPressed: () async{

                final secim = await Navigator.push(context,MaterialPageRoute(builder: (builder) => EventAddPage(date: today.toString().split(" ")[0],)));
                if (secim != false) {
                  print(secim);

                  final SharedPreferences prefs = await SharedPreferences.getInstance();

/*
                  var encoded = encodeSelectedEvents(selectedEvents!);
                  print(encoded);

                  Map<DateTime, List<Event>>? testing = decodeSelectedEvents(encoded);

                  print(encodeSelectedEvents(testing));
*/
                  print(encodeSelectedEvents(selectedEvents!));

                  if (selectedEvents == null) {
                    selectedEvents = {today: [Event(title: secim)]};
                  } else if (selectedEvents![today]?.isNotEmpty ?? false) {
                    print("2. giriş");
                    selectedEvents![today]!.add(Event(title: secim));
                  } else {
                    print("3. giriş");
                    selectedEvents![today] = [Event(title: secim)];
                  }
                  setState(() {});
                  selectedEvents?.removeWhere((key, value) => decodeSelectedEvents(adminSelectedEvents!).containsKey(key));
                  await prefs.setString('action', encodeSelectedEvents(selectedEvents!));

                  print("son düzlük");
                  print("son encoded hali : " + encodeSelectedEvents(selectedEvents!));
                  selectedEvents?.addAll(decodeSelectedEvents(adminSelectedEvents!));
                  print("son encoded hali 2222 : " + encodeSelectedEvents(selectedEvents!));


                }
                },
                  child: Text("Seçili güne event ekle")
              ),
              ..._getEventsfromDay(today).map((Event event) => EventHolderClient(text: event.title,)),

            ],
          ),
        ),
    );
  }
}

class EventHolderClient extends StatelessWidget {
  final String text;
  const EventHolderClient({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      width: double.infinity,
      padding: EdgeInsets.only(left: 8, right: 8),
      height: 70,
      decoration: BoxDecoration(border: Border.all()),
      child: Row(
        children: [
          Expanded(
              child: Text(
                text,
                textAlign: TextAlign.center,
              )),
          SizedBox(
              width: 40,
              child: IconButton(onPressed: () {}, icon: Icon(Icons.delete))),
        ],
      ),
    );
  }
}

class EventAddPage extends StatefulWidget {
  final String date;
  const EventAddPage({Key? key, required this.date}) : super(key: key);

  @override
  State<EventAddPage> createState() => _EventAddPageState();
}

class _EventAddPageState extends State<EventAddPage> {

  TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${widget.date} Gününe Event ekle"),
            SizedBox(
              width: 200,
              child: TextField(
                controller: controller,
              ),
            ),
            ElevatedButton(onPressed: () {
              if (controller.text != "") {
                Navigator.pop(context,  controller.text);
              }
            }, child: Text("Ekle")),
            ElevatedButton(onPressed: () {
              Navigator.pop(context, false);
            }, child: Text("Vazgeç"))
          ],
        ),
      ),
    );
  }
}


//

class ToDo {
  String? id;
  String? todoText;
  bool isDone;

  ToDo({
    required this.id,
    required this.todoText,
    this.isDone = false

  });
  static List<ToDo> todoList() {
    return [
      ToDo(id:"01",todoText:"GitHub ayın ödevi",isDone:true),
      ToDo(id:"02",todoText:"flutter 12.modül",isDone:true),
      ToDo(id:"03",todoText:"slack kanalı kontrolü",),
      ToDo(id:"04",todoText:"Coursera proje yönetimi 3.kurs",),
      ToDo(id:"05",todoText:"21.00 Kariyer Buluşması Etkinliği",isDone:true),
      ToDo(id:"06",todoText:"Spor Egzersizi",isDone:true),
      ToDo(id:"07",todoText:"fluuter üzerinde çalışma(2 saat)",),
    ];
  }
}

class TodoItem extends StatelessWidget {
  final ToDo todo ;
  final onTodoChanged;
  final onDeleteItem;

  const TodoItem({
    Key? key,
    required this.todo,
    required this.onTodoChanged,
    required this.onDeleteItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: ListTile(
        onTap: (){
          // print("cliked on todo item.");
          onTodoChanged(todo);
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20,vertical: 5),
        tileColor: Colors.white,
        leading: Icon(
          todo.isDone? Icons.check_box : Icons.check_box_outline_blank,
          color: Colors.blue,
        ),
        title: Text(
          todo.todoText!,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
            decoration: todo.isDone? TextDecoration.lineThrough: null,
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.all(0),
          margin: EdgeInsets.symmetric(vertical: 12),
          height: 35,
          width: 35,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(5),
          ),
          child: IconButton(
            color: Colors.white,
            iconSize: 18,
            icon: Icon(Icons.delete),
            onPressed: () {
              //print("cliked on delete icon");
              onDeleteItem (todo.id);
            },
          ),
        ),
      ),
    );
  }
}



class Notlar extends StatefulWidget {
  Notlar({Key? key}) : super(key: key);

  @override
  State<Notlar> createState() => _NotlarState();
}

class _NotlarState extends State<Notlar> {
  final todoList = ToDo.todoList();
  List<ToDo> _foundToDo = [];
  final _todoController = TextEditingController();

  @override
  void initState (){
    _foundToDo = todoList;
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            child: Column(
              children: [
                searchBox(),
                Expanded(
                  child: ListView(
                    children: [
                      Container(
                        margin: EdgeInsets.only(
                          top: 50,
                          bottom: 20,
                        ),
                        child: Text(
                          "All ToDos",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      for (ToDo todoo in _foundToDo.reversed)
                        TodoItem(
                          todo: todoo,
                          onTodoChanged: _handleToDoChange,
                          onDeleteItem: _deleteToDoItem,
                        ),
                    ],
                  ),
                ),
              ],

            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(children: [
              Expanded(child: Container(
                margin: EdgeInsets.only(
                  bottom: 20,
                  right: 20,
                  left: 20,
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: const [BoxShadow(
                    color: Colors.grey,
                    offset: Offset(0.0, 0.0),
                    blurRadius: 10.0,
                    spreadRadius: 0.0,
                  ),
                  ],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _todoController,
                  decoration: InputDecoration(
                    hintText: "add a new todo item",
                    border: InputBorder.none,
                  ),
                ),
              ),
              ),
              Container(
                margin: EdgeInsets.only(
                  bottom: 20,
                  right: 20,
                ),
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    child: Text('+', style: TextStyle(fontSize: 40),),
                    onPressed: () {
                      _addToDoItem(_todoController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      maximumSize: Size(65,39),
                      elevation: 15,
                    ),
                  ),
                ),
              )
            ],
            ),
          )

        ],
    );
  }

  void  _handleToDoChange(ToDo todo) {
    setState(() {
      todo.isDone =  !todo.isDone;
    });
  }
  void _deleteToDoItem (String id){
    setState(() {
      todoList.removeWhere((item) => item.id == id);
    });
  }
  void _addToDoItem(String toDo){
    setState(() {
      todoList.add(ToDo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          todoText: toDo
      ));
    });
    _todoController.clear();
  }
  void _runFilter (String enteredKeyword){
    List<ToDo> results = [];
    if (enteredKeyword.isEmpty){
      results = todoList;
    } else{
      results = todoList
          .where((item) => item.todoText!
          .toLowerCase()
          .contains(enteredKeyword.toLowerCase()))
          .toList();
    }

    setState(() {
      _foundToDo = results;
    });

  }

  Widget searchBox() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        onChanged: (value) => _runFilter(value),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(0),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.black,
            size: 20,
          ),
          prefixIconConstraints: BoxConstraints(
            maxHeight: 60,
            minWidth: 60,
          ),
          border: InputBorder.none,
          hintText: "search",
          helperStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.grey.shade300,
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(
            Icons.menu,
            color: Colors.black,
            size: 30,
          ),
          Container(
            height: 40,
            width: 40,
            child: ClipRRect(
              child: Image.asset("photo/ımages.jpeg"),
              borderRadius: BorderRadius.circular(20),
            ),
          )
        ],),
    );
  }



}





/////////// HOME
/////////// HOME
/////////// HOME
/////////// HOME
/////////// HOME
/////////// HOME
/////////// HOME
/////////// HOME
/////////// HOME



class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final PageController pageController;
  ScrollController _scrollController = ScrollController();
  int pageNo = 0;

  Timer? carasouelTmer;

  Timer getTimer() {
    return Timer.periodic(const Duration(seconds: 3), (timer) {
      if (pageNo == 4) {
        pageNo = 0;
      }
      pageController.animateToPage(
        pageNo,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOutCirc,
      );
      pageNo++;
    });
  }

  @override
  void initState() {
    pageController = PageController(initialPage: 0, viewportFraction: 0.85);
    carasouelTmer = getTimer();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        showBtmAppBr = false;
        setState(() {});
      } else {
        showBtmAppBr = true;
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  bool showBtmAppBr = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              const SizedBox(
                height: 36.0,
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: ListTile(
                  onTap: () {},
                  selected: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(16.0),
                    ),
                  ),
                  selectedTileColor: Colors.indigoAccent.shade100,
                  title: Text(
                    "Welcome Back",
                    style: Theme.of(context).textTheme.subtitle1!.merge(
                      const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                  subtitle: Text(
                    "Umarım güzel vakit geçirirsiniz.",
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                  trailing: PopUpMen(
                    menuList: const [
                      PopupMenuItem(
                        child: ListTile(
                          leading: Icon(
                            CupertinoIcons.person,
                          ),
                          title: Text("My Profile"),
                        ),
                      ),
                      PopupMenuItem(
                        child: ListTile(
                          leading: Icon(
                            CupertinoIcons.bag,
                          ),
                          title: Text("My Bag"),
                        ),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        child: Text("Settings"),
                      ),
                      PopupMenuItem(
                        child: Text("About Us"),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        child: ListTile(
                          leading: Icon(
                            Icons.logout,
                          ),
                          title: Text("Log Out"),
                        ),
                      ),
                    ],
                    icon: CircleAvatar(
                      backgroundImage: const NetworkImage(
                        'https://images.unsplash.com/photo-1644982647869-e1337f992828?ixlib=rb-1.2.1&ixid=MnwxMjA3fDF8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=435&q=80',
                      ),
                      child: Container(),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: pageController,
                  onPageChanged: (index) {
                    pageNo = index;
                    setState(() {
                    });
                  },
                  itemBuilder: (_, index) {
                    return AnimatedBuilder(
                      animation: pageController,
                      builder: (ctx, child) {
                        return child!;
                      },
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                              Text("Hello you tapped at ${index + 1} "),
                            ),
                          );
                        },
                        onPanDown: (d) {
                          carasouelTmer?.cancel();
                          carasouelTmer = null;
                        },
                        onPanCancel: () {
                          carasouelTmer = getTimer();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(
                              right: 8, left: 8, top: 24, bottom: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24.0),
                            color: Colors.amberAccent,
                          ),
                        ),
                      ),
                    );
                  },
                  itemCount: 5,
                ),
              ),
              const SizedBox(
                height: 12.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                      (index) => GestureDetector(
                    child: Container(
                      margin: const EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.circle,
                        size: 12.0,
                        color: pageNo == index
                            ? Colors.indigoAccent
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: GridB(),
              ),
            ],
      ),
    );
  }
}

class PopUpMen extends StatelessWidget {
  final List<PopupMenuEntry> menuList;
  final Widget? icon;
  const PopUpMen({Key? key, required this.menuList, this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      itemBuilder: ((context) => menuList),
      icon: icon,
    );
  }
}

class FabExt extends StatelessWidget {
  const FabExt({
    Key? key,
    required this.showFabTitle,
  }) : super(key: key);

  final bool showFabTitle;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {},
      label: AnimatedContainer(
        duration: const Duration(seconds: 2),
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(CupertinoIcons.cart),
            SizedBox(width: showFabTitle ? 12.0 : 0),
            AnimatedContainer(
              duration: const Duration(seconds: 2),
              child: showFabTitle ? const Text("Go to cart") : const SizedBox(),
            )
          ],
        ),
      ),
    );
  }
}

class GridB extends StatefulWidget {
  const GridB({Key? key}) : super(key: key);

  @override
  State<GridB> createState() => _GridBState();
}

class _GridBState extends State<GridB> {
  final List<Map<String, dynamic>> gridMap = [
    {
      "title": "Mobil Yazılım Yeni Teknolojiler",
      "images":
      "https://webmobilyazilim.com/cms/medias/article/medium/25/mobil-uygulama-yeni-teknolojileri.jpg",
    },
    {
      "title": "Unity Optimizasyon Önerileri",
      "images":
      "https://berkayoztunc.com/storage/blogs/December2018/tC3HrHcGqR4R4Wk3TL2w.png",
    },
    {
      "title": "Unity ile Yapılan Oyunlar",
      "images":
      "https://mobidictum.com/wp-content/uploads/2020/08/AndroidPIT-best-androdi-games-1-w810h462-1-1-1.jpg.webp",
    },
    {
      "title": "Flutter ile geliştirilmiş uygulamalar",
      "images":
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRyti2-GJXJqimKsaMmuc8JZI9Sslvy5uEcYw&usqp=CAU",
    },
    {
      "title": "Flutter Nedir?",
      "images":
      "https://cdn.dribbble.com/users/1622791/screenshots/11174104/flutter_intro.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        mainAxisExtent: 310,
      ),
      itemCount: gridMap.length,
      itemBuilder: (_, index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              16.0,
            ),
            color: Colors.amberAccent.shade100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                child: Image.network(
                  "${gridMap.elementAt(index)['images']}",
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${gridMap.elementAt(index)['title']}",
                      style: Theme.of(context).textTheme.subtitle1!.merge(
                        const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 8.0,
                    ),
                    Text(
                      "${gridMap.elementAt(index)['price']}",
                      style: Theme.of(context).textTheme.subtitle2!.merge(
                        TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 8.0,
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            CupertinoIcons.checkmark_circle,
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            CupertinoIcons.heart,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

