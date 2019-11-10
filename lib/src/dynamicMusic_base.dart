import 'dart:html';
import 'dart:web_audio';
import 'dart:math';

class DynamicSong {
  AudioContext context;
  List<SongVariant> variants;
  int activeSong;

  bool playingRequested = false;

  int numSongs;
  int loadedSongs;
  DynamicSong(List<String> urls) {
    context = new AudioContext();
    numSongs = urls.length;
    variants = new List<SongVariant>(numSongs);
    for(int i = 0; i < numSongs; i++) {
      variants[i] = new SongVariant();
    }
    loadedSongs = 0;
    for(int i = 0; i < numSongs; i++) {
      loadSound(urls[i], i);
    }
    activeSong = 0; //todo make this modifiable
  }

  //todo clean this up
  void start() {
    for(int i = 0; i < variants.length; i++) {
      AudioBufferSourceNode source = context.createBufferSource();
      source.buffer = variants[i].buffer;
      source.loop = true;
      GainNode gain = context.createGain();
      source.connectNode(gain);
      gain.connectNode(context.destination);
      if(activeSong == i) {
        gain.gain.value = 1.0;
      } else {
        gain.gain.value = 0.0;
      }
      variants[i].sourceNode = source;
      variants[i].gainNode = gain;
    }

    for(int i = 0; i < variants.length; i++) {
      variants[i].sourceNode.start(0);
    }
  }

  void loadSound(String url, int index) {
    HttpRequest request = new HttpRequest();
    request.open("GET", url, async: true);
    request.responseType = 'arraybuffer';
    request.onLoad.listen((e) => requestOnLoad(request, url, index));
    request.send();
  }

  void requestOnLoad(HttpRequest request, String url, int index) {
    context.decodeAudioData(request.response).then((AudioBuffer buffer) {
      variants[index].buffer = buffer;
      loadedSongs++;
      if(loadedSongs >= numSongs && playingRequested) {
        start();
      }
    });
  }


  void startWhenReady() {
    if(loadedSongs >= numSongs) {
      start();
    } else {
      playingRequested = true;
    }
  }


  int fadeTime = 5; //todo make this somethign modifiable
  int fadePrecision = 20; //not sure if i need this but fgood to have. todo reevealuate this
  void swapSong(int newIndex) {
    var currTime = context.currentTime;
    variants[activeSong].gainNode.gain.setValueCurveAtTime(valueCurveArray(false, fadePrecision), currTime, fadeTime);
    variants[newIndex].gainNode.gain.setValueCurveAtTime(valueCurveArray(true, fadePrecision), currTime, fadeTime);

    activeSong = newIndex;
  }
}

class SongVariant {
  AudioBuffer buffer;
  AudioBufferSourceNode sourceNode;
  GainNode gainNode;

  SongVariant() {
    buffer = null;
    sourceNode = null;
    gainNode = null;
  }

}

double crossfadeDown(double value, double max) {
  double prog = value / max;
  return cos(prog * 0.5 * pi);
}

double crossfadeUp(double value, double max) {
  double prog = value / max;
  return cos((1.0 - prog) * 0.5 * pi);
}

List<double> valueCurveArray(bool up, int numSegments) {
  List<double> ret = List<double>(numSegments);
  for(int i = 0; i < numSegments; i++) {
    if(up) {
      ret[i] = crossfadeUp(i.toDouble(), numSegments.toDouble());
    } else {
      ret[i] = crossfadeDown(i.toDouble(), numSegments.toDouble());
    }
  }

  //gotta make sure it ends on the right value
  if(up) {
    ret[numSegments - 1] = 1;
  }  else {
    ret[numSegments - 1] = 0;
  }

  /*
  print("value curve array");
  for(int i = 0; i < numSegments; i++) {
    print(ret[i]);
  }*/

  return ret;
}