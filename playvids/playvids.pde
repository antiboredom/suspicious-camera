import processing.video.*;
import java.io.File;
import java.util.Arrays;
import java.util.Comparator;

int index = 0;
String[] filenames;
String PATH_TO_VIDEOS = "/Users/sam/Dropbox/school/spring_2014/surveillance/SuspiciousCamera/suspicious/data/";

float w, h;

Movie mov;

void setup() {
  imageMode(CENTER);
  size(displayWidth, displayHeight);
  background(0);
  getLatestFiles();
  nextMovie();
  
  w = width;
  h = 720 * w/1280;
}


void draw() {
  image(mov, width/2, height/2, w, h);
  if (mov.duration() - mov.time() <= .1) {
    nextMovie();
  }
}

void movieEvent(Movie m) {
  m.read();
}

void nextMovie() {
  if (mov != null) {
    mov.dispose();
    mov = null;
    System.gc();
  }
  mov = new Movie(this, filenames[index]);
  mov.play();
  getLatestFiles();
  index ++;
  if (index >= filenames.length) index = 0;
}

void getLatestFiles() {
  File dir = new File(PATH_TO_VIDEOS);
  File [] files  = dir.listFiles();
  Arrays.sort(files, new Comparator() {
    public int compare(Object o1, Object o2) {
      return compare( (File)o1, (File)o2);
    }
    private int compare( File f1, File f2) {
      long result = f2.lastModified() - f1.lastModified();
      if ( result > 0 ) {
        return 1;
      } 
      else if ( result < 0 ) {
        return -1;
      } 
      else {
        return 0;
      }
    }
  });
  
  
  ArrayList<String> temp = new ArrayList<String>();
  
  for (int i=0; i<20; i++) {
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

