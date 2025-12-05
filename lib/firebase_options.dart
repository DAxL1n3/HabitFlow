
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBq8VS27FZ7d-JQYELIWRsRipHnqpXcgfE',
    appId: '1:539734119507:web:2b6d2929db2acaec0ea2a6',
    messagingSenderId: '539734119507',
    projectId: 'habitflow-app-dc84f',
    authDomain: 'habitflow-app-dc84f.firebaseapp.com',
    storageBucket: 'habitflow-app-dc84f.firebasestorage.app',
    measurementId: 'G-19R1E95B85',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDaeDMjVWNzbfGcnSpDtVD7Qahc74VMTqI',
    appId: '1:539734119507:android:b0cfc49a0ae2e9a10ea2a6',
    messagingSenderId: '539734119507',
    projectId: 'habitflow-app-dc84f',
    storageBucket: 'habitflow-app-dc84f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCWSnaUZKzxD4aE4sMA_4WFAI8JHNhRCFc',
    appId: '1:539734119507:ios:ca9f7652629c98630ea2a6',
    messagingSenderId: '539734119507',
    projectId: 'habitflow-app-dc84f',
    storageBucket: 'habitflow-app-dc84f.firebasestorage.app',
    androidClientId: '539734119507-v02e1u78crii5ge0e1uhrapjdj08r5ob.apps.googleusercontent.com',
    iosClientId: '539734119507-013q16qa993al83o3ohm93i4abod665b.apps.googleusercontent.com',
    iosBundleId: 'com.example.dalFlutter',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCWSnaUZKzxD4aE4sMA_4WFAI8JHNhRCFc',
    appId: '1:539734119507:ios:ca9f7652629c98630ea2a6',
    messagingSenderId: '539734119507',
    projectId: 'habitflow-app-dc84f',
    storageBucket: 'habitflow-app-dc84f.firebasestorage.app',
    androidClientId: '539734119507-v02e1u78crii5ge0e1uhrapjdj08r5ob.apps.googleusercontent.com',
    iosClientId: '539734119507-013q16qa993al83o3ohm93i4abod665b.apps.googleusercontent.com',
    iosBundleId: 'com.example.dalFlutter',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBq8VS27FZ7d-JQYELIWRsRipHnqpXcgfE',
    appId: '1:539734119507:web:a5a52a4f5e218e440ea2a6',
    messagingSenderId: '539734119507',
    projectId: 'habitflow-app-dc84f',
    authDomain: 'habitflow-app-dc84f.firebaseapp.com',
    storageBucket: 'habitflow-app-dc84f.firebasestorage.app',
    measurementId: 'G-91KRMJRGVE',
  );

}