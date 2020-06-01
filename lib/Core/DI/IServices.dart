// handles data scraping

import 'package:filer/Core/Models/FileModel.dart';

abstract class IServices{
  //Get lotto results
  // <List<FileModel>>
<<<<<<< HEAD
  Future<List<FileModel>> getLottoResults(String ftype, String qry, String checknet);
  // checkInternetConnection();
=======
  Future getLottoResults(String ftype, String qry);
>>>>>>> 181ec160da02e628d6cc439edafd4c9577bf954d

}