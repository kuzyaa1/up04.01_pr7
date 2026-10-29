import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/form_outcome.dart';
import '../core/validators.dart';
import '../models/studio_record.dart';
import '../repositories/booking_repository.dart';
import '../repositories/client_repository.dart';
import '../repositories/studio_record_repository.dart';
import '../widgets/dirty_guard.dart';
import '../widgets/entity_form.dart';
import '../widgets/state_views.dart';
import 'studio_records_screen.dart';

class StudioRecordFormScreen extends StatefulWidget {
  const StudioRecordFormScreen({super.key, required this.entity, this.id});
  final String entity;
  final int? id;
  @override
  State<StudioRecordFormScreen> createState() => _StudioRecordFormScreenState();
}

class _StudioRecordFormScreenState extends State<StudioRecordFormScreen> {
  final _form = GlobalKey<FormState>();
  final _fields = GlobalKey<EntityFormState>();
  late final StudioRecordRepository repository;
  StudioRecord? record;
  List<DropdownEntry> choices = [];
  bool loading = true, saving = false, dirty = false;
  String? error;
  Map<String, String> errors = {};
  int revision = 0;
  @override
  void initState() {
    super.initState();
    repository = StudioRecordRepository(context.read<Dio>(), widget.entity);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (widget.id != null) record = await repository.findById(widget.id!);
      if (!mounted) return;
      if (widget.entity == 'subscriptions') {
        final rows = await context.read<ClientRepository>().all();
        choices = [
          for (final r in rows) DropdownEntry(r.id, '${r.name} — ${r.email}')
        ];
      } else if (widget.entity == 'payments') {
        final rows = await context.read<BookingRepository>().all();
        choices = [
          for (final r in rows)
            DropdownEntry(r.id,
                '${r.accessCode} — ${r.clientName} · ${r.totalPrice.toStringAsFixed(2)} ₽')
        ];
      }
      if (mounted) setState(() => loading = false);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  FieldSpec text(String name, String label,
          {int min = 0,
          int max = 100,
          FieldType type = FieldType.text,
          Object? initial}) =>
      FieldSpec(
          name: name,
          label: label,
          type: type,
          initialValue: record?.values[name] ?? initial,
          serverError: errors[name],
          validators: [V.length(min: min, max: max)]);
  FieldSpec number(String name, String label, int min, int max,
          {int initial = 0}) =>
      FieldSpec(
          name: name,
          label: label,
          type: FieldType.number,
          initialValue: record?.values[name] ?? initial,
          serverError: errors[name],
          validators: [V.integer(min: min, max: max)]);
  FieldSpec date(String name, String label) => FieldSpec(
      name: name,
      label: label,
      type: FieldType.date,
      initialValue: record?.values[name] ??
          DateTime.now().toIso8601String().split('T').first,
      serverError: errors[name],
      validators: [V.date()]);
  FieldSpec select(String name, String label, List<String> values,
          {String? initial}) =>
      FieldSpec(
          name: name,
          label: label,
          type: FieldType.dropdownText,
          initialValue: record?.values[name] ?? initial,
          serverError: errors[name],
          textOptions: [for (final v in values) TextDropdownEntry(v, v)],
          validators: [V.notNull()]);
  List<FieldSpec> get specs => switch (widget.entity) {
        'services' => [
            text('name', 'Название услуги', min: 2),
            text('category', 'Категория', min: 2, max: 60),
            number('price', 'Стоимость, ₽', 0, 1000000),
            text('description', 'Описание',
                max: 1000, type: FieldType.multiline),
          ],
        'subscriptions' => [
            FieldSpec(
                name: 'clientId',
                label: 'Клиент',
                type: FieldType.dropdown,
                initialValue: record?.values['clientId'],
                options: choices,
                serverError: errors['clientId'],
                validators: [V.notNull()]),
            text('number', 'Номер абонемента', min: 3, max: 40),
            date('issuedAt', 'Действует с'),
            FieldSpec(
                name: 'expiresAt',
                label: 'Действует до',
                type: FieldType.date,
                initialValue: record?.values['expiresAt'] ??
                    DateTime.now()
                        .add(const Duration(days: 365))
                        .toIso8601String()
                        .split('T')
                        .first,
                serverError: errors['expiresAt'],
                validators: [
                  V.date(),
                  (v) {
                    final start = DateTime.tryParse(
                        _fields.currentState?.string('issuedAt') ?? '');
                    final end = DateTime.tryParse(v ?? '');
                    return start != null && end != null && end.isBefore(start)
                        ? 'Окончание раньше начала'
                        : null;
                  }
                ]),
            number('discountPercent', 'Скидка на аренду зала, %', 0, 50),
          ],
        _ => [
            FieldSpec(
                name: 'bookingId',
                label: 'Бронирование',
                type: FieldType.dropdown,
                initialValue: record?.values['bookingId'],
                options: choices,
                serverError: errors['bookingId'],
                validators: [V.notNull()]),
            FieldSpec(
                name: 'amount',
                label: 'Сумма, ₽',
                initialValue: record?.values['amount'],
                serverError: errors['amount'],
                validators: [
                  (v) {
                    final n = double.tryParse(v ?? '');
                    return n == null ||
                            !n.isFinite ||
                            n < 0.01 ||
                            n > 999999999 ||
                            !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(v ?? '')
                        ? 'Укажите сумму от 0,01 с точностью до копеек'
                        : null;
                  }
                ]),
            select('method', 'Способ оплаты', ['Карта', 'Наличные', 'Перевод'],
                initial: 'Карта'),
            select('status', 'Статус', ['paid', 'pending', 'refunded'],
                initial: 'paid'),
            date('paidAt', 'Дата оплаты'),
            text('note', 'Примечание', max: 300, type: FieldType.multiline),
          ],
      };
  Future<void> _save() async {
    if (saving || !(_form.currentState?.validate() ?? false)) return;
    final form = _fields.currentState!;
    final data = <String, dynamic>{};
    for (final field in specs) {
      data[field.name] = switch (field.type) {
        FieldType.number || FieldType.dropdown => form.number(field.name),
        _ => form.string(field.name),
      };
    }
    if (widget.entity == 'payments') {
      data['amount'] = double.parse(form.string('amount'));
    }
    setState(() {
      saving = true;
      errors = {};
    });
    try {
      if (widget.id == null) {
        await repository.create(StudioRecord(data));
      } else {
        await repository.update(widget.id!, StudioRecord(data));
      }
      dirty = false;
      if (mounted) context.go('/${widget.entity}');
    } on Object catch (e) {
      if (!mounted) return;
      final outcome = toFormOutcome(e);
      if (outcome is FormInvalid) {
        setState(() {
          errors = outcome.errors;
          revision++;
        });
      } else {
        showFormError(context, outcome);
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => DirtyGuard(
      isDirty: () => dirty,
      fallbackLocation: '/${widget.entity}',
      child: Scaffold(
        appBar: AppBar(
            title: Text(
                '${widget.id == null ? 'Добавить' : 'Изменить'} · ${studioEntityTitle(widget.entity)}')),
        body: loading
            ? const LoadingView()
            : error != null
                ? ErrorView(message: error!, onRetry: _load)
                : EntityForm(
                    key: _fields,
                    formKey: _form,
                    fields: specs,
                    saving: saving,
                    rebuildToken: revision,
                    onSubmit: _save,
                    onCancel: () => context.go('/${widget.entity}'),
                    onChanged: () => dirty = true,
                  ),
      ));
}
