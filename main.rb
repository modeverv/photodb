#! /usr/bin/env ruby
# -*- coding:utf-8 -*-
require 'sinatra'
#require "sinatra/reloader" #if development?
require File.dirname(__FILE__)+'/photomodels'
require File.dirname(__FILE__)+'/globmodel'

require 'will_paginate'

USERNAME = "user"
PASS = "hoge"

### helper ##################
# need modify via environment 
helpers do
  def make_path(path)
    #  path.gsub('/var','/Volumes')
    path
  end
  
  def search1(query)
    puts "obsolete"
    qs = query.gsub('<OR>','|').split(' ').map {|q| /#{q.downcase}/i}
    rets = Photomodel.where(:search.all => qs).only(:id,:name,:path,:thumb_s).limit(100);
  end

  def recent(query)
    puts "obsolete"
    status = {:page => 1,:total => 200,:next => "no",:prev => "no",:qs => query}
    rets = Photomodel.desc(:created_at).limit(50).only(:name,:path,:thumb_s).to_a
    [status,rets]
  end

  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="photodb Restricted Area")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [USERNAME, PASS]
  end

  def type(path)
    type = File.extname(path).gsub('.','')
    if type == "jpg" || type == "JPG"
      type = "jpeg"
    end
    type  
  end
  
end

### page ####################
get '/' do
  protected!
  expires 36000 ,:public
  cache_control :public, 36000
  
  @config = "sinatra"
  erb :index
end

get '/photodb' do
  protected!
  expires 36000 ,:public
  cache_control :public, 36000
  
  @config = "sinatra"
  erb :index
end

get '/websocket' do
  @config = "websocket"
  erb :index
end

get '/image/full/:mid' do
  expires 36000 ,:public
  cache_control :public, 36000
  
  ret = []
  ret << "<html><body><style>*{margin:0;padding:0;color:#fff;background:#111;}</style>"
  ret << "<img src='/photodb/api/image/full/#{params['mid']}' alt='img' width='100%' />"
  ret << "<body></html>"
  ret.join('')
end

get '/photodb/image/full/:mid' do
  expires 36000 ,:public
  cache_control :public, 36000
  
  ret = []
  ret << "<html><body><style>*{margin:0;padding:0;color:#fff;background:#111;}</style>"
  ret << "<img src='/photodb/api/image/full/#{params['mid']}' alt='img' width='100%' />"
  ret << "<body></html>"
  ret.join('')
end

get '/photodb/image/full2/:mid' do
  expires 36000 ,:public
  cache_control :public, 36000
  
  ret = Photomodel.where(:_id => params['mid']).only(:path,:name).first
  if ret.nil?
    "error"
  else
    path = make_path(ret.path)
    buf = [ File.open(path,'rb').read ].pack('m')
    html = []
    html << "<html><title>#{ret.name.to_s}</title><body>"
    html << "<img src='data:image/jpeg;base64,#{buf}' alt='img' width='100%' />"
    html << "</body></html>"
    html.join('')
  end

end

get '/image/full2/:mid' do
  expires 36000 ,:public
  cache_control :public, 36000
  
  ret = Photomodel.where(:_id => params['mid']).only(:path,:name).first
  if ret.nil?
    "error"
  else
    path = make_path(ret.path)
    buf = [ File.open(path,'rb').read ].pack('m')
    html = []
    html << "<html><title>#{ret.name.to_s}</title><body>"
    html << "<img src='data:image/jpeg;base64,#{buf}' alt='img' width='100%' />"
    html << "</body></html>"
    html.join('')
  end

end



##########  manage  ###########################################
get '/manage' do
  protected!
  ret = ["<h1>manage</h1>"]
  place_folder = "<li><a href='#href#' target='_blank'>#link#</a>"
  ret << place_folder.gsub("#href#","/photodb/manage/update_tag").gsub("#link#",'update_tag')
  ret << place_folder.gsub("#href#","/photodb/manage/update_thumb_m").gsub("#link#",'update_thumb_m')
  ret << place_folder.gsub("#href#","/photodb/manage/update_thumb_s").gsub("#link#",'update_thumb_s')
  ret << place_folder.gsub("#href#","/photodb/manage/update_db").gsub("#link#",'update_db')
