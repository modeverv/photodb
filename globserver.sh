#!/bin/bash

cd /home/seijiro/sinatra/photodb
export PATH="/home/seijiro/.rvm/bin:$PATH" # Add RVM to PATH for scripting
#source /home/seijiro/.rvm/environments/ruby-1.9.3-p392
source /home/seijiro/.rvm/environments/ruby-1.9.3-p551
# bundle exec ruby ./update_server.rb
bundle exec ruby ./glob_server.rb
