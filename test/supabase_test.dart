import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:photo_studio_portal/core/api_exceptions.dart';
import 'package:photo_studio_portal/core/permissions.dart';
import 'package:photo_studio_portal/core/router.dart';
import 'package:photo_studio_portal/core/supabase_api.dart';
import 'package:photo_studio_portal/models/booking.dart';
import 'package:photo_studio_portal/models/studio_record.dart';
import 'package:photo_studio_portal/repositories/api_photographer_repository.dart';
import 'package:photo_studio_portal/repositories/supabase_auth_repository.dart';
import 'package:photo_studio_portal/core/config.dart';
import 'package:photo_studio_portal/screens/studio_record_form_screen.dart';
import 'package:photo_studio_portal/screens/studio_records_screen.dart';
import 'package:photo_studio_portal/state/session.dart';

class Adapter implements HttpClientAdapter {
  Adapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
          Future<void>? cancel) =>
      respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody reply(Object body, [int status = 200]) =>
    ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });

Dio client(Future<ResponseBody> Function(RequestOptions) respond,
    {Future<bool> Function()? refresh, String? Function()? token}) {
  final dio = buildSupabaseDio(
      tokenProvider: token ?? () => 'jwt',
      refreshTokens: refresh ?? () async => false,
      onSessionExpired: () async {});
  // Absolute URL is required by native test adapters. Production uses config.
  dio.options.baseUrl = 'https://example.supabase.co';
  dio.httpClientAdapter = Adapter(respond);
  return dio;
}

Future<void> mount(WidgetTester tester, Widget screen, Dio dio,
    {String role = 'admin'}) async {
  final session = SessionStore()
    ..setUser(AppUser(
        id: 1,
        username: role,
        fullName: 'Тест',
        email: 'test@example.com',
        role: role));
  await tester.pumpWidget(MultiProvider(providers: [
    Provider<Dio>.value(value: dio),
    ChangeNotifierProvider(create: (_) => session),
  ], child: MaterialApp(home: screen)));
}

