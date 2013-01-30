#!/usr/bin/env ruby -w
# encoding: UTF-8
require 'rubygems' # if you use RubyGems   
require 'daemons'

Daemons.run('input_flows_server.rb')