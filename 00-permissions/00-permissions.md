It’s very tempting to get straight into creating infrastructure, but,
like in an ideal real world, I wanted to make sure that security was
built-in from the start and use the ‘Principle of Least Privilege’ in
all of the scenarios.

For all of the infrastructure as code that is written, applied, and
destroyed in each provider, we will do this using a ‘study’ account
which is a member of a ‘study’ group. For each scenario, before we do
perform any creation of infrastructure, we’ll make sue to define
policies or permissions that we limit the blast raduius, ensuring that
this user can only create and destory certain designated elements.

# AWS

**\[AWS IAM Terraform Code\]**

We’ll be using the IAM functionality to ring fence our study access. We
create a *study* group, a *study* user, and we add the user into the
group.

From this point on we’ll try and use *tag based policies* to limit the
access to the resources in each scenario: *Spoiler alert*: this seems to
be very difficult to manage.

There’s an optional ‘path’ variable which allows us (if we want to) to
structure the users and groups we create. This can help when you’re
referring to groups or users using their arn. For example you could
refer to all groups under ‘/groups/business\_unit\_a/’ using the arn
`arn:aws:iam:<account_id>:group/groups/business_unit_a/*`.

Let’s build these users and groups using Terraform.

    cd aws
    terraform apply -auto-approve > ../logs/aws.log

You can see the raw logs for this Terraform application
[here](00-permissions/logs/aws.log).

We also need to generate an access key to use. I’m going to do that
using the AWS CLI, rather than Terraform. I’ve also made sure I add the
line "\*.priv.txt" to my .gitignore file to I don’t accidently advertise
my IAM key to the whole world.

    # Generate the access key
    aws iam create-access-key --user-name study > aws_study_access_key.priv.txt

    # Print out but redact
    jq '.AccessKey.SecretAccessKey = "<REDACTED>"' aws_study_access_key.priv.txt

    ## {
    ##   "AccessKey": {
    ##     "UserName": "study",
    ##     "AccessKeyId": "AKIA5BTYAKZGOMTHVVNH",
    ##     "Status": "Active",
    ##     "SecretAccessKey": "<REDACTED>",
    ##     "CreateDate": "2021-07-19T04:44:41Z"
    ##   }
    ## }

I then create a new profile using the AWS CLI using the command
`aws configure --profile terraform`. In all subsequent Terraform code
you will see the following at the top in the provider configuration:

    provider "aws" {
      region     = "ap-southeast-2"
      profile    = "terraform"
    }

This means Terraform will use the specified AWS profile, and thus will
use the IAM access key associated with our ‘study’ user.

# Azure

# GCP
