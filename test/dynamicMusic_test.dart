import 'package:dynamicMusic/dynamicMusic.dart';
import 'package:test/test.dart';

void main() {
  DynamicAudio audio = new DynamicAudio();
  audio.addSong("Ant_Farm_Test_1.mp3");
  audio.playAll();
}
