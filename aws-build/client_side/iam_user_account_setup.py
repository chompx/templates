#!/usr/local/bin/python3
#

# account_setup.py
#    simplifies creating new IAM users in accounts

import os, sys, getopt
import json

import configparser
import subprocess

profiles= { }


# for k,v in profiles.items():
#     print(f" name:  {k}   target:  {v[1]}")
	 

def help():
    print("account_setup.py         --> lists options")
    print("   options:   ")
    print("   --users  <filename>    points to a json user database file e.g. /Users/rosema/code/madrona/aws_data/encore_users.json  ")
    print("   -h                    --> help")
    sys.exit(0)


def get_config():
    path = os.path.join(os.path.expanduser('~'), '.aws/config')
    config = configparser.ConfigParser()
    config.read(path)
    profiles = [ s.split()[1] for s in config.sections() if 'profile' in s ]

    
def fetch_account_id(profile_name):
    '''Returns the account_id for a specific profile'''
    # see: https://forums.aws.amazon.com/thread.jspa?threadID=266940
    command = f"aws iam get-user --profile {profile_name} --query 'User.Arn'|awk -F\: '{{print $5}}'"
    account_id = os.popen(command).read()
    return account_id
    
def fetch_login_url(profile_name):
    '''Returns the console login url for a specific profile'''
    account_id = fetch_account_id(profile_name).strip()
    login_url = f"https://{account_id}.signin.aws.amazon.com/console/"
    return login_url

def generate_pwd():
    command = 'openssl rand -base64 8'
    return  os.popen(command).read().strip()


def create_aws_account(profile_name, userdict):
    username  = userdict['userName']

    account = user_exists(profile_name,username)
    if account:
        print(f" Account already exists for {account['User']['UserName']}")
        return
    
    groupname = userdict['awsGroup']
    email     = userdict['emailAddress']
    givenname = userdict['firstName']
    surname   = userdict['lastName']
    pwd       = generate_pwd()
    loginurl  = fetch_login_url(profile_name)
    
    userdict["awsInitialPwd"]    = pwd
    # command_create_account       = f"aws iam create-user --profile {profile_name} --user-name {username} --email-address {email} --given-name {givenname} --surname {surname}"
    command_create_account       = f"aws iam create-user --profile {profile_name} --user-name {username}"
    command_grant_console_access = f"aws iam create-login-profile --profile {profile_name} --user-name {username} --password {pwd} --password-reset-required"
    command_assign_group         = f"aws iam add-user-to-group    --profile {profile_name} --group-name {groupname} --user-name {username}"
    command_attach_pwd_policy    = f"aws iam attach-user-policy   --profile {profile_name} --user-name {username}  --policy-arn arn:aws:iam::aws:policy/IAMUserChangePassword"


    if username=='cristian.spoiala':
        print(command_create_account)
        print(command_grant_console_access)
        print(command_assign_group)
        
        result =  os.popen(command_create_account).read()
        print(result)
        result =  os.popen(command_grant_console_access).read()
        print(result)
        result =  os.popen(command_assign_group).read()
        print(result)
        result =  os.popen(command_attach_pwd_policy).read()
        print(result)

        print(f"Hi {givenname}, ")
        print(f"I've created a new AWS account for you.")
        print(f"Your username:  {username}")
        print(f"Your login url: {loginurl}")
        print(f"Password will follow in Slack.")
        print(f"Thanks!")
        print(f" -Keith")
        print(f"Your password:  {pwd}     please change immediately")
        print(f"{email}")
    

def user_exists(profile_name, username):
    '''returns true if username exists in this account'''
    command = f"aws iam get-user --profile {profile_name} --user-name {username}"
    account_str = os.popen(command).read()
    # print("Account string: ")
    # print(account_str)
    # print()
    try:
        account = json.loads(account_str)
    except:
        account = False
    return account

def check_account(profile_name, username):
    account = user_exists(profile_name,username)
    if account:
        print(f" Account found for {account['User']['UserName']}")
    else:
        print(f" Account not found for {username}")

def configure_accounts(profile_name, userdict):

    if not userdict['awsAccount']:
        return

    create_aws_account(profile_name, userdict)
     
    

def main():
    
    try:
        opts, args = getopt.getopt(sys.argv[1:],"h",["users="])
    except getopt.GetoptError:
        help()

    inputs = args

    users_json_file = ''
    account_data    = None
    users_data      = None
    profile         = None
    
    for opt, arg in opts:
        if opt == '-h':
             help()
        elif opt == '--users':
            users_json_file = arg
            print(f"Setting users_json_file to {users_json_file}")

    if users_json_file:
        f = open(users_json_file,)
        account_data = json.load(f)
        users_data   = account_data['users']
        profile      = account_data['profile']
        f.close()

    for u in users_data:
        configure_accounts(profile, u)
    


if __name__ == '__main__':
    main()