void main() {
  for (final confirmation in [true, false]) {
    test('регистрация учитывает подтверждение почты: $confirmation', () async {
      final auth = SupabaseAuthRepository(Dio(), accessToken: () => null);
      auth.authDio.options.baseUrl = 'https://example.supabase.co/auth/v1';
      auth.authDio.httpClientAdapter = Adapter((o) async => reply({
            'user': {'id': 'new-user'},
            if (!confirmation) 'access_token': 'new-token',
          }));
      await auth.register(
          username: 'new_client',
          password: 'test-pass123!',
          fullName: 'Новый клиент',
          email: 'new@example.com');
      expect(auth.needsEmailConfirmation, confirmation);
    });
  }
  test('имя фотографа PostgreSQL читается и отправляется без потери', () {
    final repo = ApiPhotographerRepository(Dio());
    final photo = repo.fromJson({
      'id': 1,
      'firstName': 'Анна',
      'lastName': 'Иванова',
      'bio': 'Портреты'
    });
    expect(photo.fullName, 'Иванова Анна');
    expect(photo.bio, 'Портреты');
    final body = repo.toRequestBody(photo);
    if (useSupabase) {
      expect(body['firstName'], 'Анна');
      expect(body['lastName'], 'Иванова');
      expect(body['bio'], 'Портреты');
    } else {
      expect(body['fullName'], 'Иванова Анна');
    }
  });
  test('RPC сохраняет метод, фильтры и JWT', () async {
    final dio = client((o) async {
      expect(o.path, '/rest/v1/rpc/studio_api');
      expect(o.method, 'POST');
      expect(o.headers['Authorization'], 'Bearer jwt');
      final args = o.data as Map;
      expect(args['endpoint'], '/users');
      expect(args['method'], 'GET');
      expect(args['query'], {'size': '100', 'search': 'Иван'});
      return reply({});
    });
    await dio
        .get<dynamic>('/users?size=100', queryParameters: {'search': 'Иван'});
  });
  test('RPC передаёт тело создания', () async {
    final dio = client((o) async {
      final args = o.data as Map;
      expect(args['payload'], {'name': 'Ретушь'});
      expect(args['method'], 'POST');
      return reply({'id': 1});
    });
    await dio.post<dynamic>('/services', data: {'name': 'Ретушь'});
  });
  test('PostgREST 422 преобразуется в ошибки полей', () async {
    final dio = client((_) async => reply({
          'message': 'Проверьте поля',
          'details': jsonEncode({'startTime': 'Укажите время'})
        }, 422));
    await expectLater(
        guard(() => dio.post<dynamic>('/bookings')),
        throwsA(isA<ValidationException>()
            .having((e) => e.errors['startTime'], 'field', 'Укажите время')));
  });
  test('PostgREST 409 сохраняет объяснение конфликта', () async {
    final dio = client((_) async => reply({'message': 'Зал занят'}, 409));
    await expectLater(
        guard(() => dio.delete<dynamic>('/halls/1')),
        throwsA(isA<ConflictException>()
            .having((e) => e.message, 'message', 'Зал занят')));
  });
  test('401 обновляет JWT, не оборачивая RPC повторно', () async {
    var token = 'old';
    var calls = 0;
    final dio = client(
        (o) async {
          calls++;
          final args = o.data as Map;
          expect(args['endpoint'], '/halls');
          if (calls == 1) return reply({'message': 'expired'}, 401);
          expect(o.headers['Authorization'], 'Bearer new');
          return reply({'items': []});
        },
        token: () => token,
        refresh: () async {
          token = 'new';
          return true;
        });
    await dio.get<dynamic>('/halls');
    expect(calls, 2);
  });
  test('условия нового списка восстанавливаются из URL', () {
    final q = StudioQuery.fromUri(
        Uri.parse('/payments?amountFrom=100&page=2&sort=amount,desc'));
    expect(q.page, 2);
    expect(
        Uri.parse(
                q.change({'page': '1', 'search': 'Иван'}).location('payments'))
            .queryParameters,
        {
          'amountFrom': '100',
          'page': '1',
          'sort': 'amount,desc',
          'search': 'Иван'
        });
  });
  test('новые разделы защищены от клиента и менеджера', () {
    expect(
        isRouteAllowed('/payments', const Permissions(UserRole.client)), false);
    expect(isRouteAllowed('/services/new', const Permissions(UserRole.manager)),
        false);
    expect(
        isRouteAllowed(
            '/subscriptions/new', const Permissions(UserRole.manager)),
        true);
  });
  test('бронирование читает время PostgreSQL и итоговую стоимость', () {
    final b = Booking.fromJson({
      'startTime': '13:30:00',
      'totalPrice': '6100.00',
      'serviceIds': [1]
    });
    expect(b.startTime, '13:30');
    expect(b.totalPrice, 6100);
    expect(b.serviceIds, [1]);
    expect(Booking.fromJson({'startTime': ''}).startTime, '10:00');
  });
  testWidgets('новый список показывает загрузку', (tester) async {
    final pending = Completer<ResponseBody>();
    await mount(
        tester,
        const StudioRecordsScreen(entity: 'services', query: StudioQuery({})),
        client((_) => pending.future));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(reply({'items': [], 'total': 0}));
    await tester.pumpAndSettle();
  });
  testWidgets('новый список показывает пустой результат', (tester) async {
    await mount(
        tester,
        const StudioRecordsScreen(entity: 'services', query: StudioQuery({})),
        client((_) async => reply({'items': [], 'total': 0})));
    await tester.pumpAndSettle();
    expect(find.text('Записи не найдены'), findsOneWidget);
  });
  testWidgets('новый список показывает серверную ошибку', (tester) async {
    await mount(
        tester,
        const StudioRecordsScreen(entity: 'services', query: StudioQuery({})),
        client((_) async => reply({'message': 'Тестовая ошибка'}, 409)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Тестовая ошибка'), findsOneWidget);
  });
  testWidgets(
      'список услуг помещается в 360 пикселей и скрывает изменение от клиента',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(
        tester,
        const StudioRecordsScreen(entity: 'services', query: StudioQuery({})),
        client((_) async => reply({
              'items': [
                {'id': 1, 'name': 'Ретушь', 'price': 1500, 'category': 'Фото'}
              ],
              'total': 1,
              'page': 1,
              'size': 10,
              'totalPages': 1
            })),
        role: 'client');
    await tester.pumpAndSettle();
    expect(find.text('Ретушь'), findsOneWidget);
    expect(find.byTooltip('Редактировать'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('пустая услуга не отправляется на сервер', (tester) async {
    var calls = 0;
    await mount(tester, const StudioRecordFormScreen(entity: 'services'),
        client((_) async {
      calls++;
      return reply({});
    }));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Сохранить'));
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.textContaining('Минимум'), findsWidgets);
  });
}
