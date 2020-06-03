import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:filer/widgets/headerFiler.dart';
import 'package:flutter_awesome_buttons/flutter_awesome_buttons.dart';
import 'package:flutter_mobile_vision/flutter_mobile_vision.dart';
import 'package:flutter_share_plugin/flutter_share_plugin.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:package_info/package_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:filer/Core/Models/FileModel.dart';
import 'package:filer/Services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sleek_button/sleek_button.dart';
import 'classes/custom_flushbar.dart';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flushbar/flushbar_helper.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'downloads.dart';
import 'package:url_launcher/url_launcher.dart';


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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Filer',
      theme: ThemeData(
        fontFamily: "Cairo",
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
    );
  }
}

class MyHomePage extends StatefulWidget{

  final TargetPlatform platform;

  MyHomePage({Key key, this.title,this.platform}) : super(key: key);
  final String title;
  
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  String _currentFileType = 'pdf';
  String _searchText = "";  
  var searchtextctrl = new TextEditingController();
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

//camera ocr text
    int _cameraOcr = FlutterMobileVision.CAMERA_BACK;
    // bool _autoFocusOcr = true;
    bool _torchOcr = false;
    // bool _multipleOcr = true;
    // bool _waitTapOcr = true;
    // bool _showTextOcr = true;
    Size _previewOcr;
    List<OcrText> _textsOcr = [];
    String _ocrtextsearch = "";

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
  FlutterMobileVision.start().then((previewSizes) => setState(() {
    _previewOcr = previewSizes[_cameraOcr].first;
  }));
  _inAppUpdatedialog(false);
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

