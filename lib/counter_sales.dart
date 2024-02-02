//import 'package:aahhaaapp/common/messagebox.dart';

import 'dart:io';

import 'package:aahhaaapp/api/models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer';
import 'api/database.dart' as database;
import 'package:shared_preferences/shared_preferences.dart';
import 'product_bill_sales.dart';
import 'package:open_filex/open_filex.dart' as fx;
import 'package:pdf/widgets.dart' as pw;

final focusqty = FocusNode();

var dbHelper = database.DbHelper();

class CounterSales extends StatefulWidget {
  const CounterSales({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<CounterSales> createState() => _CounterSales();
}

class _CounterSales extends State<CounterSales> {
  DateTimeRange? _selectedDateRange =
      DateTimeRange(start: DateTime.now(), end: DateTime.now());
  int selectedCounterId = 0;
  CounterList? selectedCounter;
  List<CounterList> counterList = [];
  List<CounterSalesList> counterSalesList = [];
  int posid = 0;
  String posname = '';

  @override
  void initState() {
    super.initState();

    _loadCounterList().then((result) {
      setState(() {
        if (prefs.getString("CounterId") != null &&
            prefs.getString("CounterId") != "0") {
          selectedCounterId =
              int.parse(prefs.getString("CounterId").toString());
          selectedCounter = counterList
              .where((i) => (i.counterid == selectedCounterId))
              .first;
        }
      });
    });
  }

  late SharedPreferences prefs;

  _loadCounterList() async {
    prefs = await SharedPreferences.getInstance();

    await getCounterList();
    await getCounterSaleList();
  }

  getCounterList() async {
    var args = (ModalRoute.of(context)!.settings.arguments! as Map);
    counterList =
        await dbHelper.getCounterList(context, args['posid'], args['saledate']);

    _selectedDateRange = DateTimeRange(
        start: DateTime.parse(args['saledate'].toString()),
        end: DateTime.parse(args['saledate'].toString()));
  }

  getCounterSaleList() async {
    var args = (ModalRoute.of(context)!.settings.arguments! as Map);
    posid = args['posid'];
    posname = args['posname'];
    counterSalesList = await dbHelper.getCounterSalesList(
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
        getCounterSaleList();
      });
    }
  }

  void gotoProductBillPage(result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BillProductSales(
          title: 'Bill Or Product',
        ),
        // Pass the arguments as part of the RouteSettings. The
        // DetailScreen reads the arguments from these settings.
        settings: RouteSettings(arguments: {
          "saledate": result.saledate,
          "counterid": result.counterid,
          "countername": result.countername,
          "posid": posid,
          "posname": posname
        }),
      ),
    );
  }

  void _saveCounterSalesAsPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Column(children: [
            pw.Container(
                height: 25,
                child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text('Counter Wise Report'))),
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
                        "From: ${_selectedDateRange?.start.toString().split(' ')[0]} To:  ${_selectedDateRange?.end.toString().split(' ')[0]}")))
          ]),
          // ignore: deprecated_member_use
          pw.Table.fromTextArray(context: context, data: <List<String>>[
            <String>[
              'SaleDate',
              'CounterName',
              'TotalAmount',
              'GSTAmount',
              'NetAmount'
            ],
            for (int i = 0; i < counterSalesList.length; i++)
              <String>[
                counterSalesList[i].saledate,
                counterSalesList[i].countername,
                counterSalesList[i].totalamount.toStringAsFixed(2),
                counterSalesList[i].gstamount.toStringAsFixed(2),
                counterSalesList[i].netamount.toStringAsFixed(2)
              ],
          ]),
        ],
      ),
    );
    // Directory? documentDirectory = await getDownloadsDirectory();
    // String? documentPath = documentDirectory?.path;

    // // Directory documentPath = Directory('/storage/emulated/0/Download');

    // File pdfFile = File('$documentPath/counter.pdf');
    // pdfFile.writeAsBytesSync(await pdf.save());
    // fx.OpenFilex.open('$documentPath/counter.pdf');
      final dir = await getTemporaryDirectory();
    final pdfFile = File("${dir.path}//counter.pdf");

    pdfFile.writeAsBytesSync(await pdf.save());
    fx.OpenFilex.open("${dir.path}/counter.pdf");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0), // here the desired height
          child: AppBar(
            backgroundColor: Theme.of(context).primaryColorDark,
            title: const Text(
              "Counter Sales",
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
                          icon:  Icon(Icons.picture_as_pdf,color: Theme.of(context).primaryColorDark),
                          highlightColor: Colors.pink,
                          onPressed: () {
                            _saveCounterSalesAsPDF();
                          },
                        ),
                      )
                    ],
                  ),
                ),
                  Row(
            children: [
               const SizedBox(width: 50,),
              Expanded(
                flex: 50,
                  child: ButtonTheme(
                minWidth: 200.0,
                height: 100.0,
                child: ElevatedButton(
                  onPressed: () {
                        _selectedDateRange =
                          DateTimeRange(start: DateTime.now().subtract(const Duration(days:1)), end: DateTime.now().subtract(const Duration(days:1)));
                          prefs.setString("CounterFromDate", _selectedDateRange!.start.toString());
                          prefs.setString("CounterToDate", _selectedDateRange!.end.toString());
                         getCounterSaleList();
                         
                  },
                  child: const Text("Yesterday"),
                ),
              )),
              const SizedBox(width: 50,),
               Expanded(
                
                flex: 50,
                  child: ButtonTheme(
                minWidth: 200.0,
                height: 100.0,
                child: ElevatedButton(
                  onPressed: () {
                        _selectedDateRange =
                          DateTimeRange(start: DateTime.now(), end: DateTime.now());
                          prefs.setString("CounterFromDate", _selectedDateRange!.start.toString());
                          prefs.setString("CounterToDate", _selectedDateRange!.end.toString());
                         getCounterSaleList();
                  },
                  child: const Text("Today"),
                ),
              )
              ),
               const SizedBox(width: 50,),
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
                getCounterSaleList();
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

          SingleChildScrollView(
            //  child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              columns: const <DataColumn>[
                DataColumn(
                  label: Text('SaleDate'),
                ),
                DataColumn(
                  label: Text('POSName'),
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
              rows: List.generate(counterSalesList.length, (index) {
                final item = counterSalesList[index];

                return DataRow(
                  cells: [
                    DataCell(
                     Text(item.saledate==""? "":
                      DateFormat('dd/MM/yyyy').format(DateTime.parse(item.saledate)),
                          style:  TextStyle(color: Theme.of(context).primaryColorDark)),
                      onTap: () {
                        gotoProductBillPage(item);
                      },
                    ),
                    DataCell(Text(item.countername,
                        style: TextStyle(
                            fontWeight: item.countername != "Total"
                                ? FontWeight.normal
                                : FontWeight.bold))),
                    DataCell(Text(item.totalamount.toStringAsFixed(2),
                        style: TextStyle(
                            fontWeight: item.countername != "Total"
                                ? FontWeight.normal
                                : FontWeight.bold))),
                    DataCell(Text((item.gstamount).toStringAsFixed(2),
                        style: TextStyle(
                            fontWeight: item.countername != "Total"
                                ? FontWeight.normal
                                : FontWeight.bold))),
                    DataCell(Text((item.netamount).toStringAsFixed(2),
                        style: TextStyle(
                            fontWeight: item.countername != "Total"
                                ? FontWeight.normal
                                : FontWeight.bold))),
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
