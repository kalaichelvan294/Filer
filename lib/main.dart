import 'dart:async';
<<<<<<< HEAD
import 'dart:isolate';
import 'dart:ui';
import 'package:filer/widgets/headerFiler.dart';
import 'package:flutter_share_plugin/flutter_share_plugin.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:filer/Core/Models/FileModel.dart';
import 'package:filer/Services/services.dart';
import 'package:flutter/material.dart';
// import 'package:filer/constants.dart' as constants;
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';
import 'classes/custom_flushbar.dart';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flushbar/flushbar_helper.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:progress_indicators/progress_indicators.dart';

import 'downloads.dart';


const debug = false;
void _enablePlatformOverrideForDesktop() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

void main() async{
_enablePlatformOverrideForDesktop();
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: debug);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    
    final platform = Theme.of(context).platform;

=======
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
>>>>>>> 181ec160da02e628d6cc439edafd4c9577bf954d
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Filer',
      theme: ThemeData(
        fontFamily: "Cairo",
<<<<<<< HEAD
        scaffoldBackgroundColor: Colors.black87,
        textTheme: Theme.of(context).textTheme.apply(displayColor: Color(0xFF222B45)),
      ),
      home: MyHomePage(
        title: 'Filer',
        platform: platform,
        ),
      routes: <String,WidgetBuilder>{
        // "/":(BuildContext context) => new MyHomePage(),
        "/downloads" :(BuildContext context) => new Downloads(),
      },
=======
        scaffoldBackgroundColor: kBackgroundColor,
        textTheme: Theme.of(context).textTheme.apply(displayColor: kTextColor),
      ),
      home: MyHomePage(title: 'Filer'),
>>>>>>> 181ec160da02e628d6cc439edafd4c9577bf954d
    );
  }
}

<<<<<<< HEAD
class MyHomePage extends StatefulWidget{

  final TargetPlatform platform;

  MyHomePage({Key key, this.title,this.platform}) : super(key: key);
=======
class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
>>>>>>> 181ec160da02e628d6cc439edafd4c9577bf954d
  final String title;
  
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  String _currentFileType = 'pdf';
<<<<<<< HEAD
  String _searchText = "";  
  bool downloading = false;

  List<FileModel> alistitems = new List<FileModel>();
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  
  //flutter downloader

  List<_TaskInfo> _tasks;
  List<_ItemHolder> _items;
  bool _downloadon=false;
  DownloadTaskStatus _downloadstatus;
  bool _permissionReady;
  String _localPath;
  String _currentfileName="";
  String _currentfileUrl="";
  ReceivePort _port = ReceivePort();
  
  var progress = "";
  var path = "No Data";
  var platformVersion = "Unknown";
  Directory externalDir;

  String _connectionStatus = 'Unknown';
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;
  Services service = Services();

  bool isBackButtonActivated = false;

@override
void initState() {
  super.initState();
  // initDownloadsDirectoryState();
  initConnectivity();
  alistitems.add(new FileModel("1", "home", "1","1", "1"));
  _bindBackgroundIsolate();
  FlutterDownloader.registerCallback(downloadCallback);
  _permissionReady = false;
  _connectivitySubscription =
      _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
}

@override
void dispose() {
  _connectivitySubscription.cancel();
  _unbindBackgroundIsolate();
  super.dispose();
}

void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    setState(() {
      this._downloadon = true;
    });
    
