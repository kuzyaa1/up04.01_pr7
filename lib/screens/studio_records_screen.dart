import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/studio_record.dart';
import '../repositories/studio_record_repository.dart';
import '../state/list_notifier.dart';
import '../state/session.dart';
import '../state/studio_records_store.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import '../widgets/state_views.dart';

String studioEntityTitle(String entity) => switch (entity) {
      'subscriptions' => 'Абонементы',
      'payments' => 'Оплаты',
      _ => 'Дополнительные услуги',
    };

class StudioRecordsScreen extends StatefulWidget {
  const StudioRecordsScreen(
      {super.key, required this.entity, required this.query});
  final String entity;
  final StudioQuery query;
  @override
  State<StudioRecordsScreen> createState() => _StudioRecordsScreenState();
}

class _StudioRecordsScreenState extends State<StudioRecordsScreen> {
  late final StudioRecordsStore store;
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    store = StudioRecordsStore(
        StudioRecordRepository(context.read<Dio>(), widget.entity),
        widget.query)
      ..load();
  }

  @override
  void didUpdateWidget(covariant StudioRecordsScreen old) {
    super.didUpdateWidget(old);
    if (old.query.parameters.toString() != widget.query.parameters.toString()) {
      store.applyQuery(widget.query);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    store.dispose();
    super.dispose();
  }

  void _filter(String key, String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.go(widget.query
            .change({key: value, 'page': '1'}).location(widget.entity));
      }
    });
  }

  Future<void> _operate(Future<void> Function() operation) async {
    try {
      await operation();
    } on Object catch (e) {
      if (mounted) await showOperationError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = context.watch<SessionStore>().permissions;
    final manage = permissions.canManageEntity(widget.entity);
    final minKey = switch (widget.entity) {
      'subscriptions' => 'discountFrom',
      'payments' => 'amountFrom',
      _ => 'priceFrom'
    };
    final maxKey = switch (widget.entity) {
      'subscriptions' => 'discountTo',
      'payments' => 'amountTo',
      _ => 'priceTo'
    };
    final sort = switch (widget.entity) {
      'subscriptions' => 'discountPercent',
      'payments' => 'amount',
      _ => 'price'
    };
    return AnimatedBuilder(
        animation: store,
        builder: (context, _) => Scaffold(
              appBar: AppBar(
                  title: Text(studioEntityTitle(widget.entity)),
                  actions: [
                    IconButton(
                        tooltip: 'Обновить',
                        onPressed: store.load,
                        icon: const Icon(Icons.refresh)),
                  ]),
              body: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1440),
                      child: Column(children: [
                        Padding(
                            padding: const EdgeInsets.all(12),
                            child: Wrap(spacing: 12, runSpacing: 12, children: [
                              if (manage)
                                FilledButton.icon(
                                    onPressed: () =>
                                        context.go('/${widget.entity}/new'),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Добавить')),
                              if (store.hasSelection && manage)
                                TextButton(
                                    onPressed: () =>
                                        _operate(store.deleteSelected),
                                    child: Text(
                                        'Удалить выбранные (${store.selected.length})')),
                              if (store.hasSelection &&
                                  permissions.canHardDelete)
                                TextButton(
                                    onPressed: () async {
                                      if (await confirm(
                                          context, 'Стереть выбранные записи?',
                                          hard: true)) {
                                        await _operate(store.eraseSelected);
                                      }
                                    },
                                    child: const Text('Стереть выбранные')),
                            ])),
                        AdaptiveFilters(
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      SizedBox(
                                          width: 250,
                                          child: TextFormField(
                                              initialValue: widget
                                                  .query.parameters['search'],
                                              decoration: const InputDecoration(
                                                  labelText: 'Поиск',
                                                  border: OutlineInputBorder()),
                                              onChanged: (v) =>
                                                  _filter('search', v))),
                                      if (widget.entity == 'services')
                                        SizedBox(
                                            width: 200,
                                            child: TextFormField(
                                                initialValue: widget.query
                                                    .parameters['category'],
                                                decoration: const InputDecoration(
                                                    labelText: 'Категория',
                                                    border:
                                                        OutlineInputBorder()),
                                                onChanged: (v) =>
                                                    _filter('category', v))),
                                      SizedBox(
                                          width: 160,
                                          child: TextFormField(
                                              initialValue: widget
                                                  .query.parameters[minKey],
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                  labelText: widget.entity ==
                                                          'subscriptions'
                                                      ? 'Скидка от, %'
                                                      : 'Сумма от, ₽',
                                                  border:
                                                      const OutlineInputBorder()),
                                              onChanged: (v) =>
                                                  _filter(minKey, v))),
                                      SizedBox(
                                          width: 160,
                                          child: TextFormField(
                                              initialValue: widget
                                                  .query.parameters[maxKey],
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                  labelText: widget.entity ==
                                                          'subscriptions'
                                                      ? 'Скидка до, %'
                                                      : 'Сумма до, ₽',
                                                  border:
                                                      const OutlineInputBorder()),
                                              onChanged: (v) =>
                                                  _filter(maxKey, v))),
                                      SizedBox(
                                          width: 200,
                                          child: DropdownButtonFormField<
                                                  String>(
                                              value: widget.query
                                                      .parameters['sort'] ??
                                                  'id,asc',
                                              decoration: const InputDecoration(
                                                  labelText: 'Сортировка',
                                                  border: OutlineInputBorder()),
                                              items: [
                                                const DropdownMenuItem(
                                                    value: 'id,asc',
                                                    child: Text('По номеру')),
                                                DropdownMenuItem(
                                                    value: '$sort,asc',
                                                    child: const Text(
                                                        'По возрастанию')),
                                                DropdownMenuItem(
                                                    value: '$sort,desc',
                                                    child: const Text(
                                                        'По убыванию'))
                                              ],
                                              onChanged: (v) {
                                                if (v != null) {
                                                  context.go(widget.query
                                                      .change({
                                                    'sort': v,
                                                    'page': '1'
                                                  }).location(widget.entity));
                                                }
                                              })),
                                      if (permissions.canRestore)
                                        FilterChip(
                                            label: const Text('Удалённые'),
                                            selected:
                                                widget.query.includeDeleted,
                                            onSelected: (v) => context.go(
                                                    widget.query.change({
                                                  'includeDeleted':
                                                      v ? 'true' : null,
                                                  'page': '1'
                                                }).location(widget.entity))),
                                    ]))),
                        Expanded(
                            child: switch (store.status) {
                          LoadStatus.idle ||
                          LoadStatus.loading =>
                            const LoadingView(),
                          LoadStatus.error => ErrorView(
                              message: store.error ?? 'Ошибка загрузки',
                              onRetry: store.load),
                          LoadStatus.success => store.result.items.isEmpty
                              ? const EmptyView(message: 'Записи не найдены')
                              : ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: store.result.items.length,
                                  itemBuilder: (context, i) {
                                    final r = store.result.items[i];
                                    final lines = switch (widget.entity) {
                                      'services' =>
                                        '${r.text('category')} · ${r.text('price')} ₽\n${r.text('description')}',
                                      'subscriptions' =>
                                        'Клиент №${r.text('clientId')} · скидка ${r.text('discountPercent')}%\n${r.text('issuedAt')} — ${r.text('expiresAt')}',
                                      _ =>
                                        'Бронирование №${r.text('bookingId')} · ${r.text('amount')} ₽\n${r.text('method')} · ${r.text('paidAt')} · ${r.text('status')}',
                                    };
                                    return Card(
                                        child: ResponsiveRecordTile(
                                      leading: manage
                                          ? Checkbox(
                                              value:
                                                  store.selected.contains(r.id),
                                              onChanged: (_) =>
                                                  store.toggle(r.id))
                                          : null,
                                      title: Text(
                                          '${r.title}${r.isDeleted ? ' (удалено)' : ''}'),
                                      subtitle: Text(lines),
                                      trailing: manage
                                          ? Wrap(children: [
                                              IconButton(
                                                  tooltip: 'Редактировать',
                                                  onPressed: () => context.go(
                                                      '/${widget.entity}/${r.id}/edit'),
                                                  icon: const Icon(
                                                      Icons.edit_outlined)),
                                              if (!r.isDeleted)
                                                IconButton(
                                                    tooltip: 'Удалить',
                                                    onPressed: () async {
                                                      if (await confirm(context,
                                                          'Удалить ${r.title}?')) {
                                                        await _operate(() =>
                                                            store.softDelete(
                                                                r.id));
                                                      }
                                                    },
                                                    icon: const Icon(
                                                        Icons.delete_outline)),
                                              if (r.isDeleted &&
                                                  permissions.canRestore)
                                                IconButton(
                                                    tooltip: 'Восстановить',
                                                    onPressed: () => _operate(
                                                        () => store
                                                            .restore(r.id)),
                                                    icon: const Icon(
                                                        Icons.restore)),
                                              if (permissions.canHardDelete)
                                                IconButton(
                                                    tooltip: 'Стереть навсегда',
                                                    onPressed: () async {
                                                      if (await confirm(context,
                                                          'Стереть ${r.title}?',
                                                          hard: true)) {
                                                        await _operate(() =>
                                                            store.hardDelete(
                                                                r.id));
                                                      }
                                                    },
                                                    icon: const Icon(
                                                        Icons.delete_forever)),
                                            ])
                                          : null,
                                    ));
                                  }),
                        }),
                        if (store.status == LoadStatus.success)
                          Pager(
                              page: store.result.page,
                              totalPages: store.result.totalPages,
                              total: store.result.total,
                              size: store.result.size,
                              onPage: (v) => context.go(widget.query.change(
                                  {'page': '$v'}).location(widget.entity)),
                              onSize: (v) => context.go(widget.query
                                  .change({'size': '$v', 'page': '1'}).location(
                                      widget.entity))),
                      ]))),
            ));
  }
}
