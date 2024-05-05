

import 'package:flutter/foundation.dart';
import 'package:ioc_container/ioc_container.dart';
import 'package:safety_eye_app/ioc_container.dart';

class IocContainerProvider extends ChangeNotifier {
  final IocContainer _iocContainer = createIocContainer();

  IocContainer get container => _iocContainer;
}