require 'rubygems'
require 'json'
require 'net/smtp'
require 'aws-sdk'

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
    obj = s3.bucket("#{bucket_name}").object('github_nonames')

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
    ######################### Replace ###########################
    # Currently set to work with Gmail, and if you don't want to use gmail you will need to replace information:

    # 1- replace smtp.gmail.com with another smtp server name (or leave as is if using gmail)
    # 2- replace 587 with another port number
    smtp = Net::SMTP.new('smtp.gmail.com', 587)
    smtp.enable_starttls

    # 1- replace mail.google.com with domain of mail server (or leave as is if using gmail)
    # 2- replace johndoe with username
    # 3- replace secret with password 
    smtp.start('mail.google.com', 'johndoe', 'secret', :login) do
      # 1- replace johndoe@gmail.com with the email with the credentials on line above
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