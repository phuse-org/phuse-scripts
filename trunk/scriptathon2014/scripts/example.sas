filename source url "http://phuse-scripts.googlecode.com/svn/trunk/scriptathon2014/data/example.xpt" ;
libname source xport ;
data work.example ;
  set source.example ;
run ;
