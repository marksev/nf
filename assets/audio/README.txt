Wave Rider – Audio Assets
=========================

Place the following audio files in this directory, then uncomment
the FlameAudio calls in lib/game/wave_rider_game.dart (AudioHelper class)
and add the paths to the flutter > assets section of pubspec.yaml.

Required files:
  jump.mp3           – short whoosh/spring sound when the surfer jumps
  collision.mp3      – crash/splash sound on obstacle hit
  collect.mp3        – bright ding/chime when a coin is collected
  background_music.mp3 – looping ambient surf/beach music

Recommended free sources:
  - freesound.org
  - opengameart.org
  - zapsplat.com

Supported formats: .mp3, .ogg, .wav (flame_audio uses audioplayers internally)
