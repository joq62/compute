#!/bin/bash
/lib/erlang/bin/erl -pa compute/ebin -sname compute -setcookie cookie -detached -config logger -run compute boot
