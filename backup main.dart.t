import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:filer/Core/Models/FileModel.dart';
import 'package:filer/Services/services.dart';
import 'package:flutter/material.dart';
import 'package:filer/constants.dart' as constants;
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:solid_bottom_sheet/solid_bottom_sheet.dart';
import 'classes/custom_flushbar.dart';
import 'constants.dart';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flushbar/flushbar_helper.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:progress_indicators/progress_indicators.dart';


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
        scaffoldBackgroundColor: kBackgroundColor,
        textTheme: Theme.of(context).textTheme.apply(displayColor: kTextColor),
      ),
      home: MyHomePage(
        title: 'Filer',
        platform: platform,
        ),
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
  
  SolidController _bottomcontroller = SolidController();
  String _currentFileType = 'pdf';
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
    
  // String _downloadFileUrl="";
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
    _localPath = (await _findLocalPath()) + '/Filer';
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
    listKey.currentState.insertItem(alistitems.length, duration: const Duration(milliseconds: 100));
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
      child: LinearProgressIndicator(),
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
                height: 65,
                padding: EdgeInsets.symmetric(
                  vertical:4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white70,
                ),
                child: ListTile(
                leading: getCurrentFileIconforList(),
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
                  // print(this._currentfileName);
                  // _bottomcontroller.isOpened ? _bottomcontroller.hide() : _bottomcontroller.show();
                  // print("optap---");                  
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

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size; //this gonna give us total height and with of our device
    var _fileTypes = ['pdf','docx','xlsx','ppt','csv'];
        return Scaffold(
          // header section part
          body: Stack(
            children: <Widget>[
              Container( 
                height: size.height,
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
                      //cornor icon
                        constants.cornorIcon()
                    ,
                    // header text
                       Text(
                          "Filer",
                          style: Theme.of(context)
                          .textTheme
                          .display2
                          .copyWith(fontWeight: FontWeight.w900),
                        )
                    ,
                    // input search box
                    Container(
                      height: 50,
                      margin: EdgeInsets.symmetric(
                        vertical: 17,
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
                              getresults();
                            },
                            value: this._currentFileType,
                          ),
                        ),
                      // ),

                ),

                Expanded(
                child: AnimatedList(
                  key: listKey,
                  initialItemCount: alistitems.length,
                  itemBuilder: (context, index, animation) =>_animatedlistbuildItem(context, alistitems[index], animation),
                )
                )
                ],
              ),
            ),
          ),
         
        ],
        
      ),

      bottomSheet: SolidBottomSheet(
        controller: _bottomcontroller,
        draggableBody: true,
        
        // minHeight: size.height*.40,
        maxHeight: size.height*.40,
        // toggleVisibilityOnTap:true,
        // headerBar: Container(
        //   color: Theme.of(context).primaryColor,
        //   // height: 50,
        //   child: null
        //   ),
        // ),
        headerBar: null, 
        body:getbottompopupbody(), 
        // body: Container(
        //   color: Colors.white,
        //   height: 30,
        //   child: Center(
        //     child: Text(
        //       "Hello! I'm a bottom sheet :D",
        //       style: Theme.of(context).textTheme.display1,
        //     ),
        //   ),
        // ),
      ),
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

