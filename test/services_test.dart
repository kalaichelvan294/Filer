import 'package:filer/Services/services.dart';
import 'package:test/test.dart';

void main(){

  group("services test", (){
    test("Get Recent result test", () async{
      var sut = Services();

      var result = await sut.getLottoResults("pdf","aukdc");

      // expect( result.length > 0, true);
    });
  });

}