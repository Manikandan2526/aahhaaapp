import 'dart:async';
import 'dart:io' as io;
//import 'dart:js';
//import 'package:path/path.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
//import '../models.dart';
import 'package:http/http.dart' as http; //package to make a http get call
import 'dart:convert'; //package to decode json response from api
// import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'package:aahhaaapp/common/messagebox.dart' as messagebox;
import 'package:aahhaaapp/config.dart';

class DbHelper {
  late Database myDb;

  Future<Database> get db async {
    myDb = await initDb();
    return myDb;
  }

  initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = "${documentsDirectory.path}/aahhaaapp.db";
    var theDb = await openDatabase(path, version: 2, onCreate: onCreate);
    return theDb;
  }

  Future<void> onCreate(Database db, int version) async {
    await db.execute(
        "CREATE TABLE tblCompany(companyid INTEGER, companyname TEXT)");
  }

  Future<dynamic> saveCompany(Company company) async {
    var dbClient = await db;

    await dbClient.transaction((txn) async {
      return await txn.insert(
        'tblCompany',
        company.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<List<Company>> getCompanyList() async {
    var dbClient = await db;

    List<Map> list = await dbClient.rawQuery('SELECT * FROM tblCompany');
    List<Company> companylist = <Company>[];
    for (int i = 0; i < list.length; i++) {
      var company = Company(
        companyid: list[i]['companyid'],
        companyname: list[i]['companyname'],
      );
      companylist.add(company);
    }

    return companylist;
  }

  Future<String> validateLogin(emailid, password) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var apiURL = myApiBaseURL;
      // var posid = prefs.getString("POSId");

      var params = {
        "LoginEmail": emailid,
        "LoginPassword": password,
      };
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': "",
      };

      final response = await http
          .post(
            Uri.parse("$apiURL/ValidateLoginForMobileApp"),
            headers: headers,
            body: jsonEncode(params),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        var result = json.decode(response.body.toString());
        var status = result["Status"];
        if (status == "valid") {
          Map<String, String> headers1 = {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${result["Token"].toString()}',
          };

          var params1 = {
            "LoginId": result["Data"]['Ref'].toString(),
          };

          final companyres = await http
              .post(
                Uri.parse("$apiURL/GetCompaniesForLogin"),
                headers: headers1,
                body: jsonEncode(params1),
              )
              .timeout(const Duration(seconds: 60));

          var dbClient = await db;

          await dbClient.rawQuery('DELETE FROM tblCompany');

          var companylist =
              json.decode(companyres.body.toString())["Data"].toList();
          for (int i = 0; i < companylist.length; i++) {
            var company = Company(
              companyid: companylist[i]['CompanyId'],
              companyname: companylist[i]['CompanyName'],
            );

            await saveCompany(company);
          }

          // prefs.setString("tet", response1.body.length as String);

          prefs.setString("Token", result["Token"].toString());
          prefs.setString("Ref", result["Data"]['Ref'].toString());
          return "success";
        } else {
          return result["Data"].toString();
        }
      } else {
        // Navigator.pop(context);
        //messagebox.showMessage("Connection Error!${response.statusCode}", context);
        return "Connection Error!${response.statusCode}";
      }
    } catch (ex) {
      //  Navigator.pop(context);
      //messagebox.showMessage("API Connectivity Issue:Error importing records $ex", context);
      return "API Connectivity Issue:Error!$ex";
    }
  }

  Future<List<POSList>> getPOSList(context) async {
    List<POSList> poslist = <POSList>[];
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var apiURL = myApiBaseURL;
      var companyid = int.parse(prefs.getString("CompanyId").toString());
      var ref = prefs.getString("Ref");

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${prefs.getString("Token").toString()}',
      };

      var params = {
        "Ref": ref,
        "CompanyId": companyid,
      };

      final response = await http
          .post(
            Uri.parse("$apiURL/GetPOSByLoginId"),
            headers: headers,
            body: jsonEncode(params),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        var result = json.decode(response.body.toString());
        var status = result["Status"];
        if (status == "valid") {
          var posresult = result["Data"];

          for (int i = 0; i < posresult.length; i++) {
            if (i == 0) {
              var company1 = POSList(
                posid: 0,
                posname: 'All POS',
              );
              poslist.add(company1);
            }
            var company = POSList(
              posid: posresult[i]['POSId'],
              posname: posresult[i]['POSName'],
            );
            poslist.add(company);
          }

          return poslist;
          //     } else {
          //       return result["Data"].toString();
          //     }
          //   } else {
          //     // Navigator.pop(context);
          //     //messagebox.showMessage("Connection Error!${response.statusCode}", context);
          //     return "Connection Error!${response.statusCode}";
          //   }
          // } catch (ex) {
          //   //  Navigator.pop(context);
          //   //messagebox.showMessage("API Connectivity Issue:Error importing records $ex", context);
          //   return "API Connectivity Issue:Error!$ex";
          // }
        } else {
          messagebox.showMessage(
              "Invalid Data!${result["Data"].toString()}", context);
          return poslist;
        }
      } else {
        messagebox.showMessage(
            "Connection Error!!${response.statusCode}", context);
        return poslist;
      }
    } catch (ex) {
      messagebox.showMessage("Error getting records $ex", context);
      return poslist;
    }
  }

  Future<List<CounterList>> getCounterList(context, posid, saledate) async {
    List<CounterList> counterlist = <CounterList>[];
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var apiURL = myApiBaseURL;
      var companyid = int.parse(prefs.getString("CompanyId").toString());
      var ref = prefs.getString("Ref");

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${prefs.getString("Token").toString()}',
      };

      var params = {
        "Ref": ref,
        "POSId": posid,
        "CompanyId": companyid,
      };

      final response = await http
          .post(
            Uri.parse("$apiURL/GetBillCounters"),
            headers: headers,
            body: jsonEncode(params),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        var result = json.decode(response.body.toString());
        var status = result["Status"];
        if (status == "valid") {
          var counterresult = result["Data"];

          for (int i = 0; i < counterresult.length; i++) {
            if (i == 0) {
              var company1 = CounterList(
                counterid: 0,
                countername: 'All Counters',
              );
              counterlist.add(company1);
            }

            var company = CounterList(
              counterid: counterresult[i]['BillCounterId'],
              countername: counterresult[i]['BillCounterName'],
            );
            counterlist.add(company);
          }

          return counterlist;
          //     } else {
          //       return result["Data"].toString();
          //     }
          //   } else {
          //     // Navigator.pop(context);
          //     //messagebox.showMessage("Connection Error!${response.statusCode}", context);
          //     return "Connection Error!${response.statusCode}";
          //   }
          // } catch (ex) {
          //   //  Navigator.pop(context);
          //   //messagebox.showMessage("API Connectivity Issue:Error importing records $ex", context);
          //   return "API Connectivity Issue:Error!$ex";
          // }
        } else {
          messagebox.showMessage(
              "Invalid Data!${result["Data"].toString()}", context);
          return counterlist;
        }
      } else {
        messagebox.showMessage(
            "Connection Error!!${response.statusCode}", context);
        return counterlist;
      }
    } catch (ex) {
      messagebox.showMessage("Error getting records $ex", context);
      return counterlist;
    }
  }

  Future<List<POSSalesList>> getPOSSalesList(context, fromdate, todate) async {
    List<POSSalesList> possalelist = <POSSalesList>[];
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var apiURL = myApiBaseURL;
      var companyid = int.parse(prefs.getString("CompanyId").toString());
      var posid = int.parse(prefs.getString("POSId").toString());
      var ref = prefs.getString("Ref");

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${prefs.getString("Token").toString()}',
      };

      var params = {
        "Ref": ref,
        "CompanyId": companyid,
        "PosId": posid,
        "FromDate": fromdate,
        "ToDate": todate,
      };

      final response = await http
          .post(
            Uri.parse("$apiURL/GetDailySalesByPOSId"),
            headers: headers,
            body: jsonEncode(params),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        var result = json.decode(response.body.toString());
        var status = result["Status"];
        if (status == "valid") {
          var possalesresult = result["Data"];

          for (int i = 0; i < possalesresult.length; i++) {
            // final DateFormat formatter = DateFormat('yyyy-MM-dd');
            // final saledate = formatter.format(possalesresult[i]['SaleDate']);

            var pos = POSSalesList(
              saledate: possalesresult[i]['SaleDate'].substring(0, 10),
              posid: possalesresult[i]['POSId'],
              posname: possalesresult[i]['POS'],
              totalamount: possalesresult[i]['Amount'],
              gstamount: possalesresult[i]['GST'],
              netamount: possalesresult[i]['TotalSales'],
              cash: possalesresult[i]['Cash'],
              card: possalesresult[i]['Card'],
              online: possalesresult[i]['Online'],
            );

            possalelist.add(pos);

            if (i == possalesresult.length - 1) {
              var poslisttotal = POSSalesList(
                saledate: "",
                posid: 0,
                posname: "Total",
                totalamount: (possalelist.fold(
                    0, (sum, item) => sum + item.totalamount)),
                gstamount:
                    (possalelist.fold(0, (sum, item) => sum + item.gstamount)),
                netamount:
                    (possalelist.fold(0, (sum, item) => sum + item.netamount)),
                cash: (possalelist.fold(0, (sum, item) => sum + item.cash)),
                card: (possalelist.fold(0, (sum, item) => sum + item.card)),
                online: (possalelist.fold(0, (sum, item) => sum + item.online)),
              );
              possalelist.add(poslisttotal);
            }
          }

          return possalelist;
        } else {
          messagebox.showMessage(
              "Invalid Data!${result["Data"].toString()}", context);
          return possalelist;
        }
      } else {
        messagebox.showMessage(
            "Connection Error!!${response.body}", context);
        return possalelist;
      }
    } catch (ex) {
      messagebox.showMessage("Error getting records $ex", context);
      return possalelist;
    }
  }

  Future<List<CounterSalesList>> getCounterSalesList(
      context, posid, counterid, fromdate, todate) async {
    List<CounterSalesList> countersalelist = <CounterSalesList>[];
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var apiURL = myApiBaseURL;
      var companyid = int.parse(prefs.getString("CompanyId").toString());
      //var posid = int.parse(prefs.getString("POSId").toString());
      var ref = prefs.getString("Ref");

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${prefs.getString("Token").toString()}',
      };

      var params = {
        "Ref": ref,
        "CompanyId": companyid,
        "PosId": posid,
        "pBillCounterId": counterid,
        "FromDate": fromdate,
        "ToDate": todate,
      };

      final response = await http
          .post(
            Uri.parse("$apiURL/GetDailySalesByBillCounterId"),
            headers: headers,
            body: jsonEncode(params),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        var result = json.decode(response.body.toString());
        var status = result["Status"];
        if (status == "valid") {
          var counteralesresult = result["Data"];

          for (int i = 0; i < counteralesresult.length; i++) {
            // final DateFormat formatter = DateFormat('yyyy-MM-dd');
            // final saledate = formatter.format(possalesresult[i]['SaleDate']);

            var counter = CounterSalesList(
              saledate: DateFormat("yyyy-MM-dd")
                  .parse(counteralesresult[i]['SaleDate'])
                  .toString()
                  .substring(0, 10),
              counterid: counteralesresult[i]['BillCounterId'],
              countername: counteralesresult[i]['Counter'],
              totalamount: counteralesresult[i]['Amount'],
              gstamount: counteralesresult[i]['GST'],
              netamount: counteralesresult[i]['TotalSales'],
            );

            countersalelist.add(counter);

            if (i == counteralesresult.length - 1) {
              var counterlisttotal = CounterSalesList(
                saledate: "",
                counterid: 0,
                countername: "Total",
                totalamount: (countersalelist.fold(
                    0, (sum, item) => sum + item.totalamount)),
                gstamount: (countersalelist.fold(
                    0, (sum, item) => sum + item.gstamount)),
                netamount: (countersalelist.fold(
                    0, (sum, item) => sum + item.netamount)),
              );
              countersalelist.add(counterlisttotal);
            }
          }

          return countersalelist;
        } else {
          messagebox.showMessage(
              "Invalid Data!${result["Data"].toString()}", context);
          return countersalelist;
        }
      } else {
        messagebox.showMessage(
            "Connection Error!!${response.statusCode}", context);
        return countersalelist;
      }
    } catch (ex) {
      messagebox.showMessage("Error getting records $ex", context);
      return countersalelist;
    }
  }

  Future<List<BillWiseSalesList>> getBillWiseSalesList(
      context, posid, counterid, fromdate, todate) async {
    List<BillWiseSalesList> billwisesalelist = <BillWiseSalesList>[];
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var apiURL = myApiBaseURL;
      var companyid = int.parse(prefs.getString("CompanyId").toString());
      //var posid = int.parse(prefs.getString("POSId").toString());
      var ref = prefs.getString("Ref");

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${prefs.getString("Token").toString()}',
      };

      var params = {
        "Ref": ref,
        "CompanyId": companyid,
        "PosId": posid,
        "pBillCounterId": counterid,
        "FromDate": fromdate,
        "ToDate": todate,
      };

      final response = await http
          .post(
            Uri.parse("$apiURL/GetDailySalesBillWiseByBillCounterId"),
            headers: headers,
            body: jsonEncode(params),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        var result = json.decode(response.body.toString());
        var status = result["Status"];
        if (status == "valid") {
          var billwisesalesresult = result["Data"];

          for (int i = 0; i < billwisesalesresult.length; i++) {
            // final DateFormat formatter = DateFormat('yyyy-MM-dd');
            // final saledate = formatter.format(possalesresult[i]['SaleDate']);

            var counter = BillWiseSalesList(
              billno: billwisesalesresult[i]['BillNo'],
              billdate: billwisesalesresult[i]['BillDate'].toString(),
              counterid: billwisesalesresult[i]['BillCounterId'],
              totalamount: billwisesalesresult[i]['Amount'],
              gstamount: billwisesalesresult[i]['GST'],
              netamount: billwisesalesresult[i]['TotalSales'],
              iscancelled: billwisesalesresult[i]['IsCancelled'],
            );

            billwisesalelist.add(counter);

            if (i == billwisesalesresult.length - 1) {
              var billwiselisttotal = BillWiseSalesList(
                billno: '',
                billdate: 'Total',
                counterid: 0,
                totalamount: (billwisesalelist
                    .where((element) => element.iscancelled == 0)
                    .fold(0, (sum, item) => sum + item.totalamount)),
                gstamount: (billwisesalelist
                    .where((element) => element.iscancelled == 0)
                    .fold(0, (sum, item) => sum + item.gstamount)),
                netamount: (billwisesalelist
                    .where((element) => element.iscancelled == 0)
                    .fold(0, (sum, item) => sum + item.netamount)),
                iscancelled: billwisesalesresult[i]['IsCancelled'],
              );
              billwisesalelist.add(billwiselisttotal);
            }
          }

          return billwisesalelist;
        } else {
          messagebox.showMessage(
              "Invalid Data!${result["Data"].toString()}", context);
          return billwisesalelist;
        }
      } else {
        messagebox.showMessage(
            "Connection Error!!${response.statusCode}", context);
        return billwisesalelist;
      }
    } catch (ex) {
      messagebox.showMessage("Error getting records $ex", context);
      return billwisesalelist;
    }
  }

  Future<List<ProductWiseSalesList>> getProductWiseSalesList(
      context, posid, counterid, fromdate, todate) async {
    List<ProductWiseSalesList> productwisesaleslist = <ProductWiseSalesList>[];
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var apiURL = myApiBaseURL;
      var companyid = int.parse(prefs.getString("CompanyId").toString());
      //var posid = int.parse(prefs.getString("POSId").toString());
      var ref = prefs.getString("Ref");

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${prefs.getString("Token").toString()}',
      };

      var params = {
        "Ref": ref,
        "CompanyId": companyid,
        "PosId": posid,
        "pBillCounterId": counterid,
        "FromDate": fromdate,
        "ToDate": todate,
      };

      final response = await http
          .post(
            Uri.parse("$apiURL/GetDailySalesProductWiseByBillCounterId"),
            headers: headers,
            body: jsonEncode(params),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        var result = json.decode(response.body.toString());
        var status = result["Status"];
        if (status == "valid") {
          var productwisesalelist = result["Data"];

          for (int i = 0; i < productwisesalelist.length; i++) {
            // final DateFormat formatter = DateFormat('yyyy-MM-dd');
            // final saledate = formatter.format(possalesresult[i]['SaleDate']);

            var counter = ProductWiseSalesList(
              itemname: productwisesalelist[i]['ItemName'],
              qty: productwisesalelist[i]['Qty'],
              totalamount: productwisesalelist[i]['Amount'],
              gstamount: productwisesalelist[i]['GST'],
              netamount: productwisesalelist[i]['TotalSales'],
            );

            productwisesaleslist.add(counter);

            if (i == productwisesalelist.length - 1) {
              var billwiselisttotal = ProductWiseSalesList(
                itemname: 'Total',
                qty: (productwisesaleslist.fold(
                    0, (sum, item) => sum + item.qty)),
                totalamount: (productwisesaleslist.fold(
                    0, (sum, item) => sum + item.totalamount)),
                gstamount: (productwisesaleslist.fold(
                    0, (sum, item) => sum + item.gstamount)),
                netamount: (productwisesaleslist.fold(
                    0, (sum, item) => sum + item.netamount)),
              );
              productwisesaleslist.add(billwiselisttotal);
            }
          }

          return productwisesaleslist;
        } else {
          messagebox.showMessage(
              "Invalid Data!${result["Data"].toString()}", context);
          return productwisesaleslist;
        }
      } else {
        messagebox.showMessage(
            "Connection Error!!${response.statusCode}", context);
        return productwisesaleslist;
      }
    } catch (ex) {
      messagebox.showMessage("Error getting records $ex", context);
      return productwisesaleslist;
    }
  }

  Future<List<MonthlySalesList>> getMonthlySalesList(
      context, posid, year) async {
    List<MonthlySalesList> monthlysaleslist = <MonthlySalesList>[];
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var apiURL = myApiBaseURL;

      //var posid = int.parse(prefs.getString("POSId").toString());
      var ref = prefs.getString("Ref");

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${prefs.getString("Token").toString()}',
      };

      var params = {
        "Ref": ref,
        "PosId": posid,
        "Year": year,
      };

      final response = await http
          .post(
            Uri.parse("$apiURL/GetMonthlySalesByPOSId"),
            headers: headers,
            body: jsonEncode(params),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        var result = json.decode(response.body.toString());
        var status = result["Status"];
        if (status == "valid") {
          var monthwisesalelist = result["Data"];

          for (int i = 0; i < monthwisesalelist.length; i++) {
            // final DateFormat formatter = DateFormat('yyyy-MM-dd');
            // final saledate = formatter.format(possalesresult[i]['SaleDate']);

            var counter = MonthlySalesList(
              month: monthwisesalelist[i]['Month'],
              totalamount: monthwisesalelist[i]['Amount'],
              gstamount: monthwisesalelist[i]['GST'],
              netamount: monthwisesalelist[i]['TotalSales'],
            );

            monthlysaleslist.add(counter);

            if (i == monthwisesalelist.length - 1) {
              var monthwiselisttotal = MonthlySalesList(
                month: 'Total',
                totalamount: (monthlysaleslist.fold(
                    0, (sum, item) => sum + item.totalamount)),
                gstamount: (monthlysaleslist.fold(
                    0, (sum, item) => sum + item.gstamount)),
                netamount: (monthlysaleslist.fold(
                    0, (sum, item) => sum + item.netamount)),
              );
              monthlysaleslist.add(monthwiselisttotal);
            }
          }

          return monthlysaleslist;
        } else {
          messagebox.showMessage(
              "Invalid Data!${result["Data"].toString()}", context);
          return monthlysaleslist;
        }
      } else {
        messagebox.showMessage(
            "Connection Error!!${response.statusCode}", context);
        return monthlysaleslist;
      }
    } catch (ex) {
      messagebox.showMessage("Error getting records $ex", context);
      return monthlysaleslist;
    }
  }
}
