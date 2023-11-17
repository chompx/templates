# aws-build

Used to configure a new AWS instance for development

## client_side

Things in the client_side are local scripts used to manage AWS or instances from a local
client.

System-wide
 - configuring AWS users

Typically, this involves:
 - launching the instance
 - configuring keys
 - logging in
 - pushing the initial ec2_side scripts over
 - executing the ec2_side initial scripts
 
 ## ec2_side
 
 The ec2_side scripts are run on an instance.  There is a little bit of bootstrapping from
 the initial scripts that mount volumes and install utility tools such as git, python, and
 editors
 
 Once the initial scripts are run, git can be used to download any phase II scripts to
 execute further work.
 
 