    _port.listen((dynamic data) {
      if (debug) {
        print('UI Isolate Callback: $data');
      }
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      var task;
      try{
      if(_tasks[0]!=null && _tasks[0].taskId==id)
        task = _tasks[0];
      }
      catch(e){
        print("exeception kn on task-->"+e.toString());
      }
      if (task != null) {
        setState(() {
          task.status = status;
          task.progress = progress;
          this._downloadstatus = status;
        });
      _checkdownload(task);
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }


static void downloadCallback(
    String id, DownloadTaskStatus status, int progress) {
    if (debug) {
      print(
          'Background Isolate Callback: task ($id) is in status ($status) and process ($progress)');
    }
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }

  Future<bool> _checkPermission() async {
    if (widget.platform == TargetPlatform.android) {
      PermissionStatus permission = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.storage);
      if (permission != PermissionStatus.granted) {
        Map<PermissionGroup, PermissionStatus> permissions =
            await PermissionHandler()
                .requestPermissions([PermissionGroup.storage]);
        if (permissions[PermissionGroup.storage] == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  Future<Null> _prepare(String filename, String fileurl) async {
    print("prepared");
    _permissionReady = await _checkPermission();
    
    if(_permissionReady==false){FlushbarHelper.createError(message: "Storage permission required!!!")..show(context);return;}
    // if(this._downloadon){FlushbarHelper.createInformation(message: "Already a download is in progress!!!")..show(context);return;}
    final response = await http.head(fileurl);
    if (response.statusCode != 200){FlushbarHelper.createError(message: "Url error occurred")..show(context);return;}
    final tasks = await FlutterDownloader.loadTasks();
    
    int count = 0;_tasks = [];_items = [];
    _tasks.insert(0,_TaskInfo(name: filename, link: fileurl , status : DownloadTaskStatus.undefined));
    _items.insert(0,_ItemHolder(name: 'Documents'));
    for (int i = count; i < _tasks.length; i++) {_items.add(_ItemHolder(name: _tasks[i].name, task: _tasks[i]));count++;}
    tasks?.forEach((task) {
      for (_TaskInfo info in _tasks) {
        if (info.link == task.url) {
          info.taskId = task.taskId;
          info.status = task.status;
          info.progress = task.progress;
        }
      }
    });
    _localPath = await _findLocalPath();
    final savedDir = Directory(_localPath);
    bool hasExisted = await savedDir.exists();
    if(!hasExisted){savedDir.create();}
    
    _requestDownload(_tasks[0]);

    FlushbarHelper.createInformation(message: filename, title: "Download intiated...").show(context);
  }

  void _requestDownload(_TaskInfo task) async {
    print("File download path set----->"+_localPath);
    task.taskId = await FlutterDownloader.enqueue(
        url: task.link,
        savedDir: _localPath,
        showNotification: true,
        openFileFromNotification: true);
    setState(() {this._downloadon=true;_downloadstatus=null;});
  }

  _checkdownload(_TaskInfo taskinfo)
  {
      print(taskinfo.toString()+" ---> progress");
      if(taskinfo.status==DownloadTaskStatus.failed){FlushbarHelper.createError(message:"Download failed").show(context);setState((){this._downloadon=false;});}
      else if(taskinfo.status==DownloadTaskStatus.complete){FlushbarHelper.createSuccess(message: "Download completed").show(context);setState((){this._downloadon=false;});}
      else if(taskinfo.status==DownloadTaskStatus.canceled){FlushbarHelper.createInformation(message: "Download cancelled").show(context);setState((){this._downloadon=false;});}
      else if(taskinfo.status==DownloadTaskStatus.paused){FlushbarHelper.createInformation(message: "Download paused").show(context);setState((){this._downloadon=false;});}
  }

  Future<String> _findLocalPath() async {
    final directory = widget.platform == TargetPlatform.android ? await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();
    print("path------------>"+directory.path.toString());
    return directory.path;
  }


Future<void> initConnectivity() async {
    ConnectivityResult result;
    try {result = await _connectivity.checkConnectivity();}catch(e){print("exception kn----->"+e.toString());}
    if (!mounted){return Future.value(null);}
    return _updateConnectionStatus(result);
  }


Future<void> _updateConnectionStatus(ConnectivityResult result) async {
  switch (result) {
    case ConnectivityResult.wifi:
      setState(() => _connectionStatus = "Success");
      break;
    case ConnectivityResult.mobile:
      setState(() => _connectionStatus = "Success");
      break;
    case ConnectivityResult.none:
      setState(() => _connectionStatus = "Failed");
      break;
    default:
      setState(() => _connectionStatus = 'Failed');
      break;
  }
  if(this._connectionStatus=="Failed"){FlushbarCustom.internetDisabled()..show(context);}
  else if(this._connectionStatus=="Success"){FlushbarCustom.internetEnabled()..show(context);}

}

_addItem(FileModel resultitem) {
  setState(() {
    listKey.currentState.insertItem(alistitems.length, duration: const Duration(milliseconds: 500));
    alistitems.add(resultitem);
  });
}

_removeAllItems() {

  final int itemCount = alistitems.length;
  for (var i = 0; i < itemCount; i++) {
    FileModel itemToRemove = alistitems[0];
    listKey.currentState.removeItem(0,
      (BuildContext context, Animation animation) => _animatedlistbuildItem(context, itemToRemove, animation),
      duration: const Duration(milliseconds: 250),
    );
    alistitems.removeAt(0);
  }
}

_buildlistelement(project)
{
  if(project.fileUrl=="load")
  {
    return Container( 
                  height: 100,
                  margin: EdgeInsets.all(2),
                  padding: EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color : Colors.white, 
                  ),
                  alignment: Alignment.center,
                  child: CollectionScaleTransition(
                    children: <Widget>[
                      FaIcon(FontAwesomeIcons.search,color: Colors.black,size: 24,), 
                      Icon(Icons.navigate_next,size: 24,),
                      Icon(Icons.navigate_next,size: 24,),
                      Icon(Icons.navigate_next,size: 24,),
                      FaIcon(FontAwesomeIcons.solidFilePdf,color: Colors.red,size: 24,), 
                      SizedBox(width:6,),
                      FaIcon(FontAwesomeIcons.solidFileWord,color: Colors.blue[400],size: 24,),  
                      SizedBox(width:6,),
                      FaIcon(FontAwesomeIcons.solidFileExcel,color: Colors.green[900],size: 24,),  
                      SizedBox(width:6,),
                      FaIcon(FontAwesomeIcons.solidFilePowerpoint,color: Colors.orange,size: 24,),
                      SizedBox(width:6,),
                      FaIcon(FontAwesomeIcons.fileCsv,color: Colors.green[900],size: 24,),
                      SizedBox(width:6,),
                      FaIcon(FontAwesomeIcons.solidFile,color: Colors.amber,size: 24,),
                    ],
                  ),
              );
  }
  else if(project.fileUrl=="show")
  {
    return Card(
          child: ListTile(
          leading: Icon(Icons.error),
          title: Text(project.fileName+" for "+this._searchText),
          dense: false,
          ),
        );
  }
  else if(project.fileUrl=="home")
  {
    return Container( 
                  height: 100,
                  margin: EdgeInsets.all(2),
                  padding: EdgeInsets.symmetric(
                    vertical: 25,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color : Colors.white, 
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Enter search term and press > to search.",
                    maxLines: 3,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                    ),
                    ),
              );
  }
  else
  {
  return  Slidable(
              actionPane: SlidableDrawerActionPane(),
              actionExtentRatio: 0.25, 
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 70,
                padding: EdgeInsets.symmetric(
                  horizontal:3
                ),
                margin: EdgeInsets.symmetric(
                  vertical : 5.5,                 
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft : Radius.circular(10),
                    bottomLeft : Radius.circular(10),
                  )
                ),
                child: ListTile(
                leading: getCurrentFileIconforList(),
                trailing: Icon(Icons.arrow_forward_ios),
                title: Text(
                  project.fileName,
                  maxLines: 2,
                ),
                subtitle: Text(
                  project.fileUrl,
                  maxLines: 1,
                ),
                // trailing: Icon(Icons.more_vert),
                dense: false,
                onTap: (){
                    this._currentfileName = project.fileName;
                    this._currentfileUrl = project.fileUrl;  
                    _settingModalBottomSheet(context);
                },
                ),
            ),
            secondaryActions: <Widget>[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7)
                ),
                child: IconSlideAction(
                caption: 'Download',
                color: Colors.greenAccent,
                icon: Icons.file_download,
                onTap: (){
                  _prepare(project.fileName,project.fileUrl);
                },
              ),
              ),
              
            ],
        );
  }
}

