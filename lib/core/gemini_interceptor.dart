import 'package:dio/dio.dart';
import 'api_manager.dart';

class GeminiFailoverInterceptor extends Interceptor {
  final ApiKeyManager keyManager;
  final Dio dio;

  GeminiFailoverInterceptor(this.keyManager, this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    
    // Catch Invalid Key (400), Forbidden (403), Quota Exceeded (429), or Server Error (500)
    if (statusCode == 400 || statusCode == 403 || statusCode == 429 || statusCode == 500) {
      
      print('⚠️ API Error ($statusCode) detected on key: ${keyManager.currentKey}');
      
      if (keyManager.rotateKey()) {
        print('🔄 Switched to next API Key: ${keyManager.currentKey}');
        
        final requestOptions = err.requestOptions;
        
        // Safely replace the broken key in the URL with the new working key
        final oldUrl = requestOptions.path;
        requestOptions.path = oldUrl.replaceAll(
          RegExp(r'key=[^&]*'), 
          'key=${keyManager.currentKey}'
        );

        try {
          // Retry the request with the new key!
          final response = await dio.fetch(requestOptions);
          return handler.resolve(response);
        } catch (e) {
          // If it fails again, it will loop back through this interceptor
          return handler.next(e as DioException);
        }
      } else {
        print('❌ All API keys in .env are exhausted or invalid.');
      }
    }
    
    // Pass the error along if it's a generic internet failure
    return handler.next(err);
  }
}