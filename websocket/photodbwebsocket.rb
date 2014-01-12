# /usr/bin/env ruby
# -*- coding:utf-8 -*-
require 'em-websocket'
require File.join(File.dirname(__FILE__), '..','/',)+"photomodels"
require 'cgi'
require 'kconv'

Process.daemon(nochdir=true) if ARGV[0] == "-D"

def api_dirs
  Mongoid.unit_of_work do
    rets = Dirmodel.all    
    if rets.first.nil?
      "error"
    else
      dirs = []
      rets.each do |dir|
        elem = {}
        elem[:_id] = dir.id;
        elem[:path] = dir.path;
        elem[:name] = "#{dir.name}(#{dir.models_count})"
        dirs << elem
      end
      ([{
          "method" => "api_dirs",
          "callback" => "callback_api_dirs",
        }
       ] + dirs).to_json.to_s
    end
  end
end

def api_dir(mid,ws)
  Mongoid.unit_of_work do
    ret = Dirmodel.where(:_id => mid).first
    
    medias = ret.photomodels.only(:exif,:thumb_s,:path,:name)
    if medias
      medias.each {|e|
        e.thumb_s = [e.thumb_s.to_s].pack('m')
        e.thumb_m = ""
        ws.send ([{
                    "method" => "api_dir_#{mid}_e_#{e.id}",
                    "callback" => "callback_api_dir_e",
                  }
                 ] + [e]).to_json.to_s
      }
    else
      ws.send "error #{mid}"
    end
  end
end

def api_search(querystring,ws)
  Mongoid.unit_of_work do
    query = CGI.unescape(querystring.toutf8).gsub('<OR>','|')
    qs = query.split(' ').map {|q| /#{q}/i}
    medias = Photomodel.where(:search.all => qs).limit(100).to_a
    
    #  medias = Photomodel.where(:search.all => qs).limit(100).to_a

    medias = medias.each {|e|
      e.thumb_s = [e.thumb_s.to_s].pack('m')
      e.thumb_m = ""
      
      ws.send ([{
                  "method" => "api_search_#{querystring}_e_#{e.id}",
                  "callback" => "callback_api_search_e",
                }] + [e]).to_json.to_s
    }
  end
end

EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8090, :debug => false) do |ws|
  ws.onopen { ws.send "Hello Client!"}
  ws.onmessage { |msg|
#    ws.send "Pong: #{msg}"
    
    # dispacher
    if msg =~ /get:dirs$/
      ws.send api_dirs 
    end
    if msg =~ /get:dir:(.+)$/
      api_dir $1,ws
    end
    if msg =~ /get:search:(.+)$/ #need escape querystring
      api_search $1,ws
    end
  }
  ws.onclose { puts "WebSocket closed" }
  ws.onerror { |e| puts "Error: #{e.message}" }
end
