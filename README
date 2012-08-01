AutoIt_Code-Snippets
====================

My collection of AutoIt scripts. 

Remarks:
    My AutoIt coding style is a little obtuse, but I
  think it's a change for the better. 

    I like to make really heavy use of the function Call()
  and I use it like you'd normally use a function pointer.

    I also like very long variable names. It's something I
  picked up from coding so much Objective-C. As a general
  rule of thumb, the more complex the code is, the longer
  my variable names are going to be. 

__FILE.au3:
    This is a function library that includes a bunch of
  miscellaneous functions that are used for well -- you
  guess it -- file operations. 
  
  The most important thing to note about this library is
  the function __FILE__RECURSIVE__COPY() and __FILE__LIST(),
  both of them are quite massive.

    __FILE__RECURSIVE__COPY() is a function that performs a
  recursive file copy operation given a source path and a
  destination path and a bunch of callback functions. It's
  really designed with GUI in mind, but doesn't have one single
  inkling of GUI code embedded in it. It makes very heavy use
  of the Call() function.

    __FILE__LIST() is a function that performs a recursive
  directory listing. __FILE__RECURSIVE__COPY() is nothing
  but a big wrapper to parse the output of __FILE__LIST().

__DROPBOX.au3
    I like Dropbox, a lot... So much so that I started to
  write functions that communicate with each other through it,
  because I got tired of doing socket programming...

    This function library is based all on the central idea of
  network communication being like a radio channel. A function
  can subscribe, unsubscribe, and work with this structure I
  call a "channel." 

    The best part about it is that it's all file manipulation,
  and so everything is implemented through files. 

    This libarary isn't production code yet, but it's very close
  to it, and I'm hoping that I can get another pair of eyes to
  look at it. 

    For now, my scripts that communicate through dropbox are just
  writing files to and from one another, but very soon they will
  use this library. 

    If anything, it's just neat. 
