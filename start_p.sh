#! /bin/bash
unicorn -c /home/seijiro/sinatra/photodb/unicorn_p.conf --env production -D
echo "waiting..."
sleep 5
ps ax|grep unicorn

