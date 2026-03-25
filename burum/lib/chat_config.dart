//채팅 목록 조회하는 디폴트 유저 번호를 정하는 파일입니다. 
import 'package:flutter/foundation.dart';

const int kCurrentUserId = 7;

String get kBaseUrl {
  if (kIsWeb) {
    return 'http://localhost:3000';
  } else {
    return 'http://10.0.2.2:3000';
  }
}