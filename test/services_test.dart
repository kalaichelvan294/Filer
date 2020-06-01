<<<<<<< HEAD
// import 'package:filer/Services/services.dart';
=======
import 'package:filer/Services/services.dart';
>>>>>>> 181ec160da02e628d6cc439edafd4c9577bf954d
import 'package:test/test.dart';

void main(){

  group("services test", (){
    test("Get Recent result test", () async{
<<<<<<< HEAD
      // var sut = Services();
      // var res = await sut.checkInternetConnection();
      // print(res);
      // var result = await sut.getLottoResults("pdf","aukdc","s");
=======
      var sut = Services();

      var result = await sut.getLottoResults("pdf","aukdc");

>>>>>>> 181ec160da02e628d6cc439edafd4c9577bf954d
      // expect( result.length > 0, true);
    });
  });

}