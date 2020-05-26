import 'dart:async';
import 'package:file_utils/file_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:filer/Core/Models/FileModel.dart';
import 'package:filer/Services/services.dart' as services;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'constants.dart';
import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'dart:math';
// import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Filer',
      theme: ThemeData(
        fontFamily: "Cairo",
        scaffoldBackgroundColor: kBackgroundColor,
        textTheme: Theme.of(context).textTheme.apply(displayColor: kTextColor),
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
  
  String _currentFileType = 'pdf';
  String _searchText = "";
  bool _loading = false;
  bool downloading = false;
  String _imgUrl="";
  var progress = "";
  var path = "No Data";
  var platformVersion = "Unknown";
  final PermissionHandler _permissionHandler = PermissionHandler();
  static final Random random = Random();
  Directory externalDir;
  Directory _downloadsDirectory;

  Map _source = {ConnectivityResult.none: false};
  MyConnectivity _connectivity = MyConnectivity.instance;

  @override
  void initState() {
    super.initState();
    _connectivity.initialise();
    initDownloadsDirectoryState();
    _connectivity.myStream.listen((source) {
      setState(() => _source = source);
    });
  }

  @override
  void dispose() {
    _connectivity.disposeStream();
    super.dispose();
  }


Future<void> initDownloadsDirectoryState() async {
    Directory downloadsDirectory;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      downloadsDirectory = await DownloadsPathProvider.downloadsDirectory;
    }catch(e) {
      print('Could not get the downloads directory');
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      this._downloadsDirectory = downloadsDirectory;
    });
  }

