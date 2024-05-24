import 'package:ioc_container/ioc_container.dart';
import 'package:safety_eye_app/providers/providers.dart';
import 'package:safety_eye_app/repositories/repositories.dart';
import 'package:safety_eye_app/services/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text_provider.dart';

extension IocContainerBuilderExtension on IocContainerBuilder {
  void addProviders() {
    this
      ..addSingleton<AuthenticationProvider>(
          (container) => AuthenticationProvider(container.get<AuthService>()))
      ..addSingleton<PermissionsProvider>((container) => PermissionsProvider())
      ..addSingleton<SensorsProvider>((container) => SensorsProvider())
      ..addSingleton<SettingsProvider>((container) => SettingsProvider(container.get<PreferencesService>()))
      ..addSingleton<SpeechToTextProvider>((container) => SpeechToTextProvider(SpeechToText()))

      ..add<VideoRecordingProvider>((container) {
        final authProvider = container.get<AuthenticationProvider>();
        final fileSystemRepo = container.get<FileSystemRepository>();
        final sensorsProvider = container.get<SensorsProvider>();
        final permissionsProvider = container.get<PermissionsProvider>();
        final settingProvider = container.get<SettingsProvider>();
        final chunkProcessorService = container.get<ChunkProcessorService>();
        return VideoRecordingProvider(
            authenticationProvider: authProvider,
            fileSystemRepository: fileSystemRepo,
            sensorsProvider: sensorsProvider,
            permissions: permissionsProvider,
            settingsProvider: settingProvider,chunkProcessorService:chunkProcessorService);
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
        final signaturesProvider = container.get<SignaturesProvider>();
        return ChunksProvider(
            authenticationProvider: authProvider,
            backendService: backend,
            fileSystemRepository: fileSystemRepo,signaturesProvider: signaturesProvider);
      })
      ..addSingleton<SignaturesProvider>((container) => SignaturesProvider(
          container.get<AuthenticationProvider>(),
          container.get<SignaturesService>()));
  }

  void addServices() {
    this
      ..addSingleton<AuthService>((container) => AuthService())
      ..addSingleton<ChunkProcessorService>((container) {
        final fileSystemRepo = container.get<FileSystemRepository>();
        final signaturesProvider = container.get<SignaturesProvider>();
        return ChunkProcessorService(fileSystemRepository: fileSystemRepo, signaturesProvider: signaturesProvider );})
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
