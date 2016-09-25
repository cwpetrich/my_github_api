require 'rubygems'
require 'json'
require 'net/smtp'

puts "enter user name"
user_name = gets.chomp.to_s
puts "enter organization name"
organization_name = gets.chomp.to_s

reponse = JSON.parse(`curl -u '#{user_name}' https://api.github.com/orgs/#{organization_name}/members`)
members = reponse.collect{|member| JSON.parse(`curl -u '#{user_name}' #{member['url']}`)}
members_with_names = members.select{|member| member['name']}
members_without_names = members.select{|member| !member['name']}

members_without_names.each{|member| `echo 'https://github.com/settings/profile?profile_link=1' | mail -s 'Add Your Name to Your Github Account' #{member['email']}`}
puts "members => #{members}"
puts "members_with_names => #{members_with_names}"
puts "members_without_names => #{members_without_names}"


message = <<MESSAGE_END
From: Private Person <cradpetrich@gmail.com>
To: A Test User <conradpetrich@gmail.com>
MIME-Version: 1.0
Content-type: text/html
Subject: SMTP e-mail test

This is an e-mail message to be sent in HTML format

<b>This is HTML message.</b>
<h1>This is headline.</h1>
MESSAGE_END

Net::SMTP.start('smtp.gmail.com', 587, 'localhost', 'conradpetrich', 'iburntmynosehairs', :plain) do |smtp|
  smtp.send_message message, 'cradpetrich@gmail.com', 'conradpetrich@gmail.com'
end