end

get '/manage/update_tag' do
  protected!
  ret = ["<h1>DONE:manage/updatet_tag</h1>"]
  Photomodel.all.each do |photo|
    photo.set_search
    photo.save
    ret << "<li>#{photo.path}=>#{photo.search}"
    ret << "<li>#{photo.path}=>#{photo.search2}"
  end
  ret.join("")
end

get '/manage/update_thumb_m' do
  protected!
  ret = ["<h1>DONE:manage/updatete_thumb_m</h1>"]
  ret << Photomodel.update_thumb_m
  ret.join("<br/>")
end

get '/manage/update_thumb_s' do
  protected!
  ret = ["<h1>DONE:manage/update_thumb_s</h1>"]
  ret << Photomodel.update_thumb_s
  ret.join("<br/>")
end

get '/manage/update_db' do
  protected!
  ret = ["<h1>DONE:manage/update_db</h1>"]
  ret << Photomodel.update_db
  ret.join("<br/>>")
end
##########  /manage  ###########################################

### API #####################
get '/api/image/full/:mid' do
  expires 36000 ,:public
  cache_control :public, 36000
  
  flg = false
  if params['qs']
    path = make_path(params['qs'])
    if File.exists? path
      send_file path ,
      :filename => File.basename(path),
      :type => "image/#{type(path)}"
      flg = true
    end
  end
  if !flg
    ret = Photomodel.where(:_id => params['mid']).only(:path).first
    if ret 
      path = make_path(ret.path)
      

      type = File.extname(path).gsub('.','')
      if type == "jpg" || type == "JPG"
        type = "jpeg"
      end
      
      send_file path ,
      :filename => File.basename(path),
      :type => "image/#{type(path)}"
    else
      "error"
    end
  end 
end

get '/api/image/data/:mid' do
  expires 36000 ,:public
  cache_control :public, 36000
  
  ret = Photomodel.where(:_id => params['mid']).only(:search,:tag,:exif,:name,:path).first
  if ret.nil?
    "error"
  else
    content_type  'application/json; charset=utf-8'    
    "[#{ret.to_json}]"
  end
end

get '/api/image/updatetag/:mid' do
  ret = Photomodel.where(:_id => params['mid']).only(:tag,:exif,:name,:path).first
  if ret.nil?
    "error"
  else
    ret.update_tag(:string => params[:qs])
    content_type  'application/json; charset=utf-8'    
    "[#{ret.to_json}]"
  end
end

get '/api/image/thumb_m/:mid' do
  expires 36000 ,:public
  cache_control :public, 36000
  
  ret = Photomodel.where(:_id => params['mid']).only(:path,:thumb_m).first
  if ret.nil?
    "error"
  else
    if ret.thumb_m.nil?
      buff = `convert -define jpeg:size=400x300 -resize 400x300 -quality 90 -strip "#{make_path(ret.path)}" -`
      ret.thumb_m = BSON::Binary.new buff
      ret.save
    end
    path = make_path(ret.path)
    content_type "image/#{type(path)}"    
    "#{ret.thumb_m}"
  end
end

get '/api/dir/:mid' do
  expires 36000 ,:public
  cache_control :public, 36000
  
  ret = Dirmodel.where(:_id => params['mid']).first
  photos = ret.photomodels.only(:id,:name,:path,:thumb_s,:search)
  if photos
    rets = []
    photos.each do |e|
      elem = {}
      elem[:_id] = e.id
      elem[:name] = e.name
      elem[:path] = e.path
      if e.thumb_s.nil?
        e.update_thumb_s
        e.save
      end
      elem[:thumb_s] = e.thumb_s #
      rets << elem
    end
    content_type  'application/json; charset=utf-8'    
    [{:status => "ok"},rets].to_json
  else
    "error"
  end
end

