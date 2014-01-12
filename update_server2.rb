#! /bin/env ruby

require 'kconv'
require File.dirname(__FILE__)+'/photomodels'

Photomodel.all.each do |photo|
  puts photo.path
  photo.update_thumb_m
  photo.save
end
