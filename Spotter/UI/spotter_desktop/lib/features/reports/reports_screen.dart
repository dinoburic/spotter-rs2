import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/providers/order_provider.dart';
import '../../core/providers/ticket_provider.dart';
import '../../core/providers/event_provider.dart';
import '../../core/models/order_response.dart';
import '../../core/models/ticket_response.dart';
import '../../core/models/event_response.dart';
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
  List<EventResponse> _events = [];
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      _events = await context.read<EventProvider>().loadForDropdown();
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingEvents = false);
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
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _generateFinancialReport() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final provider = context.read<OrderProvider>();
      final allOrders = <OrderResponse>[];

      provider.setPage(1);
      await provider.loadAll(status: 1);
      allOrders.addAll(provider.items);

      final filteredOrders = allOrders.where((order) {
        return order.createdAt.isAfter(_startDate) &&
            order.createdAt.isBefore(_endDate.add(const Duration(days: 1)));
      }).toList();

      final totalRevenue = filteredOrders.fold<double>(
        0,
        (sum, order) => sum + order.totalAmount,
      );

      final pdf = pw.Document();
      final dateFormat = DateFormat('yyyy-MM-dd');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Financial Report',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Period: ${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
            ),
            pw.Text('Generated: ${dateFormat.format(DateTime.now())}'),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Revenue:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${totalRevenue.toStringAsFixed(2)} BAM',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Paid Orders (${filteredOrders.length})',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellPadding: const pw.EdgeInsets.all(5),
              headers: ['Order #', 'Event', 'User', 'Amount', 'Date'],
              data: filteredOrders.map((order) {
                return [
                  '#${order.id}',
                  order.eventTitle.length > 30
                      ? '${order.eventTitle.substring(0, 30)}...'
                      : order.eventTitle,
                  order.userFullName,
                  '${order.totalAmount.toStringAsFixed(2)} BAM',
                  dateFormat.format(order.createdAt),
                ];
              }).toList(),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.pop(context);
        await Printing.layoutPdf(
          onLayout: (format) => pdf.save(),
          name: 'financial_report_${dateFormat.format(DateTime.now())}.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _generateGuestList() async {
    if (_selectedEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final provider = context.read<TicketProvider>();
      final usedTickets =
          await provider.getUsedTicketsForEvent(_selectedEventId!);

      final event = _events.firstWhere((e) => e.id == _selectedEventId);

      final pdf = pw.Document();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Guest List',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Event: ${event.title}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Venue: ${event.venueName}'),
            pw.Text('Date: ${dateFormat.format(event.startsAt)}'),
            pw.Text('Generated: ${dateFormat.format(DateTime.now())}'),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text('Total Attendees: ${usedTickets.length}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            if (usedTickets.isEmpty)
              pw.Text('No used tickets found for this event.')
            else
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
                cellPadding: const pw.EdgeInsets.all(5),
                headers: ['#', 'User', 'Ticket Type', 'Used At'],
                data: usedTickets.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final ticket = entry.value;
                  return [
                    index.toString(),
                    ticket.userFullName,
                    '${ticket.ticketTypeName} (${ticket.typeName})',
                    ticket.usedAt != null
                        ? dateFormat.format(ticket.usedAt!)
                        : '-',
                  ];
                }).toList(),
              ),
          ],
        ),
      );

      if (mounted) {
        Navigator.pop(context);
        await Printing.layoutPdf(
          onLayout: (format) => pdf.save(),
          name:
              'guest_list_${event.title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const SpotterDrawer(currentRoute: 'reports'),
      body: _isLoadingEvents
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.attach_money, size: 32),
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
                                      labelText: 'Start Date',
                                      border: OutlineInputBorder(),
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
                                      labelText: 'End Date',
                                      border: OutlineInputBorder(),
                                    ),
                                    child: Text(dateFormat.format(_endDate)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _generateFinancialReport,
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Generate Financial Report'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people, size: 32),
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
                            'Generate a list of attendees for a specific event',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          DropdownButtonFormField<int>(
                            value: _selectedEventId,
                            decoration: const InputDecoration(
                              labelText: 'Select Event',
                              border: OutlineInputBorder(),
                            ),
                            items: _events
                                .map((event) => DropdownMenuItem(
                                      value: event.id,
                                      child: Text(event.title),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedEventId = value);
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _generateGuestList,
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Generate Guest List'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
