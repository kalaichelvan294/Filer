import 'dart:io';
import 'package:date_time_format/date_time_format.dart';
import 'package:filer/Core/Models/DownloadFileModal.dart';
import 'package:filer/widgets/headerFiler.dart';
import 'package:filesize/filesize.dart';
import 'package:flushbar/flushbar_helper.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_share_plugin/flutter_share_plugin.dart';

class Downloads extends StatefulWidget{
    @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<Downloads>{
  
  List<DownloadFile> alistitems = new List<DownloadFile>();
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  DownloadFile _currentFileobject = new DownloadFile("", "", "","","");
  String _folderpath = "";
  int filecounter = 0;

  _addItem(DownloadFile resultitem) {
    setState(() {
      listKey.currentState.insertItem(alistitems.length, duration: const Duration(milliseconds: 500));
      alistitems.add(resultitem);
    });
  }

  _removeAllItems() {
    final int itemCount = alistitems.length;
    for (var i = 0; i < itemCount; i++) {
      DownloadFile itemToRemove = alistitems[0];
      listKey.currentState.removeItem(0,
        (BuildContext context, Animation animation) => _animatedlistbuildItem(context, itemToRemove, animation),
        duration: const Duration(milliseconds: 250),
      );
      alistitems.removeAt(0);
    }
  }

  _animatedlistbuildItem(BuildContext context, DownloadFile obj, Animation<double> animation)
  {
      return SizeTransition(
        key: ValueKey<int>(0),
        axis: Axis.horizontal,
        sizeFactor: animation,
        child: _buildlistelement(obj),
      );
  }

_buildlistelement(project)
{
  if(project.fileSize=="-0-")
  {
   return Container(
     decoration: BoxDecoration(
       color: Colors.white,
     ),
     child: Card(
       child: ListTile(
         leading: Icon(Icons.warning),
         title:Text("No files found in this location"),
         subtitle: Text("Files may be moved, deleted or empty, check this directory : "+this._folderpath),
       ),
     ),
   );
  }
  else
  {
  return  Container(
    decoration: BoxDecoration(
       color: Colors.white,
     ),
    child: ListTile(
                  leading: getCurrentFileIconforList(),
                  trailing: Icon(Icons.arrow_forward_ios),
                  title: Text(
                    project.fileName,
                    maxLines: 2,
                  ),
                  subtitle: Text(
                    project.fileName,
                    maxLines: 1,
                  ),
                  // trailing: Icon(Icons.more_vert),
                  dense: false,
                  onTap: (){
                      this._currentFileobject = project;
                      _settingModalBottomSheet(context);
                  },
                  ),
  );
  }
}

getCurrentFileIconforList()
{ 

  if(this._currentFileobject.fileType=="pdf")
    return FaIcon(FontAwesomeIcons.solidFilePdf,color: Colors.redAccent,);  
  if(this._currentFileobject.fileType=="docx")
    return FaIcon(FontAwesomeIcons.solidFileWord,color: Colors.blueAccent,);  
  if(this._currentFileobject.fileType=="xlsx")
    return FaIcon(FontAwesomeIcons.solidFileExcel,color: Colors.greenAccent,);  
  if(this._currentFileobject.fileType=="ppt")
    return FaIcon(FontAwesomeIcons.solidFilePowerpoint,color: Colors.orangeAccent,);  
  if(this._currentFileobject.fileType=="csv")
    return FaIcon(FontAwesomeIcons.fileCsv,color: Colors.greenAccent,);  
  else
    return FaIcon(FontAwesomeIcons.solidFile,color: Colors.amber,);
}

_deleteFile(){
  String path = this._currentFileobject.filePath;
  File fle = new File(path);
  fle.delete();
  Navigator.pop(context);
  FlushbarHelper.createSuccess(message: "File deleted Successfully");
  _removeAllItems();
  findallfiles();
}

Future<void> shareFile() async {
    FlutterShare.shareFileWithText(
      textContent: "File share by Filer ",      
      filePath: this._currentFileobject.filePath
    );
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
                  color: Colors.cyan[900],
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
                leading: getCurrentFileIconforList(),
                title:Container(
                  padding: EdgeInsets.symmetric(
                    vertical:10,
                    horizontal:5,
                  ),
                  child: new Text(
                    this._currentFileobject.fileName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.amber,
                      fontSize: 28,
                    ),
                    ),
                ),
                subtitle: Row(
                  children: <Widget>[
                    Text(
                      'Size : '+this._currentFileobject.fileSize,
                      ),
                      Spacer(),
                    Text(
                      'Date : '+this._currentFileobject.fileDate,
                    ),
                  ],
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
                        caption :"Open",
                        icon : FontAwesomeIcons.solidFolderOpen,
                        onTap:() async { 
                          print(this._currentFileobject.filePath);
                          try{
                          OpenFile.open(this._currentFileobject.filePath);
                          }catch(e)
                          {
                            print(e);
                          }
                        },
                      ),
                    ),
                    Container(
                      child: IconSlideAction(
                        caption :"Share",
                        icon : FontAwesomeIcons.creativeCommonsShare,
                        onTap: (){shareFile();},
                      ),
                    ),
                    Container(
                      child: IconSlideAction(
                        caption :"Delete",
                        icon : Icons.delete_forever,
                        onTap: (){_deleteFile();},
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


  Future<bool> _checkPermission() async {
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
    return false;
  }


  Future<Directory> _findLocalPath() async {
    Directory directory = await getExternalStorageDirectory();
    print("path------------>"+directory.path.toString());
    // print(directory.path);
    this._folderpath = directory.path;
    return directory;
  }

  Future findallfiles() async{
    if(await _checkPermission()==false)
    {
      FlushbarHelper.createError(message: "Storage permission required") ;
    }
    final downloadsfolder = await _findLocalPath();
    if(downloadsfolder==null)
    {
      print("null value returned");
      return;
    }
    _removeAllItems();
    this.filecounter=0;
    Stream<FileSystemEntity> folderdata = downloadsfolder.list();
    folderdata.forEach((FileSystemEntity fse) async {
      FileStat fs = await fse.stat();
      bool _isfile = await FileSystemEntity.isFile(fse.path);
        if(_isfile)
        {
          print("is file true----------");
          String fpath = fse.path;
          String fname = fpath.substring(fpath.lastIndexOf("/")+1);
          String ftype = "unknown";
          int ftypeind = fname.indexOf('.');
          print(ftypeind);
          if(ftypeind!=-1)
            ftype = fname.substring(ftypeind+1);
          String fdate =  DateTimeFormat.format(fs.accessed, format: DateTimeFormats.american).toString();
          print(fs.size);
          String fsize = filesize(fs.size).toString();
          print("file path: "+ fpath);
          print("file name: "+ fname);
          print("file type: "+ ftype);
          print("access time: "+fdate);
          print("file size: "+ fsize);
          // File obj = new File(fse.path);
          this._currentFileobject = new DownloadFile(fname,fsize,ftype,fpath,fdate);
          _addItem(this._currentFileobject);
          this.filecounter++;
        }
    });
    if(this.filecounter==0)
    {
      _addItem(DownloadFile("No files found","-0-","","",""));
    }
  }

  @override
  void initState() {
    super.initState();
    alistitems.add(new DownloadFile("Not yet released!!!","","","path","date"));
    findallfiles();
  }


  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      
      var size = MediaQuery.of(context).size; //this gonna give us total height and with of our device
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
                       Container(
                         decoration: BoxDecoration(
                         ),
                         margin: EdgeInsets.only(
                           top : 10,
                           left:5,
                         ),
                         child: Row(
                           crossAxisAlignment: CrossAxisAlignment.center,
                           children: <Widget>[
                              headerfiler,
                              Spacer(),
                              Text(
                                "Downloads",
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w100,
                                ),
                              )
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: Icon(Icons.arrow_back_ios,),
        onPressed: () {Navigator.pop(context);}
        ),
    );
  }

}