//import 'package:aahhaaapp/common/messagebox.dart';

import 'dart:io';

import 'package:aahhaaapp/api/models.dart';
import 'package:aahhaaapp/counter_sales.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:developer';
import 'api/database.dart' as database;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart' as fx;

final focusqty = FocusNode();

var dbHelper = database.DbHelper();

class POS extends StatefulWidget {
  const POS({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<POS> createState() => _POSState();
}

class _POSState extends State<POS> {
  DateTimeRange? _selectedDateRange =
      DateTimeRange(start: DateTime.now(), end: DateTime.now());
  int selectedPOSId = 0;
  POSList? selectedPOS;
  List<POSList> posList = [];
  List<POSSalesList> posSalesList = [];
  bool _sortNameAsc = true;

  bool _sortAsc = true;
  int _sortColumnIndex = 0;

  @override
  void initState() {
    super.initState();

    _loadPOSList().then((result) {
      setState(() {
        if (prefs.getString("POSId") != null &&
            prefs.getString("POSId") != "0") {
          selectedPOSId = int.parse(prefs.getString("POSId").toString());
          selectedPOS = posList.where((i) => (i.posid == selectedPOSId)).first;
        }
      });
    });
  }

  late SharedPreferences prefs;

  _loadPOSList() async {
    prefs = await SharedPreferences.getInstance();

    if (prefs.getString("POSFromDate") != null) {
      _selectedDateRange = DateTimeRange(
          start: DateTime.parse(prefs.getString("POSFromDate").toString()),
          end: DateTime.parse(prefs.getString("POSToDate").toString()));
    }

    await getPOSList();
    await getPOSSaleList();
  }

  getPOSList() async {
    posList = await dbHelper.getPOSList(context);
  }

  getPOSSaleList() async {
    posSalesList = await dbHelper.getPOSSalesList(
        context,
        _selectedDateRange?.start.toString().split(' ')[0],
        _selectedDateRange?.end.toString().split(' ')[0]);
    setState(() {});
  }

  void _savePOSSalesAsPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Column(children: [
            pw.Container(
                height: 25,
                child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text('POS Report'))),
            pw.Container(
                height: 25,
                child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                        "From: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(_selectedDateRange!.start.toString().split(' ')[0]))} To:  ${DateFormat('dd/MM/yyyy').format(DateTime.parse(_selectedDateRange!.end.toString().split(' ')[0]))}")))
          ]),
          // ignore: deprecated_member_use
          pw.Table.fromTextArray(context: context, data: <List<String>>[
            <String>[
              'SaleDate',
              'PosName',
              'TotalAmount',
              'GSTAmount',
              'NetAmount',
              'Cash',
              'Card',
              'Online'
            ],
            for (int i = 0; i < posSalesList.length; i++)
              <String>[
                posSalesList[i].saledate == ""
                    ? ""
                    : DateFormat('dd/MM/yyyy')
                        .format(DateTime.parse(posSalesList[i].saledate)),
                (posSalesList[i].posname),
                (posSalesList[i].totalamount.toStringAsFixed(2)),
                posSalesList[i].gstamount.toStringAsFixed(2),
                posSalesList[i].netamount.toStringAsFixed(2),
                posSalesList[i].cash.toStringAsFixed(2),
                posSalesList[i].card.toStringAsFixed(2),
                posSalesList[i].online.toStringAsFixed(2),
              ],

            // posSalesList
            //     .map((sale) => [
            //           sale.saledate,
            //           sale.posname,
            //           sale.gstamount,
            //           sale.netamount
            //         ])
            //     .toList()
          ]),
        ],
      ),
    );
    // Directory? documentDirectory = await getDownloadsDirectory();
    // String? documentPath = documentDirectory?.path;

    // Directory documentPath = Directory('/storage/emulated/0/Download');

    // File pdfFile = File('$documentPath/pos.pdf');
    // pdfFile.writeAsBytesSync(await pdf.save());
    // fx.OpenFilex.open('$documentPath/pos.pdf');

    final dir = await getTemporaryDirectory();
    final pdfFile = File("${dir.path}//pos.pdf");

    pdfFile.writeAsBytesSync(await pdf.save());
    fx.OpenFilex.open("${dir.path}/pos.pdf");
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
        prefs.setString("POSFromDate", _selectedDateRange!.start.toString());
        prefs.setString("POSToDate", _selectedDateRange!.end.toString());
        getPOSSaleList();
      });
    }
  }

  void gotoCounterPage(result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CounterSales(
          title: 'Counter',
        ),
        // Pass the arguments as part of the RouteSettings. The
        // DetailScreen reads the arguments from these settings.
        settings: RouteSettings(arguments: {
          "saledate": result.saledate,
          "posid": result.posid,
          "posname": result.posname,
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0), // here the desired height
          child: AppBar(
            backgroundColor: Theme.of(context).primaryColorDark,
            title: const Text(
              "POS Sales",
              style: TextStyle(fontSize: 15, color: Colors.white),
            ),
          )),
      body: ListView(children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(1),
          child: Row(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start date
              Expanded(
                flex: 22,
                child: Text(
                  "From: ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)}",
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),

              Expanded(
                flex: 20,
                child: Text(
                    "To: ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}",
                    style: const TextStyle(fontSize: 18, color: Colors.black)),
              ),
              // End date
              Expanded(
                flex: 5,
                child: IconButton(
                  icon: Icon(Icons.picture_as_pdf,
                      color: Theme.of(context).primaryColorDark),
                  highlightColor: Colors.pink,
                  onPressed: () {
                    _savePOSSalesAsPDF();
                  },
                ),
              ),
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
                          start:
                              DateTime.now().subtract(const Duration(days: 1)),
                          end:
                              DateTime.now().subtract(const Duration(days: 1)));
                      prefs.setString(
                          "POSFromDate", _selectedDateRange!.start.toString());
                      prefs.setString(
                          "POSToDate", _selectedDateRange!.end.toString());
                      getPOSSaleList();
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
                      prefs.setString(
                          "POSFromDate", _selectedDateRange!.start.toString());
                      prefs.setString(
                          "POSToDate", _selectedDateRange!.end.toString());
                      getPOSSaleList();
                    },
                    child: const Text("Today"),
                  ),
                )),
            const SizedBox(
              width: 50,
            ),
          ],
        ),
        DropdownButton<POSList>(
          isExpanded: true,
          hint: const Text("Select a POS"),
          value: selectedPOS,
          onChanged: (selectedvalue) {
            setState(() {
              selectedPOS = selectedvalue!;
              selectedPOSId = selectedvalue.posid;
              prefs.setString("POSId", selectedvalue.posid.toString());
              getPOSSaleList();
            });
          },
          items: posList.map((POSList pos) {
            return DropdownMenuItem<POSList>(
              value: pos,
              child: Text(
                pos.posname,
                overflow: TextOverflow.clip,
                style: const TextStyle(color: Colors.black),
              ),
            );
          }).toList(),
        ),

        SingleChildScrollView(
          //  child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            columns: <DataColumn>[
              DataColumn(
                  label: const Text('SaleDate'),
                  onSort: (columnIndex, sortAscending) {
                    setState(() {
                      if (columnIndex == _sortColumnIndex) {
                        _sortAsc = _sortNameAsc = sortAscending;
                      } else {
                        _sortColumnIndex = columnIndex;
                        _sortAsc = _sortNameAsc;
                      }
                      posSalesList
                          .sort((a, b) => a.posname.compareTo(b.posname));
                      if (!_sortAsc) {
                        posSalesList = posSalesList.reversed.toList();
                      }
                    });
                  }),
              const DataColumn(
                label: Text('POSName'),
                //  numeric: true,
              ),
              const DataColumn(
                label: Text('Amount'),
                numeric: true,
              ),
              const DataColumn(
                label: Text('GST'),
                numeric: true,
              ),
              const DataColumn(
                label: Text('TotalSales'),
                numeric: true,
              ),
              const DataColumn(
                label: Text('Cash'),
                numeric: true,
              ),
              const DataColumn(
                label: Text('Card'),
                numeric: true,
              ),
              const DataColumn(
                label: Text('Online'),
                numeric: true,
              ),
            ],
            rows: List.generate(posSalesList.length, (index) {
              final item = posSalesList[index];

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                        item.saledate == ""
                            ? ""
                            : DateFormat('dd/MM/yyyy')
                                .format(DateTime.parse(item.saledate)),
                        style: TextStyle(
                            color: Theme.of(context).primaryColorDark)),
                    onTap: () {
                      gotoCounterPage(item);
                    },
                  ),
                  DataCell(Text(item.posname,
                      style: TextStyle(
                          fontWeight: item.posname != "Total"
                              ? FontWeight.normal
                              : FontWeight.bold))),
                  DataCell(Text(item.totalamount.toStringAsFixed(2),
                      style: TextStyle(
                          fontWeight: item.posname != "Total"
                              ? FontWeight.normal
                              : FontWeight.bold))),
                  DataCell(Text((item.gstamount).toStringAsFixed(2),
                      style: TextStyle(
                          fontWeight: item.posname != "Total"
                              ? FontWeight.normal
                              : FontWeight.bold))),
                  DataCell(Text((item.netamount).toStringAsFixed(2),
                      style: TextStyle(
                          fontWeight: item.posname != "Total"
                              ? FontWeight.normal
                              : FontWeight.bold))),
                  DataCell(Text((item.cash).toStringAsFixed(2),
                      style: TextStyle(
                          fontWeight: item.posname != "Total"
                              ? FontWeight.normal
                              : FontWeight.bold))),
                  DataCell(Text((item.card).toStringAsFixed(2),
                      style: TextStyle(
                          fontWeight: item.posname != "Total"
                              ? FontWeight.normal
                              : FontWeight.bold))),
                  DataCell(Text((item.online).toStringAsFixed(2),
                      style: TextStyle(
                          fontWeight: item.posname != "Total"
                              ? FontWeight.normal
                              : FontWeight.bold))),
                ],
              );
            }),
          ),
        )
        //
      ]

          // This button is used to show the date range picker

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
