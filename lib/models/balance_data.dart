class BalanceData {
  final DateTime date;
  final double balance;

  BalanceData(this.date, this.balance);
}

// Example data
List<BalanceData> data = [
  BalanceData(DateTime.now().subtract(const Duration(days: 30)), 1000.0),
  BalanceData(DateTime.now().subtract(const Duration(days: 20)), 1200.0),
  BalanceData(DateTime.now().subtract(const Duration(days: 10)), 1150.0),
  BalanceData(DateTime.now(), 1300.0),
];