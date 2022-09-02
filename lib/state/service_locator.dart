import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:subsound/state/player_task.dart';
import 'package:subsound/state/playerstate.dart';

GetIt  getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  getIt.registerSingleton<AudioHandler>(await initAudioService());
  getIt.registerLazySingleton<PlayerManager>(() => PlayerManager());
}