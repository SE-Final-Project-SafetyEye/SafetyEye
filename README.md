# safety_eye_app

An app for hands free drive recorder with object detection and smart saving of empty drive.
data collected is signed by using public-private key encryption.

## Building App:
before running the app, the following commands need to be ran:
- `flutter pub get` - getting the missing dependencies
- `flutter pub run build_runner build` - creating auto generated classes from definition.
- `flutter pub run environment_config:generate --BACKEND_URL="<current_url_of_backend>"  <br/>
--"<more configuration vars to set>"`

## Running The App:
For running the app, connect a device or run an emulator.
- run the command `flutter run`