getCurrentFileIconforList()
{ 
  // var _fileTypes = ['pdf','docx','xlsx','ppt','csv'];
  if(this._currentFileType=="pdf")
    return FaIcon(FontAwesomeIcons.solidFilePdf,color: Colors.redAccent,);  
  if(this._currentFileType=="docx")
    return FaIcon(FontAwesomeIcons.solidFileWord,color: Colors.blueAccent,);  
  if(this._currentFileType=="xlsx")
    return FaIcon(FontAwesomeIcons.solidFileExcel,color: Colors.greenAccent,);  
  if(this._currentFileType=="ppt")
    return FaIcon(FontAwesomeIcons.solidFilePowerpoint,color: Colors.orangeAccent,);  
  if(this._currentFileType=="csv")
    return FaIcon(FontAwesomeIcons.fileCsv,color: Colors.greenAccent,);  
  else
    return FaIcon(FontAwesomeIcons.solidFile,color: Colors.amber,);
}
_animatedlistbuildItem(BuildContext context, FileModel obj, Animation<double> animation)
{
    return SizeTransition(
      key: ValueKey<int>(0),
      axis: Axis.horizontal,
      sizeFactor: animation,
      child: _buildlistelement(obj),
    );
}

getresults()async
{
  if(this._searchText=="" || this._searchText==null)
  {
    _removeAllItems();
    FlushbarCustom.buildFlusbar("Input cannot be empty","Enter valid text and search...","warning")..show(context);
    _addItem(new FileModel("1", "home", "1","1", "1"));
  }
  else
  {
    if(this._connectionStatus=="Success")
    {
      _removeAllItems();
      _addItem(new FileModel("Search in progress", "load", "type"," domain", "desc"));
      var resultlist = await service.getLottoResults(this._currentFileType, this._searchText, this._connectionStatus);
      if(resultlist!=null && resultlist.length==0)
      {
        _removeAllItems();
        _addItem(new FileModel("No result found", "show", "type"," domain", "desc"));
        FlushbarCustom.buildFlusbar("No data found!!!", "", "level")..show(context);
      }
      else
      {
        _removeAllItems();
        for(int i =0;i<resultlist.length;i++){_addItem(resultlist[i]);}
      }
    }
    else{FlushbarCustom.buildFlusbar("Internet required", "check your internet connection and try again", "level")..show(context);}
  }
}

