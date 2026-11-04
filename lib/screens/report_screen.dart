import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/api_error.dart';
import 'home_screen.dart' show brown, darkBrown, cream;
import '../core/pdf_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
Future<void> _export({required bool doPrint}) async {
    if (data == null) return;
    try {
      if (doPrint) {
        await PdfService.printReport(data!, from, to);
      } else {
        await PdfService.saveReport(data!, from, to);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create the PDF')));
    }
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const _presets = [
    'Today', 'Yesterday', 'This week', 'This month', 'Custom'
  ];
  static const _line = Color(0xFFE0D6CC);

  String preset = 'Today';
  late DateTime from;
  late DateTime to;
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    from = DateTime(now.year, now.month, now.day);
    to = from;
    load();
  }

  // ---------- helpers ----------
  String _two(int n) => n.toString().padLeft(2, '0');
  String _api(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
  String _show(DateTime d) =>
      '${_two(d.day)} ${_months[d.month - 1]} ${d.year}';
  double _d(dynamic v) => double.tryParse(v.toString()) ?? 0;
  String _money(dynamic v) => '\$${_d(v).toStringAsFixed(2)}';
  String _pct(dynamic part, double whole) => whole <= 0
      ? '0.0%'
      : '${(_d(part) / whole * 100).toStringAsFixed(1)}%';

  // ---------- data ----------
  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await ApiClient.dio.get('/reports/summary',
          queryParameters: {'from': _api(from), 'to': _api(to)});
      data = Map<String, dynamic>.from(res.data);
    } catch (e) {
      error = apiError(e, 'Failed to load report');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> choose(String p) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (p == 'Custom') {
      final r = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: today,
        initialDateRange: DateTimeRange(start: from, end: to),
      );
      if (r == null) return;
      from = r.start;
      to = r.end;
    } else if (p == 'Today') {
      from = today;
      to = today;
    } else if (p == 'Yesterday') {
      final y = today.subtract(const Duration(days: 1));
      from = y;
      to = y;
    } else if (p == 'This week') {
      from = today.subtract(Duration(days: today.weekday - 1));
      to = today;
    } else {
      from = DateTime(today.year, today.month, 1);
      to = today;
    }
    setState(() => preset = p);
    load();
  }

  // ---------- small widgets ----------
  Widget _section(String title, Widget child) => Padding(
        padding: const EdgeInsets.only(top: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: brown,
              ),
            ),
            const Divider(height: 14, color: _line),
            child,
          ],
        ),
      );

  Widget _kv(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
            ),
            Text(value,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  fontSize: bold ? 16 : 14,
                )),
          ],
        ),
      );

  Widget _empty() => const Padding(padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No data for this period',
            style: TextStyle(color: Colors.grey)),
      );

  Widget _table(List<String> heads, List<List<String>> rows,
      {Set<int> numeric = const {}}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        horizontalMargin: 0,
        headingRowHeight: 36,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 40,
        headingTextStyle:
            const TextStyle(fontWeight: FontWeight.bold, color: darkBrown),
        columns: [
          for (int i = 0; i < heads.length; i++)
            DataColumn(label: Text(heads[i]), numeric: numeric.contains(i)),
        ],
        rows: rows
            .map((r) => DataRow(cells: [for (final c in r) DataCell(Text(c))]))
            .toList(),
      ),
    );
  }

  Widget _periodChips() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: _presets
            .map((p) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(p),
                    selected: preset == p,
                    onSelected: (_) => choose(p),
                    selectedColor: brown,
                    labelStyle: TextStyle(
                        color: preset == p ? Colors.white : darkBrown),
                    backgroundColor: Colors.white,
                    showCheckmark: false,
                    side: BorderSide.none,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _document() {
    final s = data!['summary'] as Map;
    final net = _d(s['net_sales']);
    final pay = data!['by_payment'] as List;
    final daily = data!['daily'] as List;
    final top = data!['top_products'] as List;
    final cashiers = data!['by_cashier'] as List;
    final gen = DateTime.tryParse(data!['generated_at'].toString());

    final period =
        from == to ? _show(from) : '${_show(from)} to ${_show(to)}';
    final generated = gen == null
        ? '-'
        : '${_show(gen)}, ${_two(gen.hour)}:${_two(gen.minute)}';

    int n = 0;
    String num(String t) => '${++n}. $t';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text('COFFEE POS',
                style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                    color: brown)),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text('Sales Report',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: darkBrown)),
          ),
          const SizedBox(height: 14),
          _kv('Period', period),
          _kv('Scope', data!['scope'].toString()),
          _kv('Prepared by', data!['prepared_by'].toString()),
          _kv('Generated', generated),

          _section(
            num('Summary'),
            Column(
              children: [
                _kv('Completed orders', '${s['orders']}'),
                _kv('Items sold', '${s['items_sold']}'),
                _kv('Gross sales', _money(s['gross_sales'])),
                _kv('Less: discounts', '-${_money(s['discounts'])}'),
                const Divider(height: 12, color: _line),
                _kv('Net sales', _money(s['net_sales']), bold: true),
                const Divider(height: 12, color: _line),_kv('Average order value', _money(s['average_order'])),
                _kv('Cancelled orders',
                    '${s['cancelled_orders']} (${_money(s['cancelled_value'])})'),
              ],
            ),
          ),

          _section(
            num('Sales by payment method'),
            pay.isEmpty
                ? _empty()
                : _table(
                    ['Method', 'Orders', 'Sales', 'Share'],
                    pay
                        .map<List<String>>((m) => [
                              m['payment_method'].toString().toUpperCase(),
                              '${m['orders']}',
                              _money(m['sales']),
                              _pct(m['sales'], net),
                            ])
                        .toList(),
                    numeric: {1, 2, 3},
                  ),
          ),

          if (from != to)
            _section(
              num('Daily sales'),
              daily.isEmpty
                  ? _empty()
                  : _table(
                      ['Date', 'Orders', 'Net sales'],
                      daily.map<List<String>>((d) {
                        final dt = DateTime.tryParse(d['day'].toString());
                        return [
                          dt == null ? d['day'].toString() : _show(dt),
                          '${d['orders']}',
                          _money(d['sales']),
                        ];
                      }).toList(),
                      numeric: {1, 2},
                    ),
            ),

          _section(
            num('Top products'),
            top.isEmpty
                ? _empty()
                : _table(
                    ['#', 'Product', 'Qty', 'Revenue', 'Share'],
                    [
                      for (int i = 0; i < top.length; i++)
                        [
                          '${i + 1}',
                          top[i]['product_name'].toString(),
                          '${top[i]['qty']}',
                          _money(top[i]['revenue']),
                          _pct(top[i]['revenue'], net),
                        ],
                    ],
                    numeric: {2, 3, 4},
                  ),
          ),

          if (cashiers.isNotEmpty)
            _section(
              num('Sales by employee'),
              _table(
                ['Employee', 'Orders', 'Sales', 'Share'],
                cashiers
                    .map<List<String>>((c) => [
                          c['name'].toString(),
                          '${c['orders']}',
                          _money(c['sales']),
                          _pct(c['sales'], net),
                        ])
                    .toList(),
                numeric: {1, 2, 3},
              ),
            ),

          const SizedBox(height: 22),
          const Divider(color: _line),
          const Center(
            child: Text('End of report',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        title: const Text('Report'),
        actions: [
          IconButton(
            tooltip: 'Print',
            icon: const Icon(Icons.print),
            onPressed:
                (loading || data == null) ? null : () => _export(doPrint: true),
          ),
          IconButton(
            tooltip: 'Save as PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: (loading || data == null)
                ? null
                : () => _export(doPrint: false),
          ),
        ],
      ),
      body: Column(
        children: [
          _periodChips(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(error!),
                            TextButton(
                                onPressed: load, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: load,
                        child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          children: [_document()],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}