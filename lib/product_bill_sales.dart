//import 'package:aahhaaapp/common/messagebox.dart';

import 'dart:io';

import 'package:aahhaaapp/api/models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer';
import 'api/database.dart' as database;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart' as fx;

final focusqty = FocusNode();

var dbHelper = database.DbHelper();

class BillProductSales extends StatefulWidget {
  const BillProductSales({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<BillProductSales> createState() => _BillProductSales();
}

class _BillProductSales extends State<BillProductSales> {
  DateTimeRange? _selectedDateRange =
      DateTimeRange(start: DateTime.now(), end: DateTime.now());
  int selectedCounterId = 0;
  CounterList? selectedCounter;
  List<CounterList> counterList = [];
  List<BillWiseSalesList> billWiseSalesList = [];
  List<ProductWiseSalesList> productWiseSalesList = [];
  int _radioSelected = 1;
  String posname = "";
  // bool _sortNameAsc = true;

  // bool _sortAsc = true;
  // int _sortColumnIndex = 0;

  @override
  void initState() {
    super.initState();

    _loadCounterList().then((result) {
      setState(() {});
    });
  }

  late SharedPreferences prefs;

  _loadCounterList() async {
    prefs = await SharedPreferences.getInstance();

    await getCounterList();
    await loadBillOrProductGrid();
  }

  getCounterList() async {
    var args = (ModalRoute.of(context)!.settings.arguments! as Map);
    counterList =
        await dbHelper.getCounterList(context, args['posid'], args['saledate']);

    selectedCounterId = int.parse(args['counterid'].toString());
    selectedCounter =
        counterList.where((i) => (i.counterid == selectedCounterId)).first;

    _selectedDateRange = DateTimeRange(
        start: DateTime.parse(args['saledate'].toString()),
        end: DateTime.parse(args['saledate'].toString()));
  }

  loadBillOrProductGrid() async {
    if (_radioSelected == 1) {
      await getProductWiseSaleList();
    } else {
      await getBillWiseSaleList();
    }
  }

  getBillWiseSaleList() async {
    var args = (ModalRoute.of(context)!.settings.arguments! as Map);

    billWiseSalesList = await dbHelper.getBillWiseSalesList(
        context,
        args['posid'],
        selectedCounterId,
        _selectedDateRange?.start.toString().split(' ')[0],
        _selectedDateRange?.end.toString().split(' ')[0]);
    setState(() {});
  }

  getProductWiseSaleList() async {
    var args = (ModalRoute.of(context)!.settings.arguments! as Map);
    posname = args['posname'];
    productWiseSalesList = await dbHelper.getProductWiseSalesList(
        context,
        args['posid'],
        selectedCounterId,
        _selectedDateRange?.start.toString().split(' ')[0],
        _selectedDateRange?.end.toString().split(' ')[0]);
    setState(() {});
  }

  // This function will be triggered when the floating button is pressed
  void _showCalendar() async {
    final DateTimeRange? result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      currentDate: DateTime.now(),
      initialDateRange:
          DateTimeRange(start: DateTime.now(), end: DateTime.now()),
      saveText: 'Done',
    );

    if (result != null) {
      // Rebuild the UI
      //print(result.start.toString());
      log('data: $result');
      setState(() {
        _selectedDateRange = result;
        prefs.setString(
            "CounterFromDate", _selectedDateRange!.start.toString());
        prefs.setString("CounterToDate", _selectedDateRange!.end.toString());
        loadBillOrProductGrid();
      });
    }
  }

  void _saveProductWiseSalesAsPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Column(children: [
            pw.Container(
                height: 25,
                child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text('Product Wise Report'))),
            pw.Container(
                height: 25,
                child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text("POS:'$posname"))),
            pw.Container(
                height: 25,
                child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                        "Counter:${selectedCounterId == 0 ? "All Counter" : selectedCounter?.countername}"))),
            pw.Container(
                height: 25,
                child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                        "From: ${_selectedDateRange?.start.toString().split(' ')[0]} To:  ${_selectedDateRange?.end.toString().split(' ')[0]}")))
          ]),
          // ignore: deprecated_member_use
          pw.Table.fromTextArray(context: context, data: <List<String>>[
            <String>[
              'ItemName',
              'Qty',
              'TotalAmount',
              'GSTAmount',
              'NetAmount'
            ],
            for (int i = 0; i < productWiseSalesList.length; i++)
              <String>[
                productWiseSalesList[i].itemname,
                productWiseSalesList[i].qty.toString(),
                productWiseSalesList[i].totalamount.toStringAsFixed(2),
                productWiseSalesList[i].gstamount.toStringAsFixed(2),
                productWiseSalesList[i].netamount.toStringAsFixed(2)
              ],
          ]),
        ],
      ),
    );
    // Directory? documentDirectory = await getDownloadsDirectory();
    // String? documentPath = documentDirectory?.path;

    // // Directory documentPath = Directory('/storage/emulated/0/Download');

    // File pdfFile = File('$documentPath/product.pdf');
    // pdfFile.writeAsBytesSync(await pdf.save());
    // fx.OpenFilex.open('$documentPath/product.pdf');

     final dir = await getTemporaryDirectory();
    final pdfFile = File("${dir.path}//product.pdf");

    pdfFile.writeAsBytesSync(await pdf.save());
    fx.OpenFilex.open("${dir.path}/product.pdf");
  }

  void _saveBillWiseSalesAsPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Column(children: [
            pw.Container(
                height: 25,
                child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text('Bill Wise Report'))),
            pw.Container(
                height: 25,
                child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text("POS:'$posname"))),
            pw.Container(
                height: 25,
                child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                        "Counter:${selectedCounterId == 0 ? "All Counter" : selectedCounter?.countername}"))),
            pw.Container(
                height: 25,
                child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                        "From: ${_selectedDateRange?.start.toString().split(' ')[0]} To:  ${_selectedDateRange?.end.toString().split(' ')[0]}")))
          ]),
          // ignore: deprecated_member_use
          pw.Table.fromTextArray(context: context, data: <List<String>>[
            <String>[
              'BillNo',
              'BillDate',
              'TotalAmount',
              'GSTAmount',
              'NetAmount'
            ],
            for (int i = 0; i < billWiseSalesList.length; i++)
              <String>[
                billWiseSalesList[i].billno,
                billWiseSalesList[i].billdate,
                billWiseSalesList[i].totalamount.toStringAsFixed(2),
                billWiseSalesList[i].gstamount.toStringAsFixed(2),
                billWiseSalesList[i].netamount.toStringAsFixed(2)
              ],
          ]),
        ],
      ),
    );
    // Directory? documentDirectory = await getDownloadsDirectory();
    // String? documentPath = documentDirectory?.path;

    // // Directory documentPath = Directory('/storage/emulated/0/Download');

    // File pdfFile = File('$documentPath/bill.pdf');
    // pdfFile.writeAsBytesSync(await pdf.save());
    // fx.OpenFilex.open('$documentPath/bill.pdf');
      final dir = await getTemporaryDirectory();
    final pdfFile = File("${dir.path}//bill.pdf");

    pdfFile.writeAsBytesSync(await pdf.save());
    fx.OpenFilex.open("${dir.path}/bill.pdf");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0), // here the desired height
          child: AppBar(
            backgroundColor: Theme.of(context).primaryColorDark,
            title: const Text(
              "Bill/Product Sales",
              style: TextStyle(fontSize: 15, color: Colors.white),
            ),
          )),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(children: <Widget>[
          _selectedDateRange == null
              ? const Center(
                  child: Text('Press the button to show the picker'),
                )
              : Padding(
                  padding: const EdgeInsets.all(1),
                  child: Row(
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Start date
                      Expanded(
                        flex: 22,
                        child: Text(
                          "From: ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)}",
                          style: const TextStyle(
                              fontSize: 18, color: Colors.black),
                        ),
                      ),

                      Expanded(
                        flex: 20,
                        child: Text(
                            "To: ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}",
                            style: const TextStyle(
                                fontSize: 18, color: Colors.black)),
                      ),
                      // End date
                      Expanded(
                        flex: 5,
                        child: IconButton(
                          icon: Icon(Icons.picture_as_pdf,
                              color: Theme.of(context).primaryColorDark),
                          highlightColor: Colors.pink,
                          onPressed: () {
                            if (_radioSelected == 1) {
                              _saveProductWiseSalesAsPDF();
                            } else {
                              _saveBillWiseSalesAsPDF();
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ),
          Row(
            children: [
              const SizedBox(
                width: 50,
              ),
              Expanded(
                  flex: 50,
                  child: ButtonTheme(
                    minWidth: 200.0,
                    height: 100.0,
                    child: ElevatedButton(
                      onPressed: () {
                        _selectedDateRange = DateTimeRange(
                            start: DateTime.now()
                                .subtract(const Duration(days: 1)),
                            end: DateTime.now()
                                .subtract(const Duration(days: 1)));

                        if (_radioSelected == 1) {
                          getProductWiseSaleList();
                        } else {
                          getBillWiseSaleList();
                        }
                      },
                      child: const Text("Yesterday"),
                    ),
                  )),
              const SizedBox(
                width: 50,
              ),
              Expanded(
                  flex: 50,
                  child: ButtonTheme(
                    minWidth: 200.0,
                    height: 100.0,
                    child: ElevatedButton(
                      onPressed: () {
                        _selectedDateRange = DateTimeRange(
                            start: DateTime.now(), end: DateTime.now());

                        if (_radioSelected == 1) {
                          getProductWiseSaleList();
                        } else {
                          getBillWiseSaleList();
                        }
                      },
                      child: const Text("Today"),
                    ),
                  )),
              const SizedBox(
                width: 50,
              ),
            ],
          ),
          DropdownButton<CounterList>(
            isExpanded: true,
            hint: const Text("Select a Counter"),
            value: selectedCounter,
            onChanged: (selectedvalue) {
              setState(() {
                selectedCounter = selectedvalue!;
                selectedCounterId = selectedvalue.counterid;
                prefs.setString(
                    "CounterId", selectedvalue.counterid.toString());
                loadBillOrProductGrid();
              });
            },
            items: counterList.map((CounterList counter) {
              return DropdownMenuItem<CounterList>(
                value: counter,
                child: Text(
                  counter.countername,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(color: Colors.black),
                ),
              );
            }).toList(),
          ),

          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Radio(
                            value: 1,
                            groupValue: _radioSelected,
                            onChanged: (value) {
                              setState(() {
                                _radioSelected = value!;
                                loadBillOrProductGrid();
                              });
                            }),
                        const Expanded(
                          child: Text('Product Wise'),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Radio(
                            value: 2,
                            groupValue: _radioSelected,
                            onChanged: (value) {
                              setState(() {
                                _radioSelected = value!;
                                loadBillOrProductGrid();
                              });
                            }),
                        const Expanded(child: Text('Bill Wise'))
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          _radioSelected == 1
              ? SingleChildScrollView(
                  //  child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    // headingRowColor: MaterialStateColor.resolveWith((states) {return  Colors.blue;},),
                    // headingTextStyle:const TextStyle(color: Colors.white),
                    columnSpacing: 20,
                    columns: const <DataColumn>[
                      DataColumn(
                          label:  Text('ItemName'),
                          // onSort: (columnIndex, sortAscending) {
                          //   setState(() {
                          //     if (columnIndex == _sortColumnIndex) {
                          //       _sortAsc = _sortNameAsc = sortAscending;
                          //     } else {
                          //       _sortColumnIndex = columnIndex;
                          //       _sortAsc = _sortNameAsc;
                          //     }
                          //     productWiseSalesList.sort(
                          //         (a, b) => a.itemname.compareTo(b.itemname));
                          //     if (!_sortAsc) {
                          //       productWiseSalesList =
                          //           productWiseSalesList.reversed.toList();
                          //     }
                          //   });
                          ),
                       DataColumn(
                        label: Text('Qty'),
                        //  numeric: true,
                      ),
                       DataColumn(
                        label: Text('Amount'),
                        numeric: true,
                      ),
                       DataColumn(
                        label: Text('GST'),
                        numeric: true,
                      ),
                       DataColumn(
                        label: Text('TotalSales'),
                        numeric: true,
                      ),
                    ],
                    rows: List.generate(productWiseSalesList.length, (index) {
                      final item = productWiseSalesList[index];

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              item.itemname.toString(),
                              // style: const TextStyle(color: Colors.blue)
                            ),
                            // onTap: () {

                            //    gotoItemScanPage(result);
                            // },
                          ),
                          DataCell(Text(item.qty.toStringAsFixed(2),
                              style: TextStyle(
                                  fontWeight: item.itemname != "Total"
                                      ? FontWeight.normal
                                      : FontWeight.bold))),
                          DataCell(Text(item.totalamount.toStringAsFixed(2),
                              style: TextStyle(
                                  fontWeight: item.itemname != "Total"
                                      ? FontWeight.normal
                                      : FontWeight.bold))),
                          DataCell(Text((item.gstamount).toStringAsFixed(2),
                              style: TextStyle(
                                  fontWeight: item.itemname != "Total"
                                      ? FontWeight.normal
                                      : FontWeight.bold))),
                          DataCell(Text((item.netamount).toStringAsFixed(2),
                              style: TextStyle(
                                  fontWeight: item.itemname != "Total"
                                      ? FontWeight.normal
                                      : FontWeight.bold))),
                        ],
                      );
                    }),
                  ),
                )
              : SingleChildScrollView(
                  //  child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const <DataColumn>[
                      DataColumn(
                        label: Text('BillNo'),
                      ),
                      DataColumn(
                        label: Text('BillDate'),
                        //  numeric: true,
                      ),
                      DataColumn(
                        label: Text('Amount'),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text('GST'),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text('TotalSales'),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text('Status'),
                        numeric: true,
                      ),
                    ],
                    rows: List.generate(billWiseSalesList.length, (index) {
                      final item = billWiseSalesList[index];

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              item.billno.toString(),
                              // style: const TextStyle(color: Colors.blue)
                            ),
                            // onTap: () {

                            //    gotoItemScanPage(result);
                            // },
                          ),
                          DataCell(Text(
                              item.billdate == "Total"
                                  ? "Total"
                                  : DateFormat('dd/MM/yyyy HH:mm')
                                      .format(DateTime.parse(item.billdate)),
                              style: TextStyle(
                                  fontWeight: item.billdate != "Total"
                                      ? FontWeight.normal
                                      : FontWeight.bold))),
                          DataCell(Text(item.totalamount.toStringAsFixed(2),
                              style: TextStyle(
                                  fontWeight: item.billdate != "Total"
                                      ? FontWeight.normal
                                      : FontWeight.bold))),
                          DataCell(Text((item.gstamount).toStringAsFixed(2),
                              style: TextStyle(
                                  fontWeight: item.billdate != "Total"
                                      ? FontWeight.normal
                                      : FontWeight.bold))),
                          DataCell(Text((item.netamount).toStringAsFixed(2),
                              style: TextStyle(
                                  fontWeight: item.billdate != "Total"
                                      ? FontWeight.normal
                                      : FontWeight.bold))),
                          item.iscancelled == 0
                              ? const DataCell(Text(("")))
                              : DataCell(IconButton(
                                  icon: const Icon(Icons.cancel),
                                  onPressed: () {},
                                )),
                        ],
                      );
                    }),
                  ),
                )
          //

          // ),
        ]

            // This button is used to show the date range picker

            ),
      ),
      floatingActionButton: Draggable(
        feedback: FloatingActionButton(
          onPressed: _showCalendar,
          child: const Icon(Icons.date_range),
        ),
        child: FloatingActionButton(
          onPressed: _showCalendar,
          child: const Icon(Icons.date_range),
        ),
      ),
    );
  }
}
