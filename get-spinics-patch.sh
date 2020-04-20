#!/bin/sh
wget "$1" -O - | \
sed -n '/<[p]re>/,/<\/pre\>/b next;b;:next;s@</*pre>@@;s@[&]gt;@>@g;s@[&]lt;@<@g;s@[&]quot;@"@g;s@[&]amp;@\&@g;p'
