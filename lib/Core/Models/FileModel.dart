class FileModel{

  String fileUrl;
  String filetype;
  String fileName;
  String filedomain;
  String filedescription;
  
  FileModel(String name,String url, String type, String domain, String desc)
  {
    this.fileName = name;
    this.fileUrl = url;
    this.filetype = type;
    this.filedomain = domain;
    this.filedescription = desc;
  }
  

  String getfileName()
  {
    return this.fileName;
  }
  String getfileUrl()
  {
    return this.fileUrl;
  }
  String getfieltype()
  {
    return this.filetype;
  }
  String getfileDomain()
  {
    return this.filedomain;
  }
  String getfileDescription()
  {
    return this.filedescription;
  }
  setfileName(String name){
    this.fileName = name;
  }
  setfileUrl(String href){
    this.fileUrl = href;
  }
}