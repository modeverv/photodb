#! /usr/bin/env ruby
# -*-coding:utf-8-*-
require 'kconv'
require 'bson'
require 'mongo'
require 'mongoid'
require 'exifr'
require 'RMagick'
require 'kconv'
#begin
#  require 'MeCab'
#rescue
#end
begin
  require 'mecab'
rescue
end
require 'active_support/concern'

#Mongoid.load!( File.dirname(__FILE__) + "/mongoid.yml" ,:production)
#Mongoid.load!( File.dirname(__FILE__) + "/mongoid.yml")

Mongoid.configure do |config|
  config.master = Mongo::Connection.new('localhost').db('photo-mongoid2')
  config.identity_map_enabled = true
end

class Dirmodel
  include Mongoid::Document
  
  field :path, type: String, :default => ''
  field :name, type: String, :default => ''
  field :created_at, :type => DateTime, :default => Time.now
  field :pcount, type:Integer,:default => nil
  field :count_data, type:Integer,:default => nil

#  index :path
  
  #  has_many :photomodels
  has_and_belongs_to_many :photomodels

  def models_count
    self.photomodels.size
  end
end

class Photomodel
  include Mongoid::Document
  field :exif, type: String, :default => '{}'
  field :thumb_s, :type => BSON::Binary ,:default => nil
  field :thumb_m, :type => BSON::Binary ,:default => nil
  field :thumb_m64, :type => BSON::Binary ,:default => nil
  field :path, type: String, :default => ''
  field :name, type: String, :default => ''
  field :search, type: String, :default => ''
  field :search2, type: Array, :default => []
  field :created_at, :type => DateTime, :default => Time.now
  field :tag,:type => String ,:default => ''

