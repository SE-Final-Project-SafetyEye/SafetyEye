import 'package:ioc_container/ioc_container.dart';
import 'package:safety_eye_app/providers/providers.dart';
import 'package:safety_eye_app/repositories/repositories.dart';
import 'package:safety_eye_app/services/services.dart';

extension IocContainerBuilderExtension on IocContainerBuilder {
  void addProviders() {
    this
      ..addSingleton<AuthenticationProvider>(
          (container) => AuthenticationProvider(container.get<AuthService>()))
      ..addSingleton<PermissionsProvider>((container) => PermissionsProvider())
      ..addSingleton<SensorsProvider>((container) => SensorsProvider())
      ..addSingleton<SettingsProvider>(
          (container) => SettingsProvider(container.get<PreferencesService>()))
      ..add<VideoRecordingProvider>((container) {
        final authProvider = container.get<AuthenticationProvider>();
        final fileSystemRepo = container.get<FileSystemRepository>();
        final sensorsProvider = container.get<SensorsProvider>();
        final permissionsProvider = container.get<PermissionsProvider>();
        final settingProvider = container.get<SettingsProvider>();
        return VideoRecordingProvider(
            authenticationProvider: authProvider,
            fileSystemRepository: fileSystemRepo,
            sensorsProvider: sensorsProvider,
            permissions: permissionsProvider,
            settingsProvider: settingProvider);
      })
      ..add<JourneysProvider>((container) {
        final authProvider = container.get<AuthenticationProvider>();
        final fileSystemRepo = container.get<FileSystemRepository>();
        final backend = container.get<BackendService>();
        return JourneysProvider(
            authenticationProvider: authProvider,
            fileSystemRepository: fileSystemRepo,
            backendService: backend);
      })
      ..addSingleton<SpeechProvider>((container) => SpeechProvider())
      ..add<ChunksProvider>((container) {
        final fileSystemRepo = container.get<FileSystemRepository>();
        final authProvider = container.get<AuthenticationProvider>();
        final backend = container.get<BackendService>();
        return ChunksProvider(
            authenticationProvider: authProvider,
            backendService: backend,
            fileSystemRepository: fileSystemRepo);
      })
      ..addSingleton<SignaturesProvider>((container) => SignaturesProvider(
          container.get<AuthenticationProvider>(),
          container.get<SignaturesService>()));
  }

  void addServices() {
    this
      ..addSingleton<AuthService>((container) => AuthService())
      ..addSingleton<SignaturesService>((container){
        final backend = container.get<BackendService>();
        return SignaturesService(backendService: backend);})
      ..addSingletonAsync<SettingsProvider>((container) async =>
          await SettingsProvider(container.get<PreferencesService>()).init())
      ..add<BackendService>((container) {
        final fileSystemRepo = container.get<FileSystemRepository>();
        final authProvider = container.get<AuthenticationProvider>();
        return BackendService(authProvider, fileSystemRepo);
      })
      ..addSingleton<PreferencesService>((container) => PreferencesService());
  }

  void addRepositories() {
    this
      ..addSingletonAsync<SignaturesRepository>(
          (container) async => await SignaturesRepository().init())
      ..addSingleton<FileSystemRepository>((container) => FileSystemRepository(
          authProvider: container.get<AuthenticationProvider>()));
  }
}

IocContainer createIocContainer() {
  final iocBuilder = IocContainerBuilder()
    ..addServices()
    ..addProviders()
    ..addRepositories();

  return iocBuilder.toContainer();
}
