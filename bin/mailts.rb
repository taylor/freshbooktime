#!/usr/bin/env ruby
##
## mailts.rb
## Login : <taylor@codecafe.com>
## Started on Sat Sep 19 04:04:39 2009 -0500 Taylor Carpenter
## $Id$

APPNAME = File.basename(__FILE__)
SCRIPT_PATH = Dir.chdir(File.expand_path(File.dirname(__FILE__))) { Dir.pwd }
CONF_PATH = Dir.chdir(SCRIPT_PATH + '/../conf') { Dir.pwd }
CACHE_DIR = Dir.chdir(SCRIPT_PATH + '/../cache') { Dir.pwd }
lib_path = Dir.chdir(SCRIPT_PATH + '/../lib') { Dir.pwd }

$:.unshift lib_path

require 'rubygems'
require 'action_mailer'
require 'inline_attachment'
require 'mime/types'
require 'yaml'
require 'ext/smtp_tls'
require 'ext/action_mailer_tls'
require 'pp'

TSCONF = CONF_PATH + 'timesheet_config.yml'

#$config = YAML.load_file(CONF_PATH + "/myconfig.yml")

class Mailer < ActionMailer::Base
  def message (from_a, to, cc, bcc, sub, b, *att)

    from from_a
    recipients to
    subject sub
    body b
    cc cc
    bcc bcc

    att.flatten!

    att.each do |apath|
      puts "trying to attach file #{apath}"
      file = File.basename(apath)
      mime_type = MIME::Types.of(file).first
      #content_type = mime_type ? mime_type.content_type : 'application/binary'
      content_type = mime_type ? mime_type.content_type : 'plain/text'
      puts "ct: #{content_type}"
      unless content_type =~ /^image/
        inline_attachment :content_type => content_type,
          :body => File.read(apath),
          :filename => file,
          :cid => "",
          :transfer_encoding => 'quoted-printable' if content_type =~ /^text\//
      else
        attachment :content_type => content_type,
          :body => File.read(apath),
          :filename => file
      end
    end
  end
end

#MAILCONF = 'conf/mailconf.yml'
#MAILCONF = 'conf/mailconf-chris.yml'

unless ARGV.length > 0 and File.exist?(ARGV[0])
  puts "Usage: mailts.rb <conf> [attachment1 .. attN]"
  exit 1
end

mailconf = ARGV[0]
ARGV.shift

mc = YAML.load_file(mailconf)
tsc = YAML.load_file(TSCONF)

ActionMailer::Base.smtp_settings = mc[:smtp_settings]
ActionMailer::Base.template_root = 'templates'

#body = mc[:body] || tsc[:title]
body = mc[:body] || ""
cc = mc[:cc]
bcc = mc[:bcc]
subject = "#{mc[:subject]} #{tsc[:title]}"
Mailer.deliver_message(mc[:from], mc[:to], cc, bcc, subject, body, ARGV)
