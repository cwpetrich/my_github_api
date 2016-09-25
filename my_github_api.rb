require 'rubygems'
require 'json'
require 'net/smtp'
require 'aws-sdk'


# NOTES:

# In order to make this work, you must ensure you have a current version of ruby and the proper gems installed
# some of which are required above. The gems needed to run this scrip can be installed via command line:

# gem install json aws-sdk

# The rubygems and net/smtp gems are built into ruby and shouldn't need to be installed as long 
# as you have a current version of ruby.

# Assumptions =>
# 1- user has valid github credentials
# 2- user is a member of at leaset one github organization
# 3- members of organization have public emails
# 4- user has access to an AWS S3 Bucket
# 5- user has already created a file storing the users AWS user credentials in ~/.aws/credentails file like so:
#
# [name_of_credentials]
# aws_access_key_id = your_key_id
# aws_secret_access_key = your_access_key
#
# 6- bucket is within region:'us-east-1'
# 7- user knows the smtp server's info in order to send emails correctly


# prompt user for Github username then desired organization
puts "enter user name"
user_name = gets.chomp.to_s
puts "enter organization name"
organization_name = gets.chomp.to_s

# Github's V3 API call to retrieve members of an organization requires user authentication
# of a user within said organization in order to view the organizations members
begin
  response = JSON.parse(`curl -u #{user_name} https://api.github.com/orgs/#{organization_name}/members`)
rescue Exception => e
  puts "There was an error either with your credentials or mispelled organization name"
  puts response
  puts e.message
  puts e.backtrace
end

# Gather information for each user from organization's members
begin
  members = response.collect{|member| JSON.parse(`curl #{member['url']}`)}
rescue Exception => e
  puts "There was an error retrieving listed organization's members.\nEnsure you entered authentication info and organization name correctly."
  puts response
  puts e.message
  puts e.backtrace
end

# Seperate members of organization who do not have names assigned to their github accounts
members_without_names = members.select{|member| !member['name']}

# Nothing to do if there are no members without names
unless members_without_names.empty?

  # get usernames of organization's members that don't have names on their github accounts.
  user_names = members_without_names.collect{|member| member['login']}

  begin
    puts "Enter Bucket name to save file of users without names."
    bucket_name = gets.chomp.to_s

    # forces the use of bundled certifications for convenience
    Aws.use_bundled_cert!

    # connect to bucket in speicified region
    # I am assuming that the region is us-east-1 which is also for US Standard.
    s3 = Aws::S3::Resource.new(region:'us-east-1')
    obj = s3.bucket("#{bucket_name}").object('GithubUsersWithoutNames')

    # save text directly to file with .put method for s3 bucket
    obj.put(body: "#{user_names.join(', ')}")
  rescue Exception => e
    puts "Error saving usernames of members without names to S3 bucket"
    puts e.message
    puts e.backtrace
  end

  # Gather emails from members who do not have names assigned to their github accounts into an array
  recipient_emails = members_without_names.collect{|member| member['email']}

  # The subject and body of the email are seperated by two new line characters
  message = "Subject: Hey There!\n\nBe sure to enter your name in you Github account by following the link below.\nhttps://github.com/settings/profile?profile_link=1"

  begin
    # smtp = Net::SMTP.new('smtp_server_name', port_number)
    smtp = Net::SMTP.new('smtp.gmail.com', 587)
    smtp.enable_starttls

#### Replace 
    # smtp.start('domain', 'username', 'password', :login)
    smtp.start('mail.google.com', 'johndoe', 'secret', :login) do
      smtp.send_message(message, "johndoe@gmail.com", recipient_emails)
    end
  rescue Exception => e
    puts "There was an error when attempting to send an email."
    puts e.message
    puts e.backtrace
  end
else
  puts "There are not members without names within the organization: #{organization_name}"
end