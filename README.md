# photodb
view photos

## config
at `main.rb`,change `USERNAME`,`PASS`  
at `globmodel.rb` change `@server`

## install

    bundle install

## passenger or unicorn
deply by passenger or unicorn
   
## cron

    0 9 * * * /home/path/to/photodb/globserver.sh >> /home/path/to/photodb/globserver.log 2>&1