#  index :search
#  index :search2
#  index :path
  
  has_and_belongs_to_many :dirmodels
  
  def set_search
    require 'kconv'
    tags = self.tag.split(' ').map{|e|"t:#{e}"}.join('|')
    self.exif = '{}' if exif.nil? || exif == ''
    tmp = self.exif.gsub(/{/,'').gsub(/}/,'').split(',')

    exifs = tmp.map{|e|"e:#{e}" }.join('|').gsub('"','')
    self.search = "p:#{path.downcase}|#{exifs.downcase}|#{tags.downcase}".encode('utf-8', {:invalid => :replace, :undef => :replace, :replace => '?'})

    mecab = MeCab::Tagger.new("-Owakati")
    strs = []
    strs << "#{path}" 
    strs << tmp.map{|e| "#{e.downcase.toutf8}" }.join(' ').gsub('"','')
    exifs2 = mecab.parse(strs.join('')).encode('utf-8',{:invalid => :replace, :undef => :replace, :replace => '?'}).split(' ').uniq
    self.search2 = exifs2
  end

  def self.search_photo(query,sfield="search",page=1,per=10)
    sfield = sfield.to_sym
    puts sfield
    if sfield == :search
      keywords = query.gsub('<OR>','|').split(' ').map {|q| /#{q.downcase}/}
    else
      qs2 = query.gsub('<OR>','|')
      keywords = MeCab::Tagger.new("-Owakati").parse(qs2).split(' ').map{|e| /^#{e.downcase}/}
    end
    page = page.to_i
    per = per.to_i
    per = 1 if per < 1
    skipnum=(page-1) * per
    if query == 'recent'
      Photomodel.recent_photo(page,per)
    else      
      retcount = Photomodel.where(sfield.all => keywords).size
      status = {:page => page,:total => retcount,:next => "no",:prev => "no",:qs => query}
      status[:next] = "yes" if retcount > page * per #境界微妙
      status[:prev] = "yes" if page.to_i > 1

      rets = Photomodel.where(sfield.all => keywords)
        .skip(skipnum).limit(per).only(:name,:path,:thumb_s)
      #    rets = Photomodel.where(sfield.all => keywords).only(:id,:name,:path,:thumb_s)
      [status,rets]
    end
      
  end

  def self.recent_photo(page,per)
    page = page.to_i
    per = per.to_i
    per = 1 if per < 1
    skipnum=(page-1) * per
    
    retcount = Photomodel.all.size
    status = {:page => page,:total => retcount,:next => "no",:prev => "no",:qs => "recent"}
    status[:next] = "yes" if retcount > page * per #境界微妙
    status[:prev] = "yes" if page.to_i > 1

    rets = Photomodel.desc(:created_at)
      .skip(skipnum).limit(per).only(:name,:path,:thumb_s)
    [status,rets]
  end

  def update_thumb_m
    return unless self.thumb_m.nil? || self.thumb_m64.nil?
    buff_m = `convert -define jpeg:size=400x300 -resize 400x300 -quality 90 -strip "#{path}" -`
    self.thumb_m = BSON::Binary.new buff_m
    self.thumb_m64 = BSON::Binary.new [buff_m].pack('m')
  rescue
  end

  def update_thumb_s
    return unless self.thumb_s.nil?
    buff_s = `convert -define jpeg:size=160x120 -resize 160x120 -quality 90 -strip "#{path}" -`
    self.thumb_s = BSON::Binary.new [buff_s.to_s].pack('m')
  rescue
  end

  def update_tag(args)
    args[:string] = args[:string] ||= ''
    args[:mode] = args[:mode] ||= 'single'
   
    #string is tags string separated by space
    if args[:mode] == 'single'
      self.tag = args[:string]
      set_search
      self.save
      return
    end
    
    if args[:mode] == 'multi'
      tags = args[:string].split(' ')
      tags_orig = self.tag.split(' ')
      tags_ret = tags | tags_orig
      self.tag = tags_ret.join(' ')
      set_search
      self.save
      return 
    end
  end
  
  class << self
    def update_tag
      rets = []
      photos = Photomodel.all
      photos.each do |photo|
        rets << photo.path
        photo.set_search
        photo.save
      end
    end

    def update_thumb_s
      puts "UPDATE_THUMB_S"
      # rets = []
      photos = Photomodel.all
      photos.each do |photo|
        puts photo.path
        # rets << photo.path 
        photo.update_thumb_s
        photo.save
      end
    end

    def update_thumb_m
      puts "UPDATE_THUMB_M"
      # rets = []
      photos = Photomodel.all
      photos.each do |photo|
        puts photo.path
        # rets << photo.path 
        photo.update_thumb_m
        photo.save
      end
    end

    def delete_not_exist_entry
      rets = Photomodel.all
      rets.each do |photo|
        puts "check #{photo.id} => #{photo.path}"
        if !File.exists?(photo.path)
          puts " not_exist => #{photo.path}" 
          dir = photo.dirmodels.first
          dir.photomodels.delete photo
          photo.delete
        end
      end
    end
    
    def update_db
      delete_not_exist_entry
      rets = []     
      require File.dirname(__FILE__)+'/globmodel'     
      gs = GlobServer.new(server: "/var/smb/sdb1",folders: ["photo"])
      # gs.media_glob
      
      puts gs.files.count
      gs.each do |e|
        unless Photomodel.where(:path => e).first.nil?
          next
        end
        puts "do make model:#{e}"
        Photomodel.path2object(e)
      end
      # rets << Photomodel.update_thumb_s
      # rets << Photomodel.update_thumb_m
      # return rets.flatten
    end
    
    def path2object(path)
      ret = []
      ret << path 
      dir = File.dirname(path)
      a_dir = Dirmodel.where(:path => dir).first
      if a_dir.nil?
        a_dir = Dirmodel.new(:path => dir,:name => File.basename(dir))
        a_dir.save
      end
      a_photo = Photomodel.new(
                               :path => path,
                               :name => File.basename(path),
                               )
      begin
        #exif取得
        if File.extname(path) == '.jpg' ||
            File.extname(path) == '.JPG' ||
            File.extname(path) == '.jpeg' ||
            File.extname(path) == '.JPEG' 
          jpg = File.open(path,'rb')
          exif = EXIFR::JPEG.new(jpg)
          a_photo.exif = exif.to_json
          jpg.close
        end
      rescue =>ex
        ret << ex.to_s
      end
      
      a_photo.set_search
      a_dir.photomodels.push a_photo
      a_dir.save
      a_photo.save
      return ret
    end
  end
end
