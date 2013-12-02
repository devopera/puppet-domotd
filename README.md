puppet-domotd
=============

Devopera puppet module for setting up a message of the day (motd)

How it works
------------

In CentOS, the message of the day lives in /etc/motd.  It is optionally updated from a template in /etc/motd.template by a script appended to /etc/rc.local.
In Ubuntu, the message of the day is typically composed from fragments in /etc/update-motd.d/*.  We therefore compose the motd in a temporary folder (/etc/puppet/tmp), optionally from a template in the same directory.  update-motd.d/15-devopera-motd then displays content from that temporary folder.

Changelog
---------

2013-09-28

  * rewritten for both CentOS and Ubuntu

2013-09-03

  * /etc/issue now dynamically generated from /etc/issue.template like motd.template

2013-05-08

  * Added /etc/issue message to show IP/MAC address before login

Copyright and License
---------------------

Copyright (C) 2012 Lightenna Ltd

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
