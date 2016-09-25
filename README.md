# my_github_api
basic github api with ruby

NOTES:
In order to make this work, you must ensure you have a current version of ruby and the json and aws-sdk gems installed.

gem install json aws-sdk

Assumptions =>
1- user has valid github credentials
2- user is a member of at leaset one github organization
3- members of organization have public emails (otherwise will find no emails for members)
4- user has access to an AWS S3 Bucket
5- user has already created a file storing the users AWS user credentials in ~/.aws/credentails file like so:

[name_of_credentials]
aws_access_key_id = your_key_id
aws_secret_access_key = your_access_key

6- aws s3 bucket is within region:'us-east-1'
7- user knows the smtp server's info in order to send emails correctly
8- user must modify the code for setting up an smtp server within the code in the my_github_api.rb file.
  - look for the #### Replace #### line and the information needed is easily replaced.