    Future<bool> _checkcamPermission() async {
      if (widget.platform == TargetPlatform.android) {
        PermissionStatus permission = await PermissionHandler()
            .checkPermissionStatus(PermissionGroup.camera);
        if (permission != PermissionStatus.granted) {
          Map<PermissionGroup, PermissionStatus> permissions =
              await PermissionHandler()
                  .requestPermissions([PermissionGroup.storage]);
          if (permissions[PermissionGroup.camera] == PermissionStatus.granted) {
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
  else if(this._connectionStatus=="Success"){
    FlushbarCustom.internetEnabled()..show(context);
    }

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
                    "Enter query or use lens and press > to search.",
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

  Future<Null> _read() async {
    _checkcamPermission();
    List<OcrText> texts = [];
    try {
      texts = await FlutterMobileVision.read(
        flash: _torchOcr,
        autoFocus: true,
        multiple: true,
        waitTap: false,
        showText: true,
        preview: _previewOcr,
        camera: _cameraOcr,
        fps: 2.0,
      );
    }catch(e){
      print("kn exception "+e.toString());
      texts.add(OcrText('Failed to recognize text.'));
    }

    if (!mounted) return;

    setState(() => _textsOcr = texts);
    _ocrtextsearch = "";
    for (var item in _textsOcr) {
      _ocrtextsearch += item.value;
    }

    if(_ocrtextsearch=='Failed to recognize text.')
    {
      print('ocr text recog failed');
      searchtextctrl.text = "No text found!!!";
    }
    else
    {
      searchtextctrl.text = this._ocrtextsearch =  this._ocrtextsearch.trim();
      print(this._ocrtextsearch);
    }
  }

  _inAppUpdatedialog(bool chk)
  async {
    final String appcastURL = 'https://raw.githubusercontent.com/kalaichelvan-kn/Filer/master/inAppUpdate.json';
    try
    {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    final versionnumbers = int.parse(version.replaceAll(".",""));
    print("old version :"+versionnumbers.toString());
      if(_connectionStatus=="Success")
      {
        final url = Uri.parse(appcastURL);
        final response = await http.get(url);
        if(response.statusCode==200)
        {
          final updatedata = json.decode(response.body);
          String versionn = updatedata['version'];
          final versionnumbersn = int.parse(versionn.replaceAll(".",""));
          print("new version :"+versionnumbersn.toString());
          if(versionnumbers<versionnumbersn)
          {
            _showupdatedialog(true,version,versionn,updatedata["download"]);
          }
          else{
            if(chk)
              _showupdatedialog(false,"","","");
            }
        }
        else
        {
          FlushbarHelper.createInformation(message: "No response from app update server!");
        }
      }
    }
    catch(e)
    {
      print("Exception kn "+e.toString());
      FlushbarHelper.createError(message: "some error occured!!!");
    }
  }

  _showupdatedialog(bool available,String oldver,String newver,String url)
  {
    if(available)
    {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext bc){
          return Container(
            child: new Wrap(
              children: <Widget>[
                Container(
                  child : ListTile(
                    leading: Icon(
                      Icons.system_update,
                      color: Colors.orange,
                      ),
                    title: Text(
                      "New version of Filer is available.",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:FontWeight.w500,
                      )
                    )
                  )
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children:<Widget>[
                      SleekButton(
                        onTap: ()async{
                          Navigator.pop(context);
                        },
                        style: SleekButtonStyle.flat(
                          color: Colors.red,
                          inverted: true,
                          rounded: true,
                          size: SleekButtonSize.medium,
                          context: context,
                          ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                              const Icon(Icons.cancel),
                              const SizedBox(width: 6),
                              const Text('Cancel'),
                          ],
                        ),
                      ),
                      SleekButton(
                        onTap: ()async{
                          try{await launch(url);}catch(e){print(e);}
                        },
                        style: SleekButtonStyle.flat(
                          color: Colors.green,
                          inverted: true,
                          rounded: true,
                          size: SleekButtonSize.medium,
                          context: context,
                          ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                              const Icon(Icons.check),
                              const SizedBox(width: 6),
                              const Text('Update'),
                          ],
                        ),
                      ),
                    ]
                  ),
                )
              ],
            ),
          );
        }
      );
    }
    else
    {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext bc){
          return Container(
            child: new Wrap(
              children: <Widget>[
                Container(
                  child : ListTile(
                    leading: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      ),
                    title: Text(
                      "Already up to date.",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:FontWeight.w500,
                      ),
                    ),
                    trailing: IconButton(
                     icon : Icon(Icons.cancel,color: Colors.black), onPressed: () { Navigator.pop(context); },
                    ),
                  )
                ),
              ],
            ),
          );
        }
      );
    }
  }

  _aboutdialog()
  {
    return showAboutDialog(
            context: context,
            applicationIcon: Image.asset(
              "assets/icons/float.png",
              width: 35,
              height: 35,
            ),
            applicationName: "Filer",
            applicationVersion: "1.0.1",
            children: [
              Text(
                "Browse, Download, Dhare files from internet",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w500,
                ),
                ),
            ]
          );
  }


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
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(29.5),
                        color : Colors.white,
                      ),
                      child: TextField(
                        controller: searchtextctrl,
                        decoration: InputDecoration(
                          hintText : "Search...",
                          icon : SvgPicture.asset("assets/icons/search.svg"),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.arrow_forward_ios), 
                            onPressed: (){
                              FocusScope.of(context).requestFocus(new FocusNode());
                              getresults();
                            }
                            ),
                        ),
                        onChanged: (String value){
                          setState(() {
                            this._searchText = value;
                          });
                        },
                      ),
                    ),
                    
                    Container(
                      height: 50,
                      margin: EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal : 25,
                      ),
                      decoration: BoxDecoration(
                        // borderRadius: BorderRadius.circular(29.5),
                      ),
                      // child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          // crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: 200,
                              height: 45,
                              decoration: BoxDecoration(
                                color:Colors.white,
                                borderRadius: BorderRadius.all(Radius.circular(10))
                              ),
                              padding: EdgeInsets.only(
                                left:18,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: Colors.greenAccent[400],
                                  focusColor: Colors.black,
                                  items: _fileTypes.map((String dropDownstringItem){
                                    return DropdownMenuItem<String>(
                                      value: dropDownstringItem,
                                      child: Text(
                                        dropDownstringItem,
                                        style:TextStyle(
                                          color:Colors.black,
                                          fontWeight:FontWeight.w500,
                                        )
                                        ),
                                      );
                                  }).toList(), 
                                  isExpanded: false,
                                  onChanged: (String newfileType){
                                    setState(() {
                                      this._currentFileType = newfileType;
                                    });
                                    getresults();
                                  },
                                  value: this._currentFileType,
                                ),
                              ),
                            ),
                            Spacer(),
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color:Colors.green[800],
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                              child: RoundedButtonWithIcon(
                                onPressed: (){_read();},
                                icon:Icons.camera_alt,
                                title: "  Lens",
                                textColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
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
            child: Icon(Icons.system_update,
            color: Colors.black,
            ),
            label: "check Update",
            backgroundColor: Colors.yellowAccent[400],
            onTap: (){
              _inAppUpdatedialog(true);
            },
          ),
          SpeedDialChild(
            child: Icon(FontAwesomeIcons.infoCircle,
            color: Colors.white,
            ),
            label: "About",
            backgroundColor: Colors.black87,
            onTap: (){
              _aboutdialog();
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
