import 'package:flutter/material.dart';
import '../../../shared/utils/time_picker_helper.dart';
import '../models/bill_model.dart';

class BillDetailSheet extends StatefulWidget {
  final Bill? bill;
  final String currency;

  const BillDetailSheet({super.key, this.bill, required this.currency});

  @override
  State<BillDetailSheet> createState() => _BillDetailSheetState();
}

class _BillDetailSheetState extends State<BillDetailSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _leadMinutesController;
  late BillRecurrence _recurrence;
  late DateTime _dueDate;
  late bool _reminderEnabled;
  late bool _paid;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final defaultDue = DateTime(now.year, now.month, now.day + 1, 9, 0);
    _titleController = TextEditingController(text: widget.bill?.title ?? '');
    _amountController = TextEditingController(
      text: widget.bill == null ? '' : widget.bill!.amount.toStringAsFixed(2),
    );
    _leadMinutesController = TextEditingController(
      text: (widget.bill?.leadMinutes ?? 60).toString(),
    );
    _recurrence = widget.bill?.recurrence ?? BillRecurrence.oneTime;
    _dueDate = widget.bill?.dueDate ?? defaultDue;
    _reminderEnabled = widget.bill?.reminderEnabled ?? true;
    _paid = widget.bill?.paid ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _leadMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.bill == null ? 'NEW BILL' : 'EDIT BILL',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'TITLE',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: widget.bill == null,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'AMOUNT',
                    prefixText: widget.currency,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'RECURRENCE',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<BillRecurrence>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: BillRecurrence.oneTime,
                        label: Text('ONE-TIME'),
                      ),
                      ButtonSegment(
                        value: BillRecurrence.monthly,
                        label: Text('MONTHLY'),
                      ),
                    ],
                    selected: {_recurrence},
                    onSelectionChanged: (set) {
                      setState(() => _recurrence = set.first);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'DUE DATE & TIME',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          '${_dueDate.year}.${_dueDate.month.toString().padLeft(2, '0')}.${_dueDate.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(
                          '${_dueDate.hour.toString().padLeft(2, '0')}:${_dueDate.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('ENABLE REMINDER'),
                  subtitle: const Text('Notify before due time'),
                  value: _reminderEnabled,
                  onChanged: (value) =>
                      setState(() => _reminderEnabled = value),
                ),
                if (_reminderEnabled)
                  TextField(
                    controller: _leadMinutesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'LEAD TIME (MINUTES)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('MARK AS PAID'),
                  subtitle: const Text('Paid bills do not send reminders'),
                  value: _paid,
                  onChanged: (value) => setState(() => _paid = value),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        child: Text(widget.bill == null ? 'CREATE' : 'SAVE'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;
    setState(() {
      _dueDate = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _dueDate.hour,
        _dueDate.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final selected = await showZenitTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _dueDate.hour, minute: _dueDate.minute),
    );
    if (selected == null) return;
    setState(() {
      _dueDate = DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final leadMinutes = int.tryParse(_leadMinutesController.text.trim()) ?? 0;

    if (title.isEmpty || amount == null) {
      return;
    }

    final now = DateTime.now();

    final result = Bill(
      id: widget.bill?.id,
      title: title,
      amount: amount,
      dueDate: _dueDate,
      recurrence: _recurrence,
      reminderEnabled: _reminderEnabled,
      leadMinutes: leadMinutes.clamp(0, 525600),
      paid: _paid,
      paidAt: _paid ? (widget.bill?.paidAt ?? now) : null,
      createdAt: widget.bill?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.pop(context, result);
  }
}