get '/api/dirs' do
  expires 36000 ,:public
  cache_control :public, 36000
  
  rets = Dirmodel.all.asc(:name) #.only(:id,:path,:name,:pcount)
  if rets.first.nil?
    "error"
  else
    ret = []
    rets.each do |dir|
      next if dir.name == 'Thumbnail'
      next if dir.name == 'Original'
      #      if dir.pcount.nil?
      dir.pcount = dir.photomodels.count
      #        dir.save
      #      end
      elem = {}
      elem[:_id] = dir.id;
      elem[:path] = dir.path;
      elem[:name] = "#{dir.name}(#{dir.pcount})"
      ret << elem
    end
    content_type  'application/json; charset=utf-8'    
    ret.to_json
  end
end

get '/api/search1' do
  page = params['page'] ||= 1
  page = page.to_i
  per  = params['per'] ||= 10
  per = per.to_i
  
  photosret = Photomodel.search_photo(params['qs'].gsub('<OR>','|'),:search,page,per)
  photosret[1].each do |e|
    if e.thumb_s.nil?
      e.update_thumb_s
      e.save
    end
  end

  content_type  'application/json; charset=utf-8'
  photosret.to_json
end

get '/api/search2' do
  page = params['page'] ||= 1
  page = page.to_i
  per  = params['per'] ||= 10
  per = per.to_i

  photosret = Photomodel.search_photo(params['qs'].gsub('<OR>','|'),:search2,page,per)
  
  photosret[1].each do |e|
    if e.thumb_s.nil?
      e.update_thumb_s
      e.save
    end
  end
  content_type  'application/json; charset=utf-8'    
  photosret.to_json
end

get '/api/search3' do
  page = params['page'] ||= 1
  photos = Photomodel.search_photo(params['qs'].gsub('<OR>','|'),:search2,page)
  photosret[1].each do |e|
    if e.thumb_s.nil?
      e.update_thumb_s
      e.save
    end
  end
  content_type  'application/json; charset=utf-8'
  photos.to_json
end



#######################################################################
get '/photodb/api/image/full/:mid' do
  expires 36000 ,:public
  cache_control :public, 36000
  
  flg = false
  if params['qs']
    path = make_path(params['qs'])
    if File.exists? path
      send_file path ,
      :filename => File.basename(path),
      :type => "image/#{type(path)}"
      flg = true
    end
  end
  if !flg
    ret = Photomodel.where(:_id => params['mid']).only(:path).first
    if ret 
      path = make_path(ret.path)
      

      type = File.extname(path).gsub('.','')
      if type == "jpg" || type == "JPG"
        type = "jpeg"
      end
      
      send_file path ,
      :filename => File.basename(path),
      :type => "image/#{type(path)}"
    else
      "error"
    end
  end 
end

get '/photodb/api/image/data/:mid' do
  expires 36000 ,:public
  cache_control :public, 36000
  
  ret = Photomodel.where(:_id => params['mid']).only(:search,:tag,:exif,:name,:path).first
  if ret.nil?
    "error"
  else
    content_type  'application/json; charset=utf-8'    
    "[#{ret.to_json}]"
  end
end

get '/photodb/api/image/updatetag/:mid' do
  ret = Photomodel.where(:_id => params['mid']).only(:tag,:exif,:name,:path).first
  if ret.nil?
    "error"
  else
    ret.update_tag(:string => params[:qs])
    content_type  'application/json; charset=utf-8'    
    "[#{ret.to_json}]"
  end
end

get '/photodb/api/image/thumb_m/:mid' do
  expires 36000 ,:public
  cache_control :public, 36000
  
  ret = Photomodel.where(:_id => params['mid']).only(:path,:thumb_m).first
  if ret.nil?
    "error"
  else
    if ret.thumb_m.nil?
      buff = `convert -define jpeg:size=400x300 -resize 400x300 -quality 90 -strip "#{make_path(ret.path)}" -`
      ret.thumb_m = BSON::Binary.new buff
      ret.save
    end
    path = make_path(ret.path)
    content_type "image/#{type(path)}"    
    "#{ret.thumb_m}"
  end
end

