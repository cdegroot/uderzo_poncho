This directory contains the Erlang interface libraries and headers 
from OTP 20.2 on the RPi3, and some other dependencies:
* libnanovg.a, compiled on RPi3 from the submodule in uderzo
* libfreetype.a, grabbed from the Raspbian libfreetype6-dev package
* libpng.a, from the Raspbian libpng-dev package
This could/should be a custom system at some point, but for now
this is simpler to keep in sync.
