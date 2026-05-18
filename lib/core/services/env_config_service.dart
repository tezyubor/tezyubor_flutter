import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart';

const _kServerKey = 'env_use_dev_server';
const _kEnvKey = 'env_environment';

enum AppEnvironment { app, admin }

enum AppServer { prod, dev }

class EnvConfig {
  final AppServer server;
  final AppEnvironment environment;

  const EnvConfig({
    this.server = AppServer.prod,
    this.environment = AppEnvironment.app,
  });

  String get serverLabel => server == AppServer.prod ? 'Prod Server' : 'Dev Server';
  String get envLabel => environment == AppEnvironment.app ? 'app' : 'admin';
  String get apiUrl => server == AppServer.prod ? AppConstants.baseUrl : AppConstants.devBaseUrl;

  EnvConfig copyWith({AppServer? server, AppEnvironment? environment}) => EnvConfig(
        server: server ?? this.server,
        environment: environment ?? this.environment,
      );
}

class EnvConfigNotifier extends Notifier<EnvConfig> {
  @override
  EnvConfig build() {
    _load();
    return const EnvConfig();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final useDev = prefs.getBool(_kServerKey) ?? false;
    final envIndex = prefs.getInt(_kEnvKey) ?? 0;
    state = EnvConfig(
      server: useDev ? AppServer.dev : AppServer.prod,
      environment: AppEnvironment.values[envIndex],
    );
  }

  Future<void> toggleServer() async {
    final newServer = state.server == AppServer.prod ? AppServer.dev : AppServer.prod;
    state = state.copyWith(server: newServer);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kServerKey, newServer == AppServer.dev);
    ApiClient.instance.updateBaseUrl(state.apiUrl);
  }

  Future<void> toggleEnvironment() async {
    final newEnv = state.environment == AppEnvironment.app
        ? AppEnvironment.admin
        : AppEnvironment.app;
    state = state.copyWith(environment: newEnv);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kEnvKey, newEnv.index);
  }
}

final envConfigProvider = NotifierProvider<EnvConfigNotifier, EnvConfig>(
  EnvConfigNotifier.new,
);
