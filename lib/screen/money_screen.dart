import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phonekit_manager/model/money_model.dart';
import 'package:phonekit_manager/services/money_service.dart';

class MoneyPage extends StatefulWidget {
  final String currentShop;
  final String currentEmail;
  final String currentRole;

  const MoneyPage(this.currentShop, this.currentEmail, this.currentRole,
      {Key? key})
      : super(key: key);

  @override
  State<MoneyPage> createState() => _MoneyPageState();
}

class _MoneyPageState extends State<MoneyPage> {
  final MoneyService _moneyService = MoneyService();
  DateTime _selectedDate = DateTime.now();
  bool _isDay = true;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2021),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Widget _summaryCard(String title, double value, Color color, IconData icon) {
    final currency =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 4),
              Text(currency.format(value * 1000),
                  style: TextStyle(
                      color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(List<MoneyModel> data, int shopIndex) {
    if (data.isEmpty) return const SizedBox.shrink();

    List<FlSpot> doanhThuPoints = [];
    List<FlSpot> loiNhuanPoints = [];

    // Chuyển dữ liệu thành điểm (x = ngày, y = tiền)
    for (var e in data) {
      final x = e.date.day.toDouble();
      final giaBan = double.tryParse(e.gia_ban[shopIndex]) ?? 0;
      final giaNhap = double.tryParse(e.gia_nhap[shopIndex]) ?? 0;
      final loi = giaBan - giaNhap;
      doanhThuPoints.add(FlSpot(x, giaBan));
      loiNhuanPoints.add(FlSpot(x, loi));
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              'Biểu đồ doanh thu & lợi nhuận',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: doanhThuPoints,
                      color: Colors.deepOrange,
                      barWidth: 3,
                      isCurved: true,
                      dotData: FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: loiNhuanPoints,
                      color: Colors.green,
                      barWidth: 3,
                      isCurved: true,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.circle, size: 10, color: Colors.deepOrange),
                SizedBox(width: 4),
                Text('Doanh thu', style: TextStyle(fontSize: 12)),
                SizedBox(width: 16),
                Icon(Icons.circle, size: 10, color: Colors.green),
                SizedBox(width: 4),
                Text('Lợi nhuận', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(MoneyModel task, int index) {
    final currencyFormat =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    int shopIndex = widget.currentShop == "Cửa hàng Quang Tèo 1"
        ? 0
        : widget.currentShop == "Cửa hàng Quang Tèo 2"
            ? 1
            : 2;

    double giaBan = double.tryParse(task.gia_ban[shopIndex]) ?? 0;
    double giaNhap = double.tryParse(task.gia_nhap[shopIndex]) ?? 0;
    double lai = giaBan - giaNhap;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.deepPurpleAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sell_rounded, color: Colors.deepPurpleAccent),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd/MM/yyyy').format(task.date),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: lai >= 0
                    ? Colors.green.withOpacity(0.15)
                    : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                lai >= 0
                    ? '+${currencyFormat.format(lai * 1000)}'
                    : currencyFormat.format(lai * 1000),
                style: TextStyle(
                  color: lai >= 0 ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.arrow_upward_rounded,
                      size: 14, color: Colors.deepOrange),
                  const SizedBox(width: 4),
                  Text('Bán: ${currencyFormat.format(giaBan * 1000)}',
                      style: const TextStyle(
                          color: Colors.deepOrange, fontSize: 13)),
                ],
              ),
              if (widget.currentRole == 'admin') ...[
                Row(
                  children: [
                    const Icon(Icons.arrow_downward_rounded,
                        size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text('Nhập: ${currencyFormat.format(giaNhap * 1000)}',
                        style: const TextStyle(
                            color: Colors.blueGrey, fontSize: 13)),
                  ],
                ),
              ]
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () {
          // Mở chi tiết nếu cần sau này
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.currentShop,
            style: const TextStyle(
                color: Colors.deepPurpleAccent,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: Colors.deepPurpleAccent),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<MoneyModel>>(
        stream:
            _moneyService.streamMoneyData(widget.currentShop, _selectedDate),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          if (data.isEmpty)
            return const Center(child: Text('Không có dữ liệu'));

          int shopIndex = widget.currentShop == "Cửa hàng Quang Tèo 1"
              ? 0
              : widget.currentShop == "Cửa hàng Quang Tèo 2"
                  ? 1
                  : 2;

          double tongBan = data.fold(0.0,
              (sum, e) => sum + (double.tryParse(e.gia_ban[shopIndex]) ?? 0));
          double tongNhap = data.fold(0.0,
              (sum, e) => sum + (double.tryParse(e.gia_nhap[shopIndex]) ?? 0));
          double tongLai = tongBan - tongNhap;

          final list = _isDay ? data : _moneyService.sumMoneyByMonth(data);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _summaryCard('Tổng bán', tongBan, Colors.deepOrange,
                        Icons.attach_money_rounded),
                    const SizedBox(width: 8),
                    _summaryCard('Nhập hàng', tongNhap, Colors.blueGrey,
                        Icons.shopping_cart_outlined),
                    const SizedBox(width: 8),
                    _summaryCard(
                        'Lợi nhuận',
                        tongLai,
                        tongLai >= 0 ? Colors.green : Colors.red,
                        Icons.trending_up),
                  ],
                ),
              ),
              _buildChart(data, shopIndex),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month,
                              color: Colors.deepPurpleAccent),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM yyyy').format(_selectedDate),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurpleAccent),
                          )
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _isDay = true),
                            child: Text('Ngày',
                                style: TextStyle(
                                    color: _isDay
                                        ? Colors.deepPurpleAccent
                                        : Colors.grey)),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _isDay = false),
                            child: Text('Tháng',
                                style: TextStyle(
                                    color: !_isDay
                                        ? Colors.deepPurpleAccent
                                        : Colors.grey)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) =>
                      _buildItem(list[index], index + 1),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
