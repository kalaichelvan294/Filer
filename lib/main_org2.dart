import 'package:filer/Core/Models/FileModel.dart';
import 'package:filer/Services/services.dart' as services;
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Filer',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: MyHomePage(title: 'Filer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Widget projectWidget() {
    var ss = services.Services();
    return FutureBuilder(
      builder: (context, projectSnap) {
        if (projectSnap.connectionState == ConnectionState.none &&
            projectSnap.hasData == null) {
          return Container(
            child: Center(
              child: Text("Loading...")
            ),
          );
        }
        return ListView.builder(
          itemCount: projectSnap?.data?.length ?? 0,
          itemBuilder: (context, index) {
            FileModel project = projectSnap.data[index];
            return ListTile(
              title: Text(project.fileName),
            );
          },
        );
      },
      future: ss.getLottoResults("pdf","aukdc"),
    );
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      
      appBar: AppBar(
        title: Text(widget.title),
        
      ),

      body:
      Container(
        child: projectWidget(),
      ),
       // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
