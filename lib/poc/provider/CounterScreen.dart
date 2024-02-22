import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'CounterProvider.dart';

class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(),body: Container(child: Column(children:
    [Text(context.watch<CounterProvider>().counter.toString()),TextButton(
      style: ButtonStyle(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
              if (states.contains(MaterialState.focused))
                return Colors.red;
              return null; // Defer to the widget's default.
            }
        ),
      ),
      onPressed: () {context.read<CounterProvider>().plus(); },
      child: const Text('PlusButton'),
    ),TextButton(
      style: ButtonStyle(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
              if (states.contains(MaterialState.focused))
                return Colors.red;
              return null; // Defer to the widget's default.
            }
        ),
      ),
      onPressed: () {context.read<CounterProvider>().minus(); },
      child: const Text('MinusButton'),
    )
    ],),),);
  }
}
void main() {
  runApp(MultiProvider(providers: [ChangeNotifierProvider(create: (context)=>CounterProvider())],child: MaterialApp(
    home: Counter(),
  ),));
}
