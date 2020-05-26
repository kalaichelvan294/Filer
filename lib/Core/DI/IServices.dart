// handles data scraping

import 'package:filer/Core/Models/FileModel.dart';

abstract class IServices{
  //Get lotto results
  // <List<FileModel>>
  Future getLottoResults(String ftype, String qry);

}