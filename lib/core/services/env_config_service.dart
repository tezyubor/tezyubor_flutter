import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart';

const _kServerKey = 'env_use_dev_server';

enum AppServer { prod, dev }

class ServerConfig {
  final AppServer server;
  const ServerConfig({this.server = AppServer.prod});

  String get label => server == AppServer.prod ? 'Prod Server' : 'Dev Server';
  String get apiUrl => server == AppServer.prod ? AppConstants.baseUrl : AppConstants.devBaseUrl;
}

class ServerConfigNotifier extends Notifier<ServerConfig> {
  @override
  ServerConfig build() {
    _load();
    return const ServerConfig();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final useDev = prefs.getBool(_kServerKey) ?? false;
    state = ServerConfig(server: useDev ? AppServer.dev : AppServer.prod);
    ApiClient.instance.updateBaseUrl(state.apiUrl);
  }

  Future<void> toggle() async {
    final newServer = state.server == AppServer.prod ? AppServer.dev : AppServer.prod;
    state = ServerConfig(server: newServer);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kServerKey, newServer == AppServer.dev);
    ApiClient.instance.updateBaseUrl(state.apiUrl);
  }
}

final serverConfigProvider = NotifierProvider<ServerConfigNotifier, ServerConfig>(
  ServerConfigNotifier.new,
);