gercurrentfilename()
{
  return this._currentfileName;
}

getbottompopupbody()
{
  return CustomScrollView(
    slivers: <Widget>[
      SliverList(
        delegate: SliverChildListDelegate([
          Container(
            child: Text(
              this._currentfileName,
            ),
          ),
          Container(
            child: Text(
              this._currentfileUrl,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Icon(Icons.access_alarm),
              Icon(Icons.access_alarm),
              Icon(Icons.access_alarm),
            ],
          ),
        ]),
      ),
    ],
  );
  
}

changefiletype(String ftype)
{
  setState(() {
    this._currentFileType=ftype;
  });
  getresults();
}
 
//  Widget popupmenubutton()
//  {
//    return PopupMenuButton<String>(
//      itemBuilder: (BuildContext context)=><PopupMenuEntry<String>>[
//        PopupMenuItem(child: Icon(Icons.info),value: "About",)
//      ],...
//    );
//  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size; //this gonna give us total height and with of our device
    var _fileTypes = ['pdf','docx','xlsx','ppt','csv'];
        return Scaffold(
          // header section part
          backgroundColor: Colors.teal[900],
          body: Stack(
            children: <Widget>[
              Container( 
                height: size.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xff5cdb95), Color(0xff379683)],begin: Alignment.topLeft,end: Alignment.bottomRight,),
                ),
              ),
=======
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
              
>>>>>>> 181ec160da02e628d6cc439edafd4c9577bf954d
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
<<<<<<< HEAD
                      //cornor icon
                        // constants.cornorIcon()
                    // ,
                    // header text
                       Container(
                         decoration: BoxDecoration(
                         ),
                         margin: EdgeInsets.only(
                           top : 10,
                           left:5,
                         ),
                         child: Row(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: <Widget>[
                             headerfiler,
                           ],
                         ),
                       )
                    ,
                    Container(
                      height: 50,
                      margin: EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal : 25,
                        vertical : 3,
=======
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
>>>>>>> 181ec160da02e628d6cc439edafd4c9577bf954d
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(29.5),
                        color : Colors.white,
                      ),
                      child: TextField(
<<<<<<< HEAD
=======
                        // autofocus: true,
>>>>>>> 181ec160da02e628d6cc439edafd4c9577bf954d
                        decoration: InputDecoration(
                          hintText : "Search...",
                          icon : SvgPicture.asset("assets/icons/search.svg"),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.arrow_forward_ios), 
                            onPressed: (){
<<<<<<< HEAD
                              FocusScope.of(context).requestFocus(new FocusNode());
=======
>>>>>>> 181ec160da02e628d6cc439edafd4c9577bf954d
                              getresults();
                            }
                            ),
                        ),
                        onChanged: (String value){
                          setState(() {
                            this._searchText = value;
<<<<<<< HEAD
=======
                            this._loading = false; 
>>>>>>> 181ec160da02e628d6cc439edafd4c9577bf954d
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
<<<<<<< HEAD
                              getresults();
=======
>>>>>>> 181ec160da02e628d6cc439edafd4c9577bf954d
                            },
                            value: this._currentFileType,
                          ),
                        ),
