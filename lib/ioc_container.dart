import 'package:ioc_container/ioc_container.dart';
import 'package:safety_eye_app/providers/providers.dart';
import 'package:safety_eye_app/repositories/repositories.dart';
import 'package:safety_eye_app/services/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text_provider.dart';

extension IocContainerBuilderExtension on IocContainerBuilder {
  void addProviders() {
    this
      ..addSingleton<AuthenticationProvider>((container) => AuthenticationProvider(container.get<AuthService>()))
      ..addSingleton<PermissionsProvider>((container) => PermissionsProvider())
      ..addSingleton<SensorsProvider>((container) => SensorsProvider())
      ..addSingleton<SettingsProvider>((container) => SettingsProvider(container.get<PreferencesService>()))
      ..addSingleton<SpeechToTextProvider>((container) => SpeechToTextProvider(SpeechToText()))
      ..add<VideoRecordingProvider>((container) {
        final authProvider = container.get<AuthenticationProvider>();
        final fileSystemRepo = container.get<FileSystemRepository>();
        final sensorsProvider = container.get<SensorsProvider>();
        final permissionsProvider = container.get<PermissionsProvider>();
        return VideoRecordingProvider(
            authenticationProvider: authProvider,
            fileSystemRepository: fileSystemRepo,
            sensorsProvider: sensorsProvider,
            permissions: permissionsProvider);
      })
      // ..addSingleton<SpeechProvider>((container) => SpeechProvider())
      ..addSingleton<SignaturesProvider>((container) =>
          SignaturesProvider(container.get<AuthenticationProvider>(), container.get<SignaturesService>()));
  }

  void addServices() {
    this
      ..addSingleton<AuthService>((container) => AuthService())
      ..addSingleton<SignaturesService>((container) => SignaturesService())
      ..addSingletonAsync<SettingsProvider>(
          (container) async => await SettingsProvider(container.get<PreferencesService>()).init())
      ..add<BackendService>((container) => BackendService(container.get<AuthenticationProvider>()))
      ..addSingleton<PreferencesService>((container) => PreferencesService());
  }

  void addRepositories() {
    this
      ..addSingletonAsync<SignaturesRepository>((container) async => await SignaturesRepository().init())
      ..addSingleton<FileSystemRepository>(
          (container) => FileSystemRepository(authProvider: container.get<AuthenticationProvider>()));
  }
}

IocContainer createIocContainer() {
  final iocBuilder = IocContainerBuilder()
    ..addServices()
    ..addProviders()
    ..addRepositories();

  return iocBuilder.toContainer();
}
