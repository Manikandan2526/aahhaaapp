//import 'package:aahhaaapp/common/messagebox.dart';

import 'dart:io';

import 'package:aahhaaapp/api/models.dart';
import 'package:aahhaaapp/counter_sales.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
// import 'dart:developer';
import 'api/database.dart' as database;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart' as fx;

final focusqty = FocusNode();

var dbHelper = database.DbHelper();

class MonthlySales extends StatefulWidget {
  const MonthlySales({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MonthlySales> createState() => _MonthlySalesState();
}

class _MonthlySalesState extends State<MonthlySales> {
  // DateTimeRange? _selectedDateRange =
  //     DateTimeRange(start: DateTime.now(), end: DateTime.now());
  DateTime _selectedDate = DateTime.now();
  int selectedPOSId = 0;
  POSList? selectedPOS;
  List<POSList> posList = [];
  List<MonthlySalesList> monthlySalesList = [];

  @override
  void initState() {
    super.initState();

    _loadPOSList().then((result) {
      setState(() {});
    });
  }

  late SharedPreferences prefs;

  _loadPOSList() async {
    prefs = await SharedPreferences.getInstance();

    await getPOSList();
    await getMonthlySaleList();
  }

  getPOSList() async {
    posList = await dbHelper.getPOSList(context);
    posList.removeAt(0);
  }

  getMonthlySaleList() async {
    monthlySalesList = await dbHelper.getMonthlySalesList(
        context, selectedPOSId, _selectedDate.year);
    setState(() {});
  }

  // This function will be triggered when the floating button is pressed
  void _showCalendar() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Year"),
          content: SizedBox(
            // Need to use container to add size constraint.
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(DateTime.now().year - 100, 1),
              lastDate: DateTime(DateTime.now().year + 100, 1),
              // ignore: deprecated_member_use
              initialDate: DateTime.now(),
              // save the selected date to _selectedDate DateTime variable.
              // It's used to set the previous selected date when
              // re-showing the dialog.
              selectedDate: _selectedDate,
              onChanged: (DateTime dateTime) {
                _selectedDate = dateTime;
                // close the dialog when year is selected.
                Navigator.pop(context);
                setState(() {
                  getMonthlySaleList();
                });
                // Do something with the dateTime selected.
                // Remember that you need to use dateTime.year to get the year
              },
            ),
          ),
        );
      },
    );
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

  void _saveMonthWiseSalesAsPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Column(children: [
            pw.Container(
              
                height: 25,
                child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text('Monthly SalesReport'))),
            pw.Container(
                height: 25,
                child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                        "POS:${selectedPOSId == 0 ? "All Counter" : selectedPOS?.posname}"))),
            pw.Container(
                height: 25,
                child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text("Year: ${_selectedDate.year.toString()}")))
          ]),
          // ignore: deprecated_member_use
          pw.Table.fromTextArray(context: context, data: <List<String>>[
            <String>['Month', 'TotalAmount', 'GSTAmount', 'NetAmount'],
            for (int i = 0; i < monthlySalesList.length; i++)
              <String>[
                monthlySalesList[i].month,
                monthlySalesList[i].totalamount.toStringAsFixed(2),
                monthlySalesList[i].gstamount.toStringAsFixed(2),
                monthlySalesList[i].netamount.toStringAsFixed(2)
              ],
          ]),
        ],
      ),
    );
    // Directory? documentDirectory = await getDownloadsDirectory();
    // String? documentPath = documentDirectory?.path;

    // Directory documentPath = Directory('/storage/emulated/0/Download');
    final dir = await getTemporaryDirectory();
    final pdfFile = File("${dir.path}//sales.pdf");

    pdfFile.writeAsBytesSync(await pdf.save());
    fx.OpenFilex.open("${dir.path}/sales.pdf");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0), // here the desired height
          child: AppBar(
            backgroundColor: Theme.of(context).primaryColorDark,
            title: const Text(
              "Monthly Sales",
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
                flex: 50,
                child: Text(
                  "Selected Year: ${_selectedDate.year}",
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),

              Expanded(
                 flex: 50,
                child: IconButton(
                  icon:  Icon(Icons.picture_as_pdf,color: Theme.of(context).primaryColorDark),
                  highlightColor: Colors.pink,
                  onPressed: () {
                    _saveMonthWiseSalesAsPDF();
                  },
                ),
              )
            ],
          ),
        ),
        DropdownButton<POSList>(
          isExpanded: true,
          hint: const Text("Select a POS"),
          value: selectedPOS,
          onChanged: (selectedvalue) {
            setState(() {
              selectedPOS = selectedvalue!;
              selectedPOSId = selectedvalue.posid;
              // prefs.setString("POSId", selectedvalue.posid.toString());
              getMonthlySaleList();
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
            columns: const <DataColumn>[
              DataColumn(
                label: Text('Month'),
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
            rows: List.generate(monthlySalesList.length, (index) {
              final item = monthlySalesList[index];

              return DataRow(
                cells: [
                  DataCell(
                    Text(item.month.toString(),
                        style: TextStyle(
                            fontWeight: item.month != "Total"
                                ? FontWeight.normal
                                : FontWeight.bold)),
                  ),
                  // onTap: () {

                  //    gotoCounterPage(item);
                  // },

                  DataCell(Text(item.totalamount.toStringAsFixed(2),
                      style: TextStyle(
                          fontWeight: item.month != "Total"
                              ? FontWeight.normal
                              : FontWeight.bold))),
                  DataCell(Text((item.gstamount).toStringAsFixed(2),
                      style: TextStyle(
                          fontWeight: item.month != "Total"
                              ? FontWeight.normal
                              : FontWeight.bold))),
                  DataCell(Text((item.netamount).toStringAsFixed(2),
                      style: TextStyle(
                          fontWeight: item.month != "Total"
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
