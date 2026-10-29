import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../core/config.dart';
import '../state/session.dart';

class SupabaseAuthRepository extends AuthRepository {
  SupabaseAuthRepository(this.dataDio, {required this.accessToken})
      : authDio = Dio(BaseOptions(
          baseUrl: '$supabaseUrl/auth/v1',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'apikey': supabasePublishableKey},
          validateStatus: (_) => true,
        )),
        super(dataDio);
  final Dio dataDio;
  final Dio authDio;
  final String? Function() accessToken;
  String? _lastAccessToken;

  Future<Map<String, dynamic>> _request(String path,
      {Map<String, dynamic>? data, String? token}) async {
    final response = await guard(() => authDio.post<Map<String, dynamic>>(
          path,
          data: data,
          options: Options(headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          }),
        ));
    final body = response.data ?? {};
    final status = response.statusCode ?? 500;
    if (status >= 400) {
      final error = body['error_code'] ?? body['code'];
      if (error == 'email_not_confirmed') {
        throw const UnauthorizedException(
            'Подтвердите почту по ссылке из письма, затем войдите.');
      }
      if (status == 429) {
        throw const NetworkException(
            'Слишком много попыток. Попробуйте позже.');
      }
      if (path.startsWith('/token')) {
        throw const UnauthorizedException('Неверная почта или пароль.');
      }
      throw ValidationException(
          body['msg']?.toString() ??
              body['message']?.toString() ??
              'Не удалось создать аккаунт.',
          {
            if (error == 'user_already_exists')
              'email': 'Почта уже зарегистрирована'
          });
    }
    return body;
  }

  Future<AuthTokens> _tokens(Map<String, dynamic> data) async {
    final token = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    if (token == null || refresh == null) {
      throw const UnauthorizedException('Подтвердите почту, затем войдите.');
    }
    _lastAccessToken = token;
    // Read profile with the newly issued JWT, before SessionStore adopts it.
    final response = await guard(() => authDio.post<Map<String, dynamic>>(
        '$supabaseUrl/rest/v1/rpc/studio_api',
        data: {'endpoint': '/auth/me'},
        options: Options(headers: {'Authorization': 'Bearer $token'})));
    if (response.statusCode != 200) {
      throw const UnauthorizedException(
          'Профиль недоступен. Проверьте настройку базы.');
    }
    return (
      accessToken: token,
      refreshToken: refresh,
      user: AppUser.fromJson(response.data ?? {})
    );
  }

  @override
  Future<AuthTokens> login(String username, String password) async {
    final email =
        username.contains('@') ? username : '$username@focusframe.local';
    return _tokens(await _request('/token?grant_type=password',
        data: {'email': email.trim(), 'password': password}));
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async =>
      _tokens(await _request('/token?grant_type=refresh_token',
          data: {'refresh_token': refreshToken}));

  @override
  Future<void> register(
      {required String username,
      required String password,
      required String fullName,
      required String email}) async {
    await _request('/signup', data: {
      'email': email,
      'password': password,
      'data': {'username': username, 'fullName': fullName},
    });
  }

  @override
  Future<AppUser> me() async {
    final response =
        await guard(() => dataDio.get<Map<String, dynamic>>('/auth/me'));
    return AppUser.fromJson(response.data ?? {});
  }

  @override
  Future<void> logout(String? refreshToken) async {
    final token = accessToken() ?? _lastAccessToken;
    if (token != null) await _request('/logout?scope=local', token: token);
    _lastAccessToken = null;
  }
}
