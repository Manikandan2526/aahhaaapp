class Company {
  int companyid;
  String companyname;

  Company({
    required this.companyid,
    required this.companyname,
  });

  Map<String, dynamic> toMap() {
    return {
      'companyid': companyid,
      'companyname': companyname,
    };
  }
}

class POSList {
  int posid;
  String posname;

  POSList({
    required this.posid,
    required this.posname,
  });

  Map<String, dynamic> toMap() {
    return {
      'posid': posid,
      'posname': posname,
    };
  }
}


class CounterList {
  int counterid;
  String countername;

  CounterList({
    required this.counterid,
    required this.countername,
  });

  Map<String, dynamic> toMap() {
    return {
      'counterid': counterid,
      'countername': countername,
    };
  }
}

class POSSalesList {
  String saledate;
  String posname;
  int posid;
  num totalamount;
  num gstamount;
  num netamount;
  num cash;
  num card;
  num online;

  POSSalesList({
    required this.saledate,
    required this.posname,
    required this.posid,
    required this.totalamount,
    required this.gstamount,
    required this.netamount,
    required this.cash,
    required this.card,
    required this.online
  });

  Map<String, dynamic> toMap() {
    return {
      'saledate': saledate,
      'posname': posname,
      'totalamount': totalamount,
      'gstamount': gstamount,
      'netamount': netamount,
      'cash':cash,
      'card':card,
      'online':online
    };
  }
}


class CounterSalesList {
  String saledate;
  String countername;
  int counterid;
  num totalamount;
  num gstamount;
  num netamount;

  CounterSalesList({
    required this.saledate,
    required this.countername,
    required this.counterid,
    required this.totalamount,
    required this.gstamount,
    required this.netamount,
  });

  Map<String, dynamic> toMap() {
    return {
      'saledate': saledate,
      'posname': countername,
      'totalamount': totalamount,
      'gstamount': gstamount,
      'netamount': netamount,
    };
  }
}


class BillWiseSalesList {
  String billdate;
  String billno;
  int counterid;
  num totalamount;
  num gstamount;
  num netamount;
  int iscancelled ;
  BillWiseSalesList({
    required this.billdate,
    required this.billno,
    required this.counterid,
    required this.totalamount,
    required this.gstamount,
    required this.netamount,
    required this.iscancelled
  });

  Map<String, dynamic> toMap() {
    return {
      'saledate': billdate,
      'posname': billno,
      'totalamount': totalamount,
      'gstamount': gstamount,
      'netamount': netamount,
      'iscancelled':iscancelled
    };
  }
}



class ProductWiseSalesList {
  String itemname;
  num qty;
  num totalamount;
  num gstamount;
  num netamount;

  ProductWiseSalesList({
    required this.itemname,
    required this.qty,    
    required this.totalamount,
    required this.gstamount,
    required this.netamount,
   
  });

  Map<String, dynamic> toMap() {
    return {
      'itemname': itemname,
      'qty': qty,
      'totalamount': totalamount,
      'gstamount': gstamount,
      'netamount': netamount,
      
    };
  }
}


class MonthlySalesList {
  
  String month;
  num totalamount;
  num gstamount;
  num netamount;

  MonthlySalesList({
    required this.month,  
    required this.totalamount,
    required this.gstamount,
    required this.netamount,
   
  });

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'totalamount': totalamount,
      'gstamount': gstamount,
      'netamount': netamount,
      
    };
  }
}