<<<<<<< HEAD
                ),
                
                Expanded(
                  child: Center(
                    child: Container(
                      width: size.width,
                      decoration: BoxDecoration(
                        borderRadius:BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        color: Colors.transparent,
                      ),
                      child: AnimatedList(
                        key: listKey,
                        initialItemCount: alistitems.length,
                        itemBuilder: (context, index, animation) =>_animatedlistbuildItem(context, alistitems[index], animation),
                      ),
                    ),
                  )
                )
                ],
              ),
            ),
            
          ),
         
        ],
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        curve: Curves.bounceInOut,  
        child : Image.asset('assets/icons/float.png'),
        backgroundColor: Colors.teal[900],
        children: [
          SpeedDialChild(
            child: Icon(FontAwesomeIcons.chevronDown,
              color: Colors.white,
            ),
            label: "Downloads",
            backgroundColor: Colors.blue,
            onTap: (){
              Navigator.of(context).pushNamed("/downloads");
            },
          ),
          SpeedDialChild(
            child: Icon(FontAwesomeIcons.infoCircle,
            color: Colors.white,
            ),
            label: "About",
            backgroundColor: Colors.black87,
            onTap: (){
              showAboutDialog(
                context: context,
                applicationName: "Filer",
                applicationVersion: "1.0.3",
                children: [
                  Text(
                    "browse, download, share files from internet",
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w300,
                    ),
                    ),
                ]
                );
            },
          ),
          ],
      ),
    );
  }

_shareUrl(String text, String url)
{
  FlutterShare.shareText('Filer sharing a file Url of '+text+" "+url);
}

 void _settingModalBottomSheet(context){
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc){
        return Container(
          child: new Wrap(
            children: <Widget>[
              new Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(
                  left:20,
                ),
                decoration: BoxDecoration(
                  color: Colors.teal[900],
                ),
                height: 50,
                width: MediaQuery.of(context).size.width,
                child: Text(
                        "File Menu",
                        style: TextStyle(
                          color:Colors.white,
                          fontWeight:FontWeight.w300,
                          fontSize: 24,
                        ),
                      ),
              ),
              new ListTile( 
                title:Container(
                  padding: EdgeInsets.symmetric(
                    vertical:10,
                    horizontal:5,
                  ),
                  child: new Text(
                    this._currentfileName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.amber,
                      fontSize: 28,
                    ),
                    ),
                ),
                subtitle: new Text(
                  this._currentfileUrl,
                  ),
                onTap: () => {}          
              ),
              Container(
                margin: EdgeInsets.all(10),
                height: 70,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Container(
                      child: IconSlideAction(
                        caption :"Download",
                        icon : Icons.file_download,
                        onTap:(){ _prepare(this._currentfileName, this._currentfileUrl);},
                      ),
                    ),
                    Container(
                      child: IconSlideAction(
                        caption :"Share Url",
                        icon : FontAwesomeIcons.creativeCommonsShare,
                        onTap:(){_shareUrl(this._currentfileName,this._currentfileUrl);},
                      ),
                    ),
                    Container(
                      child: IconSlideAction(
                        caption :"close",
                        icon : Icons.close,
                        onTap: (){Navigator.pop(context);},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
}

}



//flutter donwloader classes
class _TaskInfo {
  final String name;
  final String link;

  String taskId;
  int progress = 0;
  DownloadTaskStatus status = DownloadTaskStatus.undefined;

  _TaskInfo({this.name, this.link,this.status});
}

class _ItemHolder {
  final String name;
  final _TaskInfo task;

  _ItemHolder({this.name, this.task});
}

=======
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
>>>>>>> 181ec160da02e628d6cc439edafd4c9577bf954d
