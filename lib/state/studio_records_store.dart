import 'package:dio/dio.dart';
import '../models/page_result.dart';
import '../models/studio_record.dart';
import '../repositories/studio_record_repository.dart';
import 'list_notifier.dart';

class StudioRecordsStore extends ListNotifier<StudioRecord> {
  StudioRecordsStore(this.repository, this.query);
  final StudioRecordRepository repository;
  StudioQuery query;
  @override
  Future<void> applyQuery(Object query) {
    this.query = query as StudioQuery;
    return super.applyQuery(query);
  }

  @override
  Future<PageResult<StudioRecord>> fetch(CancelToken token) =>
      repository.find(query, cancelToken: token);
  @override
  Future<void> softDelete(int id) async {
    await repository.softDelete(id);
    await load();
  }

  @override
  Future<void> hardDelete(int id) async {
    await repository.hardDelete(id);
    await load();
  }

  @override
  Future<void> restore(int id) async {
    await repository.restore(id);
    await load();
  }

  @override
  Future<void> deleteSelected() async {
    await repository.softDeleteMany(selectedIds);
    clearSelection();
    await load();
  }

  @override
  Future<void> eraseSelected() async {
    await repository.hardDeleteMany(selectedIds);
    clearSelection();
    await load();
  }
}
