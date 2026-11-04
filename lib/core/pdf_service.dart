import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';

class PdfService {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const _brown = PdfColor.fromInt(0xFF6F4E37);
  static const _dark = PdfColor.fromInt(0xFF3E2723);
  static const _line = PdfColor.fromInt(0xFFD9CFC4);

  // -——— formatting -———
  static double _d(dynamic v) => double.tryParse(v.toString()) ?? 0;
  static String _money(dynamic v) => '\$${_d(v).toStringAsFixed(2)}';
  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _date(DateTime d) =>
      '${_two(d.day)} ${_months[d.month - 1]} ${d.year}';
  static String _dateTime(DateTime d) =>
      '${_date(d)} ${_two(d.hour)}:${_two(d.minute)}';
  static String _api(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
  static String _pct(dynamic part, double whole) => whole <= 0
      ? '0.0%'
      : '${(_d(part) / whole * 100).toStringAsFixed(1)}%';

  // -——— print / save -———
  static Future<void> printBytes(Uint8List bytes, String name) async {
    await Printing.layoutPdf(name: name, onLayout: (_) async => bytes);
  }

  static Future<void> saveBytes(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  static Future<void> printReceipt(Order o) async =>
      printBytes(await receipt(o), 'receipt_${o.orderNumber}');

  static Future<void> saveReceipt(Order o) async =>
      saveBytes(await receipt(o), 'receipt_${o.orderNumber}.pdf');

  static Future<void> printReport(
          Map<String, dynamic> data, DateTime from, DateTime to) async =>
      printBytes(await reportPdf(data, from, to),
          'sales-report_${_api(from)}_to_${_api(to)}');

  static Future<void> saveReport(
          Map<String, dynamic> data, DateTime from, DateTime to) async =>
      saveBytes(await reportPdf(data, from, to),
          'sales-report_${_api(from)}_to_${_api(to)}.pdf');

  // -——— receipt (80 mm roll) -———
  static Future<Uint8List> receipt(Order o) async {
    final doc = pw.Document(title: 'Receipt ${o.orderNumber}');
    final normal = pw.TextStyle(fontSize: 9);
    final bold = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
    final small = pw.TextStyle(fontSize: 8, color: PdfColors.grey700);

    pw.Widget row(String l, String r, {pw.TextStyle? style}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text(l, style: style ?? normal)),
              pw.SizedBox(width: 6),
              pw.Text(r, style: style ?? normal),
            ],
          ),
        );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Text('COFFEE POS',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 2),
            pw.Center(child: pw.Text('Sales receipt', style: small)),
            pw.Divider(thickness: 0.5),
            row('Order', o.orderNumber),
            row('Date', _dateTime(o.createdAt)),
            if (o.cashier != null) row('Cashier', o.cashier!),
            row('Payment', o.paymentMethod.toUpperCase()),
            pw.Divider(thickness: 0.5),
            ...o.items.map(
              (i) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    row('${i.qty} x ${i.name}', _money(i.lineTotal)),
                    pw.Text('   @ ${_money(i.unitPrice)} each', style: small),],
                ),
              ),
            ),
            pw.Divider(thickness: 0.5),
            row('Subtotal', _money(o.subtotal)),
            if (o.discount > 0) row('Discount', '-${_money(o.discount)}'),
            pw.SizedBox(height: 2),
            row('TOTAL', _money(o.total),
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Divider(thickness: 0.5),
            if (o.status == 'cancelled') ...[
              pw.Center(child: pw.Text('*** CANCELLED ***', style: bold)),
              pw.SizedBox(height: 4),
            ],
            pw.Center(child: pw.Text('Thank you! Please come again.', style: normal)),
            pw.SizedBox(height: 8),
          ],
        ),
      ),
    );
    return doc.save();
  }

  // -——— report (A4) -———
  static pw.Widget _heading(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18, bottom: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(t.toUpperCase(),
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _brown,
                    letterSpacing: 1)),
            pw.Divider(color: _line, thickness: 0.8, height: 8),
          ],
        ),
      );

  static pw.Widget _kv(String l, String v, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(l,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight:
                        bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            pw.Text(v,
                style: pw.TextStyle(
                    fontSize: bold ? 11 : 10,
                    fontWeight:
                        bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ],
        ),
      );

  static pw.Widget _empty() => pw.Text('No data for this period',
      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600));

  static pw.Widget _table(List<String> heads, List<List<String>> rows,
      {Set<int> numeric = const {}}) {
    return pw.TableHelper.fromTextArray(
      headers: heads,
      data: rows,
      headerStyle: pw.TextStyle(
          fontSize: 9, fontWeight: pw.FontWeight.bold, color: _dark),
      cellStyle: pw.TextStyle(fontSize: 9),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1E9E0)),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _line, width: 0.5),
        bottom: pw.BorderSide(color: _line, width: 0.5),
      ),
      cellAlignments: {
        for (int i = 0; i < heads.length; i++)
          i: numeric.contains(i)
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft,
      },
    );
  }

  static Future<Uint8List> reportPdf(
      Map<String, dynamic> data, DateTime from, DateTime to) async {
    final s = data['summary'] as Map;
    final net = _d(s['net_sales']);
    final pay = data['by_payment'] as List;
    final daily = data['daily'] as List;
    final top = data['top_products'] as List;
    final cashiers = data['by_cashier'] as List;
    final gen = DateTime.tryParse(data['generated_at'].toString());

    final period =
        from == to ? _date(from) : '${_date(from)} to ${_date(to)}';
    final generated = gen == null ? '-' : _dateTime(gen);

    int n = 0;
    String num(String t) => '${++n}. $t';

    final doc = pw.Document(title: 'Sales Report', author: 'Coffee POS');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text('Coffee POS  |  Sales Report  |  $period',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ),
        build: (ctx) => [
          pw.Center(
            child: pw.Text('COFFEE POS',
                style: pw.TextStyle(
                    fontSize: 11,
                    letterSpacing: 3,
                    fontWeight: pw.FontWeight.bold,
                    color: _brown)),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text('Sales Report',
                style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: _dark)),
          ),
          pw.SizedBox(height: 16),
          _kv('Period', period),
          _kv('Scope', data['scope'].toString()),
          _kv('Prepared by', data['prepared_by'].toString()),
          _kv('Generated', generated),

          _heading(num('Summary')),
          _kv('Completed orders', '${s['orders']}'),
          _kv('Items sold', '${s['items_sold']}'),
          _kv('Gross sales', _money(s['gross_sales'])),
          _kv('Less: discounts', '-${_money(s['discounts'])}'),
          pw.Divider(color: _line, thickness: 0.8, height: 8),
          _kv('Net sales', _money(s['net_sales']), bold: true),
          pw.Divider(color: _line, thickness: 0.8, height: 8),
          _kv('Average order value', _money(s['average_order'])),
          _kv('Cancelled orders',
              '${s['cancelled_orders']} (${_money(s['cancelled_value'])})'),

          _heading(num('Sales by payment method')),
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

          if (from != to) ...[
            _heading(num('Daily sales')),
            daily.isEmpty
                ? _empty()
                : _table(
                    ['Date', 'Orders', 'Net sales'],
                    daily.map<List<String>>((d) {
                      final dt = DateTime.tryParse(d['day'].toString());
                      return [
                        dt == null ? d['day'].toString() : _date(dt),
                        '${d['orders']}',
                        _money(d['sales']),
                      ];
                    }).toList(),
                    numeric: {1, 2},
                  ),
          ],

          _heading(num('Top products')),
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

          if (cashiers.isNotEmpty) ...[
            _heading(num('Sales by employee')),
            _table(
              ['Employee', 'Orders', 'Sales', 'Share'],
              cashiers
                  .map<List<String>>((c) => [
                        c['name'].toString(),
                        '${c['orders']}',_money(c['sales']),
                        _pct(c['sales'], net),
                      ])
                  .toList(),
              numeric: {1, 2, 3},
            ),
          ],

          pw.SizedBox(height: 24),
          pw.Divider(color: _line),
          pw.Center(
            child: pw.Text('End of report',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          ),
        ],
      ),
    );

    return doc.save();
  }
}