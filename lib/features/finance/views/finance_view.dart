import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/settings_provider.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';

class FinanceView extends ConsumerWidget {
  const FinanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionListProvider);
    final settings =
        ref.watch(settingsProvider).asData?.value ?? UserSettings();
    final currency = settings.currency;

    return Scaffold(
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width - 48,
        height: 50,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(context, ref, currency),
          icon: const Icon(Icons.add),
          label: const Text('ADD TRANSACTION'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: txState.when(
        data: (transactions) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatCards(context, transactions, currency),
              const SizedBox(height: 32),
              _buildChartSection(context, transactions),
              const SizedBox(height: 32),
              _buildTransactionLog(context, transactions, ref, currency),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('ERROR // $e')),
      ),
    );
  }

  Widget _buildStatCards(
    BuildContext context,
    List<Transaction> txs,
    String currency,
  ) {
    double income = txs
        .where((t) => t.isIncome)
        .fold(0, (s, t) => s + t.amount);
    double expenses = txs
        .where((t) => !t.isIncome)
        .fold(0, (s, t) => s + t.amount);
    double balance = income - expenses;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'INCOME',
            value: '$currency${income.toStringAsFixed(0)}',
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'BALANCE',
            value: '$currency${balance.toStringAsFixed(0)}',
            color: balance >= 0
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'EXPENSES',
            value: '$currency${expenses.toStringAsFixed(0)}',
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(BuildContext context, List<Transaction> txs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MONTHLY ANALYSIS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Container(
            height: 240,
            padding: const EdgeInsets.all(24),
            child: txs.isEmpty
                ? const Center(child: Text('NO DATA AVAILABLE'))
                : _FinanceChart(txs: txs),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionLog(
    BuildContext context,
    List<Transaction> txs,
    WidgetRef ref,
    String currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT TRANSACTIONS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        if (txs.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('NO TRANSACTIONS RECORDED')),
            ),
          )
        else
          ...txs
              .take(15)
              .map((t) => _TransactionTile(t: t, currency: currency, ref: ref)),
      ],
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, String currency) {
    final descC = TextEditingController();
    final amountC = TextEditingController();
    String category = Transaction.categories.first;
    bool isIncome = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ADD TRANSACTION',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('EXPENSE'),
                    icon: Icon(Icons.remove_circle_outline),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('INCOME'),
                    icon: Icon(Icons.add_circle_outline),
                  ),
                ],
                selected: {isIncome},
                onSelectionChanged: (v) => setS(() => isIncome = v.first),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: descC,
                decoration: const InputDecoration(
                  labelText: 'DESCRIPTION',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountC,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'AMOUNT',
                  prefixText: currency,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'CATEGORY',
                  border: OutlineInputBorder(),
                ),
                items: Transaction.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setS(() => category = v!),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  final amount = double.tryParse(amountC.text);
                  if (descC.text.isNotEmpty && amount != null) {
                    ref
                        .read(transactionListProvider.notifier)
                        .addTransaction(
                          Transaction(
                            description: descC.text,
                            amount: amount,
                            category: category,
                            isIncome: isIncome,
                            date: DateTime.now(),
                          ),
                        );
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('SAVE TRANSACTION'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction t;
  final String currency;
  final WidgetRef ref;
  const _TransactionTile({
    required this.t,
    required this.currency,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: t.isIncome
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(
            t.isIncome ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: t.isIncome
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
          ),
        ),
        title: Text(t.description),
        subtitle: Text('${t.category} • ${t.date.month}/${t.date.day}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${t.isIncome ? '+' : '-'}$currency${t.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: t.isIncome
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => ref
                  .read(transactionListProvider.notifier)
                  .deleteTransaction(t.id!),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceChart extends StatelessWidget {
  final List<Transaction> txs;
  const _FinanceChart({required this.txs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];
    List<FlSpot> balanceSpots = [];
    double cumInc = 0, cumExp = 0;

    for (int i = 1; i <= now.day; i++) {
      final dayTxs = txs.where(
        (t) => t.date.day == i && t.date.month == now.month,
      );
      for (final t in dayTxs) {
        if (t.isIncome) {
          cumInc += t.amount;
        } else {
          cumExp += t.amount;
        }
      }
      incomeSpots.add(FlSpot(i.toDouble(), cumInc));
      expenseSpots.add(FlSpot(i.toDouble(), cumExp));
      balanceSpots.add(FlSpot(i.toDouble(), cumInc - cumExp));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 10,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            color: Theme.of(context).colorScheme.secondary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(
                context,
              ).colorScheme.secondary.withValues(alpha: 0.1),
            ),
          ),
          LineChartBarData(
            spots: balanceSpots,
            isCurved: true,
            color: Theme.of(context).colorScheme.tertiary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}
