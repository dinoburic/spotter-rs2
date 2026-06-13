import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/providers/order_provider.dart';
import '../../core/providers/ticket_provider.dart';
import '../../core/providers/event_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/models/order_response.dart';
import '../../core/models/ticket_response.dart';
import '../../core/models/event_response.dart';
import '../../core/models/category_response.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/spotter_drawer.dart';
import '../../widgets/loading_indicator.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int? _selectedEventId;
  int? _selectedCategoryId;
  List<EventResponse> _events = [];
  List<CategoryResponse> _categories = [];
  bool _isLoadingData = true;
  bool _isGeneratingFinancial = false;
  bool _isGeneratingGuestList = false;
  String? _eventValidationError;

  static final _primaryPdfColor = PdfColor.fromHex('#7C3AED');

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final eventsFuture = context.read<EventProvider>().loadForDropdown();
      final categoriesFuture =
          context.read<CategoryProvider>().loadForDropdown();

      final results = await Future.wait([eventsFuture, categoriesFuture]);
      _events = results[0] as List<EventResponse>;
      _categories = results[1] as List<CategoryResponse>;
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          if (date.isBefore(_startDate)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('End date cannot be before start date')),
            );
            return;
          }
          _endDate = date;
        }
      });
    }
  }

  Future<void> _generateFinancialReport() async {
    setState(() => _isGeneratingFinancial = true);

    try {
      final provider = context.read<OrderProvider>();
      var orders = await provider.loadForReport(
        from: _startDate,
        to: _endDate,
      );

      if (_selectedCategoryId != null) {
        final eventProvider = context.read<EventProvider>();
        final categoryEvents = _events
            .where((e) => e.categoryId == _selectedCategoryId)
            .map((e) => e.id)
            .toSet();
        orders = orders.where((o) => categoryEvents.contains(o.eventId)).toList();
      }

      if (orders.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No orders found for the selected filters')),
          );
        }
        return;
      }

      final totalRevenue = orders.fold<double>(
        0,
        (sum, order) => sum + order.totalAmount,
      );

      final pdf = _buildFinancialReportPdf(orders, totalRevenue);

      if (mounted) {
        await Printing.layoutPdf(
          onLayout: (format) => pdf.save(),
          name:
              'financial_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingFinancial = false);
      }
    }
  }

  pw.Document _buildFinancialReportPdf(
      List<OrderResponse> orders, double totalRevenue) {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy');
    final dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');

    final categoryName = _selectedCategoryId != null
        ? _categories
            .firstWhere((c) => c.id == _selectedCategoryId,
                orElse: () => CategoryResponse(id: 0, name: 'All', colorHex: ''))
            .name
        : 'All Categories';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'SPOTTER',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryPdfColor,
                  ),
                ),
                pw.Text(
                  'Financial Report',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: _primaryPdfColor, thickness: 2),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Period: ${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Category: $categoryName',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generated: ${dateTimeFormat.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 16),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated by Spotter Admin',
                  style:
                      const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style:
                      const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Text(
                      'Total Orders',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${orders.length}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryPdfColor,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  width: 1,
                  height: 40,
                  color: PdfColors.grey400,
                ),
                pw.Column(
                  children: [
                    pw.Text(
                      'Total Revenue',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${totalRevenue.toStringAsFixed(2)} BAM',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryPdfColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(1.3),
              5: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _primaryPdfColor),
                children: [
                  _buildTableHeader('Order ID'),
                  _buildTableHeader('Event'),
                  _buildTableHeader('User'),
                  _buildTableHeader('Date'),
                  _buildTableHeader('Amount (BAM)'),
                  _buildTableHeader('Status'),
                ],
              ),
              ...orders.asMap().entries.map((entry) {
                final index = entry.key;
                final order = entry.value;
                final isAlternate = index % 2 == 1;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isAlternate ? PdfColors.grey100 : PdfColors.white,
                  ),
                  children: [
                    _buildTableCell('#${order.id}'),
                    _buildTableCell(order.eventTitle.length > 25
                        ? '${order.eventTitle.substring(0, 25)}...'
                        : order.eventTitle),
                    _buildTableCell(order.userFullName),
                    _buildTableCell(dateFormat.format(order.createdAt)),
                    _buildTableCell(order.totalAmount.toStringAsFixed(2)),
                    _buildTableCell(order.statusName),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return pdf;
  }

  Future<void> _generateGuestList() async {
    if (_selectedEventId == null) {
      setState(() => _eventValidationError = 'Please select an event');
      return;
    }

    setState(() {
      _eventValidationError = null;
      _isGeneratingGuestList = true;
    });

    try {
      final provider = context.read<TicketProvider>();
      final tickets = await provider.loadForGuestList(_selectedEventId!);

      if (tickets.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No tickets found for this event')),
          );
        }
        return;
      }

      final event = _events.firstWhere((e) => e.id == _selectedEventId);

      final activeCount = tickets.where((t) => t.status == 0).length;
      final usedCount = tickets.where((t) => t.status == 1).length;
      final cancelledCount = tickets.where((t) => t.status == 2).length;

      final pdf = _buildGuestListPdf(
          tickets, event, activeCount, usedCount, cancelledCount);

      if (mounted) {
        await Printing.layoutPdf(
          onLayout: (format) => pdf.save(),
          name:
              'guest_list_${event.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingGuestList = false);
      }
    }
  }

  pw.Document _buildGuestListPdf(
    List<TicketResponse> tickets,
    EventResponse event,
    int activeCount,
    int usedCount,
    int cancelledCount,
  ) {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy');
    final dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'SPOTTER',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryPdfColor,
                  ),
                ),
                pw.Text(
                  'Guest List',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: _primaryPdfColor, thickness: 2),
            pw.SizedBox(height: 12),
            pw.Text(
              event.title,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Text(
                  'Event Date: ${dateTimeFormat.format(event.startsAt)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  '  |  Venue: ${event.venueName}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generated: ${dateTimeFormat.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 16),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated by Spotter Admin',
                  style:
                      const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style:
                      const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total Tickets', '${tickets.length}'),
                pw.Container(width: 1, height: 40, color: PdfColors.grey400),
                _buildSummaryItem('Active', '$activeCount', PdfColors.blue),
                pw.Container(width: 1, height: 40, color: PdfColors.grey400),
                _buildSummaryItem('Used', '$usedCount', PdfColors.green),
                pw.Container(width: 1, height: 40, color: PdfColors.grey400),
                _buildSummaryItem('Cancelled', '$cancelledCount', PdfColors.red),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.5),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _primaryPdfColor),
                children: [
                  _buildTableHeader('#'),
                  _buildTableHeader('User'),
                  _buildTableHeader('Ticket Type'),
                  _buildTableHeader('Type'),
                  _buildTableHeader('Status'),
                  _buildTableHeader('Issued At'),
                ],
              ),
              ...tickets.asMap().entries.map((entry) {
                final index = entry.key;
                final ticket = entry.value;
                final isAlternate = index % 2 == 1;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isAlternate ? PdfColors.grey100 : PdfColors.white,
                  ),
                  children: [
                    _buildTableCell('${index + 1}'),
                    _buildTableCell(ticket.userFullName),
                    _buildTableCell(ticket.ticketTypeName),
                    _buildTableCell(ticket.typeName),
                    _buildTableCell(ticket.statusName),
                    _buildTableCell(dateFormat.format(ticket.issuedAt)),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, String value, [PdfColor? color]) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: color ?? _primaryPdfColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const SpotterDrawer(currentRoute: 'reports'),
      body: _isLoadingData
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reports', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildFinancialReportCard(dateFormat)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildGuestListCard()),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFinancialReportCard(DateFormat dateFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, size: 32, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'Financial Report',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Generate a report of paid orders within a date range',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'From',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today, size: 20),
                      ),
                      child: Text(dateFormat.format(_startDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'To',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today, size: 20),
                      ),
                      child: Text(dateFormat.format(_endDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All Categories'),
                ),
                ..._categories.map((cat) => DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.name),
                    )),
              ],
              onChanged: (value) {
                setState(() => _selectedCategoryId = value);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingFinancial ? null : _generateFinancialReport,
                icon: _isGeneratingFinancial
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_isGeneratingFinancial
                    ? 'Generating...'
                    : 'Generate PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestListCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, size: 32, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'Guest List',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Generate a list of ticket holders for a specific event',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              value: _selectedEventId,
              decoration: InputDecoration(
                labelText: 'Select Event',
                border: const OutlineInputBorder(),
                errorText: _eventValidationError,
              ),
              items: _events
                  .map((event) => DropdownMenuItem(
                        value: event.id,
                        child: Text(
                          event.title.length > 40
                              ? '${event.title.substring(0, 40)}...'
                              : event.title,
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedEventId = value;
                  _eventValidationError = null;
                });
              },
            ),
            const SizedBox(height: 74),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingGuestList ? null : _generateGuestList,
                icon: _isGeneratingGuestList
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_isGeneratingGuestList
                    ? 'Generating...'
                    : 'Generate PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
