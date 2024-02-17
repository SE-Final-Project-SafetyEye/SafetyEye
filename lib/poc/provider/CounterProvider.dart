

import 'package:flutter/cupertino.dart';

class CounterProvider extends ChangeNotifier{
  late int counter;

  CounterProvider({this.counter=0,});

  void plus() async{
    counter++;
    notifyListeners();
  }

  void minus() async{
    counter--;
    notifyListeners();
  }
}