#! /usr/bin/env ruby

require 'kconv'
require File.dirname(__FILE__)+'/photomodels'
require File.dirname(__FILE__)+'/globmodel'

Photomodel::update_db
Photomodel::update_thumb_m
Photomodel::update_thumb_s

