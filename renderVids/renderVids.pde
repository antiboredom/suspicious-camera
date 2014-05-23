import processing.video.*;
import java.io.File;
import java.util.Arrays;
import java.util.Comparator;

Combo mvs;
PApplet applet = this;
boolean playing = true;
int index = 0;
String[] filenames;

void setup() {
  frameRate(25);
  imageMode(CENTER);
  //size(1280, 720);
  size(displayWidth, displayHeight);
  background(0);
  getLatestFiles();
  newMvs();
}

void draw() {
  mvs.display();
  if (frameCount % 170 == 0) {
    newMvs();
  }
}

void movieEvent(Movie m) {
  m.read();
}

void newMvs() {
  mvs = new Combo(filenames[index], filenames[index], filenames[index], filenames[index], filenames[index]);
  //mvs = new Combo(filenames[index]);
  getLatestFiles();
  index ++;
  if (index >= filenames.length) index = 0;
}

HashMap<String, Float> oldParams = new HashMap<String, Float>();
int startClick = 0;
int endClick = 0;
int lastClick = 0;


class Mov {
  Movie m;

  String path;
  float duration;

  Mov(String _path, PApplet applet) {
    path = _path;
    m = new Movie(applet, path);
    duration = m.duration();
  }

  void play() {
    m.play();
  }

  void loop() {
    m.loop();
  }

  void stop() {
    m.stop();
  }

  void pause() {
    m.pause();
  }

  void speed(float s) {
    m.speed(s);
  }
}

class Combo {
  Mov[] movies;
  int index=0, lastIndex=0;
  int startTime, timeSinceStart, lastSwitched = 0;
  HashMap<String, Float> params = new HashMap<String, Float>();
  ArrayList<Timer> timing = new ArrayList<Timer>();
  boolean shouldPause = true;

  Combo(String... paths) {
    movies = new Mov[paths.length];
    for (int i = 0; i < paths.length; i++) {
      movies[i] = new Mov(paths[i], applet);
    }
    //    movies[1].m.volume(0);
    startTime = millis();
    lastSwitched = startTime;
    params.put("alpha", 255.0);
    params.put("balance", 255.0);
    params.put("interval", random(1, 5.0));
  }

  void switchAt(int millisecs) {
    switchAt(float(millisecs));
  }

  void switchAt(float millisecs) {
    params.put("interval", millisecs);
  }

  void addTransition(String var, float val, int timestamp, int duration) {
    timing.add(new Timer(var, val, timestamp, duration));
    //eval(var + "=" val + ";");
  }

  void update() {
    timeSinceStart = millis() - startTime;
    for (Timer t : timing) {
      if (timeSinceStart > t.timestamp && timeSinceStart < t.timestamp + t.duration) {
        if (!t.running) t.start(params.get(t.var));
        params.put(t.var, t.update(timeSinceStart));
      }
    }

    if (mousePressed) {
      params.put("interval", map(mouseX, 0, width, 1, 5000));
      params.put("alpha", map(mouseY, 0, height, 1, 255));
    }

    if (playing && millis() - lastSwitched > params.get("interval")) {
      lastSwitched = millis();
      lastIndex = index;
      if (shouldPause) movies[index].pause();

      index ++;
      if (index > movies.length - 1) index = 0; 
      movies[index].loop();
    }
  }

  void display() {
    update();
    image(movies[lastIndex].m, width/2, height/2);
    tint(params.get("balance"), params.get("alpha"));
    image(movies[index].m, width/2, height/2);
    //text("alpha: " + params.get("alpha"), 20, 20); 
    //text("interval: " + params.get("interval"), 20, 40); 
    //text("time: " + timeSinceStart, 20, 60);
  }
}

class Timer {
  String var;
  float val, oldVal;
  int timestamp, duration;
  boolean running = false;

  Timer(String _var, float _val, int _timestamp, int _duration) {
    var = _var;
    val = _val;
    timestamp = _timestamp;
    duration = _duration;
  }

  void start(float _oldVal) {
    oldVal = _oldVal;
    running = true;
  }

  void stop() {
    running = false;
  }

  float update(int startedAt) {
    float currentVal = map(startedAt - timestamp, 0, duration, oldVal, val);
    if (oldVal < val) currentVal = constrain(currentVal, oldVal, val);
    else currentVal = constrain(currentVal, val, oldVal);
    return  currentVal;
  }
}

void getLatestFiles() {
  File dir = new File("/Users/sam/Dropbox/school/spring_2014/surveillance/SuspiciousCamera/suspicious/data/videos");
  File [] files  = dir.listFiles();
  Arrays.sort(files, new Comparator() {
    public int compare(Object o1, Object o2) {
      return compare( (File)o1, (File)o2);
    }
    private int compare( File f1, File f2) {
      long result = f2.lastModified() - f1.lastModified();
      if ( result > 0 ) {
        return -1;
      } 
      else if ( result < 0 ) {
        return 1;
      } 
      else {
        return 0;
      }
    }
  });
  
  
  ArrayList<String> temp = new ArrayList<String>();
  
  for (int i=0; i<files.length; i++) {
    String fname = files[i].getAbsolutePath();
    if (fname.indexOf(".mp4") > 0) {
      temp.add(fname);
    }
  }
  
  filenames = new String[temp.size()];
  for (int i=0; i < temp.size(); i ++) {
    filenames[i] = temp.get(i);  
  }

}

