=====================
Perl MooseFS Bindings
=====================

When I first started using MooseFS, the only means of monitoring it was using
the included web interface. Unfortunately, this caused difficulty in using 3rd
party utilities to monitor the Moose, and provide things like alerts and
archived statistics. In speaking with a more advanced user, an API was already
in demand, but had not yet been produced. So I opened up the Python code for
the Web UI and started ripping off functionality from it, and putting it into
a stand-alone Python library.

It should be noted that I have done this with only a limited understanding of
both Python and MooseFS, and that large portions of the code in my library have
been taken directly from the Web UI that ships with MooseFS. Thankfully, the
GPL allows for this sort of thing, so long as I tell you where I got the code
from. You can download the most recent version of MooseFS from:

http://www.moosefs.org/

Having finished a rough, but working version of the Python API, I decided to 
make a Perl version as well. Many monitoring utilities are already written in 
Perl, and it will be much easier for programmers to use a pure-Perl 
implementation than to have to interface with the Python.

The Python repo is:

https://github.com/techhat/python-moosefs

The Perl repo is:

https://github.com/techhat/perl-moosefs



