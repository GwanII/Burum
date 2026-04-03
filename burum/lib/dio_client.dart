import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';
import 'auth_service.dart';

// 씨발 이게 무슨 말임? 개씨발 fuck fuck fuck dick asshole

class DioClient {
  late final Dio dio;
  final _storage = const FlutterSecureStorage();

  DioClient._() {
    dio = Dio(BaseOptions(baseUrl: Config.baseUrl));

    // 토큰 갱신 중 동시요청을 처리하기 위한 인터셉터 로직
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. 헤더에 Access Token 자동 주입
          final accessToken = await _storage.read(key: 'accessToken');
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // 401 에러이고, 서버에서 보낸 코드가 'TOKEN_EXPIRED'일 때
          if (e.response?.statusCode == 401 &&
              e.response?.data?['code'] == 'TOKEN_EXPIRED') {
            print('💡 Dio: 액세스 토큰 만료 감지! 백그라운드 재발급 시도 중...');

            try {
              // 2. 토큰 재발급 요청
              final newAccessToken = await _refreshToken();

              // 3. 재발급 성공 시, 원래 실패했던 요청을 새로운 토큰으로 재시도
              e.requestOptions.headers['Authorization'] =
                  'Bearer $newAccessToken';
              final response = await dio.fetch(e.requestOptions);
              print('🔄 Dio: 토큰 갱신 완료! 원래 요청을 재전송합니다.');
              return handler.resolve(response);
            } catch (refreshError) {
              // 4. 리프레시 토큰마저 만료되었을 때 (재발급 실패)
              print('🚨 Dio: 리프레시 토큰 만료. 강제 로그아웃 처리합니다.');
              await _handleLogout(); // 로그아웃 처리
              return handler.reject(e); // UI단에는 에러를 그대로 전달
            }
          }
          // 그 외 모든 에러는 그대로 전달
          return handler.next(e);
        },
      ),
    );
  }

  // Singleton 패턴으로 앱 어디서든 dio 인스턴스에 접근
  static final DioClient _instance = DioClient._();
  static Dio get instance => _instance.dio;

  // 토큰 재발급 로직
  Future<String?> _refreshToken() async {
    final refreshToken = await _storage.read(key: 'refreshToken');
    if (refreshToken == null) throw Exception('No refresh token');

    // 인터셉터를 타지 않는 별도의 Dio 인스턴스를 사용해야 무한 루프를 방지할 수 있음
    final refreshDio = Dio(BaseOptions(baseUrl: Config.baseUrl));
    final response = await refreshDio.post(
      '/api/users/refresh',
      data: {'refreshToken': refreshToken},
    );

    if (response.statusCode == 200) {
      final newAccessToken = response.data['accessToken'];
      await _storage.write(key: 'accessToken', value: newAccessToken);
      await _storage.write(
        key: 'refreshToken',
        value: response.data['refreshToken'],
      );

      return newAccessToken;
    } else {
      throw Exception('Failed to refresh token');
    }
  }

  // 전역 로그아웃 처리
  Future<void> _handleLogout() async {
    await _storage.deleteAll(); // 저장된 토큰 삭제
    // 🌟 UI 계층에 직접 관여하는 대신, 인증 상태가 변경되었음을 알림
    AuthService.instance.notifyAuthStatus(AuthStatus.unauthenticated);
  }
}
