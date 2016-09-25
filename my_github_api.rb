require 'rubygems'
require 'json'
require 'net/smtp'
require 'octokit'

puts "enter user name"
user_name = gets.chomp.to_s
puts "enter organization name"
organization_name = gets.chomp.to_s

response = JSON.parse(`curl -u #{user_name} https://api.github.com/orgs/#{organization_name}/members`)
members = response.collect{|member| JSON.parse(`curl -u #{user_name} #{member['url']}`)}
members_with_names = members.select{|member| member['name']}
members_without_names = members.select{|member| !member['name']}

# members_without_names.each{|member| `echo 'https://github.com/settings/profile?profile_link=1' | mail -s 'Add Your Name to Your Github Account' #{member['email']}`}

message = <<MESSAGE_END
From: Private Person <cradpetrich@gmail.com>
To: A Test User <conradpetrich@gmail.com>
Subject: SMTP e-mail test

This is a test email message.
MESSAGE_END

Net::SMTP.new('smtp.gmail.com', 465).start('smtp.gmail.com', 465, 'localhost', 'conradpetrich@gmail.com', 'iburntmynosehairs', :plain, :enable_starttls_auto => true) do |smtp|
  smtp.send_message message, 'cradpetrich@gmail.com', 'conradpetrich@gmail.com'
end