Future<bool> _requestPermission(PermissionGroup permission) async {
    var result = await _permissionHandler.requestPermissions([permission]);
    if (result[permission] == PermissionStatus.granted) {
      return true;
    }
    return false;
  }


    Future<void> downloadFile() async {
      
      print(_requestPermission(PermissionGroup.storage));
      
      if(true)
      {
        print("true...");
        print("entering download");
        
        Dio dio = Dio();
        String dirloc ;
        if(_downloadsDirectory!=null || _downloadsDirectory.path!="")
          dirloc = _downloadsDirectory.path;
        else
          dirloc = (await getApplicationDocumentsDirectory()).path;

        var randid = random.nextInt(10000);

        try {
          FileUtils.mkdir([dirloc]);
          print("url-->"+this._imgUrl+"------"+ dirloc + randid.toString() +"."+this._currentFileType);
          await dio.download(this._imgUrl, dirloc + randid.toString() +"."+ this._currentFileType,
              onReceiveProgress: (receivedBytes, totalBytes) {
            setState(() {
              downloading = true;
              progress =
                  ((receivedBytes / totalBytes) * 100).toStringAsFixed(0) + "%";
            });
          });
        } catch (e) {
          print(e);
        }

        setState(() {
          downloading = false;
          progress = "Download Completed.";
          path = dirloc + randid.toString() + this._currentFileType;
          // print("path------->"+this.path);
        });
      print("path------->"+this.path);
      
      }
      else
      {
        print("permission denied");
      }
      
    }



  Widget projectWidget() {
    var ss = services.Services();

    String netw;
    switch (_source.keys.toList()[0]) {
      case ConnectivityResult.none:
        netw = "off";
        break;
      case ConnectivityResult.mobile:
        netw = "Online";
        break;
      case ConnectivityResult.wifi:
        netw = "Online";
    }
    if(netw=="off")
    {
      return  Card(
        child: ListTile(
          title: Text("No Data Found!"),
        ),
      );
    }

    if(this._loading)
    {
      try{
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
                return Card(
                    child: ListTile(
                    leading: Text(this._currentFileType),
                    title: Text(project.fileName),
                    subtitle: Text(project.fileUrl),
                    trailing: Icon(Icons.more_vert),
                    dense: false,
                    onTap: (){
                      print(project.fileUrl);
                      setState(() {
                        this._imgUrl=project.fileUrl;
                      });
                      downloadFile();
                    },
                  ),
                );
              },
            );
          },
          future: ss.getLottoResults(this._currentFileType,this._searchText),
        );
      }
      catch(exception)
      {
        setState(() {
          this._loading=false;
        });
        return  Card(
        child: ListTile(
          title: Text("No Data Found!"),
        ),
      );
      }   
    }
    else
    {
      setState(() {
          this._loading=false;
        });
      print("future builder else part------");
      return Card(
        child: ListTile(
          title: Text("No Data Found!"),
        ),
      );
    }
  }


  getresults()
  {
    print("getreulsts before-->"+this._loading.toString()+" text->"+this._searchText);
    if(this._searchText=="" || this._searchText==null)
    {
      setState(() {
        this._loading=false;
      });
    }
    else{
      setState(() {
        this._loading=true;
      });
    }
    print("getreulsts after-->"+this._loading.toString()+" text->"+this._searchText);
  }


  @override
  Widget build(BuildContext context) {
    
    var size = MediaQuery.of(context).size; //this gonna give us total height and with of our device

    var _fileTypes = ['pdf','docx','xlsx','sql','ppt'];
    
        return Scaffold(
          // header section part
          body: Stack(
            children: <Widget>[
              Container(
                height: size.height*.40,
                decoration: BoxDecoration(
                  color: Color(0xFFF5CEB8),
                  image: DecorationImage(
                    alignment: Alignment.centerLeft,
                    image: AssetImage("assets/images/undraw_pilates_gpdb.png"),
                  ),
                ),
              ),
              
              // menu icon
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                    ),
                  child: Column(
                    //moves header text to left
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Align(
                          alignment: Alignment.topRight,
                          child: Container(
                          alignment: Alignment.center,
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: Color(0xFFF2BEA1),
                            shape: BoxShape.circle,
                          ),
                          child: SvgPicture.asset("assets/icons/menu.svg"),
                        ),
                      ),
                    
                    // header text
                    Text(
                      "Filer",
                      style: Theme.of(context)
                      .textTheme
                      .display2
                      .copyWith(fontWeight: FontWeight.w900),
                    ),
    
                    // input search box
                    Container(
                      height: 50,
                      margin: EdgeInsets.symmetric(
                        vertical: 17,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal : 25,
                        vertical : 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(29.5),
                        color : Colors.white,
                      ),
                      child: TextField(
                        // autofocus: true,
                        decoration: InputDecoration(
                          hintText : "Search...",
                          icon : SvgPicture.asset("assets/icons/search.svg"),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.arrow_forward_ios), 
                            onPressed: (){
                              getresults();
                            }
                            ),
                        ),
                        onChanged: (String value){
                          setState(() {
                            this._searchText = value;
                            this._loading = false; 
                          });
                        },
                      ),
                    ),
                    
                    Container(
                      height: 35,
                      margin: EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal : 25,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(29.5),
                        color : Colors.white,
                      ),
                      // child: Center(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            items: _fileTypes.map((String dropDownstringItem){
                              return DropdownMenuItem<String>(
                                value: dropDownstringItem,
                                child: Text(
                                  dropDownstringItem,
                                  ),
                                );
                            }).toList(), 
                            isExpanded: false,
                            onChanged: (String newfileType){
                              setState(() {
                                this._currentFileType = newfileType;
                              });
                            },
                            value: this._currentFileType,
                          ),
                        ),
                      // ),

                ),

                //  Expanded(child: Text(this.progress)),

  
                // list view 
                Expanded(
                      child: projectWidget(),
                ),

                ],
              ),
            ),
          ),
        ],
      ),

      // bottomNavigationBar: BottomNavBar(),

    );
  }
}



//checking internet connection
class MyConnectivity {
  MyConnectivity._internal();

  static final MyConnectivity _instance = MyConnectivity._internal();

  static MyConnectivity get instance => _instance;

  Connectivity connectivity = Connectivity();

  StreamController controller = StreamController.broadcast();

  Stream get myStream => controller.stream;

  void initialise() async {
    ConnectivityResult result = await connectivity.checkConnectivity();
    _checkStatus(result);
    connectivity.onConnectivityChanged.listen((result) {
      _checkStatus(result);
    });
  }

  void _checkStatus(ConnectivityResult result) async {
    bool isOnline = false;
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        isOnline = true;
      } else
        isOnline = false;
    } on SocketException catch (_) {
      isOnline = false;
    }
    controller.sink.add({result: isOnline});
  }

  void disposeStream() => controller.close();
}