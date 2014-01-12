#! /bin/bash
PID=`cat tmp/pids/unicorn_p.pid`
echo $PID
kill -QUIT $PID
sleep 5
ps ax|grep unicorn
