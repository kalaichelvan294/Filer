// handles data scraping

import 'package:filer/Core/Models/FileModel.dart';

abstract class IServices{
  //Get lotto results
  // <List<FileModel>>
  Future<List<FileModel>> getLottoResults(String ftype, String qry, String checknet);
  // checkInternetConnection();

}