get '/photodb/api/dir/:mid' do
  expires 36000 ,:public
  cache_control :public, 36000
  
  ret = Dirmodel.where(:_id => params['mid']).first
  photos = ret.photomodels.only(:id,:name,:path,:thumb_s,:search)
  if photos
    rets = []
    photos.each do |e|
      elem = {}
      elem[:_id] = e.id
      elem[:name] = e.name
      elem[:path] = e.path
      if e.thumb_s.nil?
        e.update_thumb_s
        e.save
      end
      elem[:thumb_s] = e.thumb_s #
      rets << elem
    end
    content_type  'application/json; charset=utf-8'    
    [{:status => "ok"},rets].to_json
  else
    "error"
  end
end

get '/photodb/api/dirs' do
  expires 36000 ,:public
  cache_control :public, 36000
  
  rets = Dirmodel.all.asc(:name) #.only(:id,:path,:name,:pcount)
  if rets.first.nil?
    "error"
  else
    ret = []
    rets.each do |dir|
      next if dir.name == 'Thumbnail'
      next if dir.name == 'Original'
      #      if dir.pcount.nil?
      dir.pcount = dir.photomodels.count
      #        dir.save
      #      end
      elem = {}
      elem[:_id] = dir.id;
      elem[:path] = dir.path;
      elem[:name] = "#{dir.name}(#{dir.pcount})"
      ret << elem
    end
    content_type  'application/json; charset=utf-8'    
    ret.to_json
  end
end

get '/photodb/api/search1' do
  page = params['page'] ||= 1
  page = page.to_i
  per  = params['per'] ||= 10
  per = per.to_i
  
  photosret = Photomodel.search_photo(params['qs'].gsub('<OR>','|'),:search,page,per)
  photosret[1].each do |e|
    if e.thumb_s.nil?
      e.update_thumb_s
      e.save
    end
  end

  content_type  'application/json; charset=utf-8'
  photosret.to_json
end

get '/photodb/api/search2' do
  page = params['page'] ||= 1
  page = page.to_i
  per  = params['per'] ||= 10
  per = per.to_i

  photosret = Photomodel.search_photo(params['qs'].gsub('<OR>','|'),:search2,page,per)
  
  photosret[1].each do |e|
    if e.thumb_s.nil?
      e.update_thumb_s
      e.save
    end
  end
  content_type  'application/json; charset=utf-8'    
  photosret.to_json
end

get '/photodb/api/search3' do
  page = params['page'] ||= 1
  photos = Photomodel.search_photo(params['qs'].gsub('<OR>','|'),:search2,page)
  photosret[1].each do |e|
    if e.thumb_s.nil?
      e.update_thumb_s
      e.save
    end
  end
  content_type  'application/json; charset=utf-8'
  photos.to_json
end

__END__

=begin
#結局おそいの
#lazyにアトリビュートを埋めていく戦略に変更
  rets = Dirmodel.all.only(:id,:path,:name)
  if rets.first.nil?
    "error"
  else
    #    rets.to_json
m =<<-EOT
function(){
  emit(this.dirmodel_id, { count: 1 });
}
EOT

r =<<-EOT
function(key, values){
  var _count = 0;
  values.forEach(function(value){ _count += value.count;});
  return {count: _count}
  };
}
EOT
    ret2 = {}    
#    counter = Photomodel.collection.
#      map_reduce(m,r,{out:'ret'}).find.each do |e|
#      ret2[e["_id"]] = e["value"]["count"]
#    end
    ret = []
    rets.each do |e|
      next if e.name == 'Thumbnail'
      next if e.name == 'Original'
      elem = {}
      elem[:_id] = e.id;
      elem[:path] = e.path;
      count = '??' #ret2[e.id].to_i.to_s
      elem[:name] = "#{e.name}(#{count})"
      ret << elem
    end
    ret.to_json
  end
=end  

=begin
http://www.func09.com/wordpress/archives/1200
require "#{Dir.pwd}/photomodels.rb"
m =<<-EOT
function(){
  emit(this.dirmodel_id, { count: 1 });
}
EOT
r =<<-EOT
function(key, values){
  var _count = 0;
  values.forEach(function(value){ _count += value.count;});
  return {count: _count}
  };
}
EOT

counter = Photomodel.collection.
  map_reduce(m,r,{out:'ret'}).find.sort("_id",'asc').each do |e|
  p e
  p e["_id"]
  p e["value"]["count"]
end
=end
