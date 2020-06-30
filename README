# Imap setup

First step is creating the filtered folders on your imap email
(I have named them "Imbox", "Feed", "Papertrail", "screenout" [all case sensitive]), 
if you want you can add new folders or remove some by changing the sourcecode.
The constant that defines the folders is in `./main.rb` 

# Configuration

You are going to need the env vars set at set_env_vars.bash setted, if running on an AWS lambda , you wont require the ACCESS key and password although you'll need to give the lambda role S3 permissions.

with that set , you need the filter file available on S3 so, rename and send empty_filter_file to S3.

With that you're all set.

# Running locally

Send your empty filter file to s3.
source set_env_vars.bash
ruby localrun.rb

# Running on a lambda

configure env vars
upload the files(*.rb to lambda and filter file to s3) 
give your lambda role s3 permissions
set a cloudwatch event to run the lambda every X minutes


