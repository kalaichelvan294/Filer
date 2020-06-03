import 'package:filer/Core/DI/IServices.dart';
import 'package:filer/Core/Models/FileModel.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:html/dom.dart';


class Services implements IServices{  
  
  @override
  Future<List<FileModel>> getLottoResults(String ftype, String qry, String checknet) async {
    print(ftype+"---"+qry);
    String typer = "."+ftype;
    String urlm1="https://www.google.com/search?q="+qry+"+filetype%3A"+ftype+"""
      &oq="""+qry+"+filetype&aqs=chrome.0.69i59j69i57.4432j0j9&sourceid=chrome&ie=UTF-8";          
    String urlm2="https://www.google.com/search?q="+qry+"""
      +filetype%3A"""+ftype+"&oq="+qry+"+filetype&aqs=chrome.0.69i59j69i57.4432j0j9&sourceid=chrome&ie=UTF-8&start=20";
    
    List<FileModel> resultelements = new List<FileModel>();
    if(checknet=="Failed")
      return resultelements;
    try 
    {
      var res = await http.
      get(urlm1)
      .catchError((e){
        return resultelements;
      }); 
      var doc = parse(res.body);
      // print(res.body);
      List<Element> links = doc.querySelectorAll('div.kCrYT > a');
      // print("list elements lenght--> "+links.length.toString());
      for (Element link in links) 
      {
        String tlink = link.attributes['href'];
        tlink.replaceAll("/url?q", "");
        // tlink.replaceAll("%25", "");
        int indhttps = tlink.indexOf("https:");
        if(indhttps!=-1)
          tlink = tlink.substring(indhttps);
        indhttps = tlink.indexOf("&");
        if(indhttps!=-1)
        {
          List<String> tls = tlink.split("&");
          tlink = tls.elementAt(0);
        }
        tlink = Uri.decodeFull(tlink);
        
        List<Element> divel = link.querySelectorAll("div");
        tlink = tlink.replaceAll("/url?q=","");
        List<String> tx = tlink.split(typer);
        tlink = tx.elementAt(0)+typer;
        Element div1 = divel.elementAt(0);
        Element div2 = divel.elementAt(1);
        String tname = div1.text;
        if(tname.length>6)
          tname = tname.substring(6,tname.length);
        String tdomain = div2.text;
        if(tlink.indexOf(typer)!=-1)
        {
          FileModel obj = new FileModel(tname,tlink,qry,tdomain,"desc");
          resultelements.add(obj);
        }
      
      }

      var res1 = await http.
      get(urlm2)
      .catchError((e){
        return resultelements;
      });
      var doc1 = parse(res1.body);
      List<Element> links1 = doc1.querySelectorAll('div.kCrYT > a');
      // print("list elements lenght--> "+links1.length.toString());
      for (Element link in links1) 
      {
        String tlink = link.attributes['href'];
        tlink.replaceAll("/url?q", "");
        int indhttps = tlink.indexOf("https:");
        if(indhttps!=-1)
          tlink = tlink.substring(indhttps);
        indhttps = tlink.indexOf("&");
        if(indhttps!=-1){
          List<String> tls = tlink.split("&");
          tlink = tls.elementAt(0);
        }
        tlink = Uri.decodeFull(tlink);

        List<Element> divel = link.querySelectorAll("div");
        tlink = tlink.replaceAll("/url?q=","");
        List<String> tx = tlink.split(typer);
        tlink = tx.elementAt(0)+typer;
        Element div1 = divel.elementAt(0);
        Element div2 = divel.elementAt(1);
        String tname = div1.text;
        if(tname.length>6)
          tname = tname.substring(6,tname.length);
        String tdomain = div2.text;
        if(tlink.indexOf(typer)!=-1)
        {
        FileModel obj = new FileModel(tname,tlink,qry,tdomain,"desc");
        resultelements.add(obj);
        }
      }
    }
    catch(e)
    {
      print(e);
      print("result element --> "+resultelements.length.toString());
      return resultelements;
    }
    
    print("result element --> "+resultelements.length.toString());
    return resultelements;
  }//getlottoresults

}//services
