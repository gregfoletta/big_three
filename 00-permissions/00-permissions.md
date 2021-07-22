    knitr::opts_chunk$set(engine.opts = list(zsh = '-i'))

It’s very tempting to get straight into creating infrastructure, however
we want to make sure that security is built-in from the start. Applying
everything using a super user account is not (generally) a privilege
we’re going to have in the real world.

For each of the cloud providers, what we want to do is set up a
ring-fenced area for our study. Then when we use Terraform we will
authenticate using an account that *only* has access to this area. This
limits our blast radius to an area where we can create and destroy
resources without worrying about accidentally “bringing down
production”.

The selections below are our foundational set up before we start to use
Terraform. This chapter is unique in thatg we’ll be solely using each
cloud provider’s CLI tool to do the configuration. Subsequent chapters
will almost always use Terraform, unless there’s something that it can’t
do.

# AWS

Of the three cloud providers, it seems AWS (and I am happy to be
corrected here) is the most diffucult to ring-fence access in. As you’ll
see below, Azure have resource groups and GCP has projects that we can
limit a service account to, whereas AWS does not have this. Instead,
we’ll use tags in conjunction with access policies to limit our access.

In our first step, we’ll create a ‘study’ user, a ‘study’ group, and add
that user to the group:

    # Create the user, the group, and add the user to the group
    aws iam create-user --user-name study --path "/users/"
    aws iam create-group --group-name study --path "/groups/"
    aws iam add-user-to-group --user-name study --group-name study

    ## {
    ##     "User": {
    ##         "Path": "/users/",
    ##         "UserName": "study",
    ##         "UserId": "AIDA5BTYAKZGHYUDEE7RQ",
    ##         "Arn": "arn:aws:iam::896826103372:user/users/study",
    ##         "CreateDate": "2021-07-22T02:32:33Z"
    ##     }
    ## }
    ## {
    ##     "Group": {
    ##         "Path": "/groups/",
    ##         "GroupName": "study",
    ##         "GroupId": "AGPA5BTYAKZGH4YGS3BLB",
    ##         "Arn": "arn:aws:iam::896826103372:group/groups/study",
    ##         "CreateDate": "2021-07-22T02:32:34Z"
    ##     }
    ## }

The ‘path’ variable I’ve specified is optional, but it allows us to
structure the users and groups we create. This can help when you’re
referring to groups or users using their arn. For example you could
refer to all groups under ‘/groups/business\_unit\_a/’ using the arn
`arn:aws:iam:<account_id>:group/groups/business_unit_a/*`.

Now we generate an access key that we’ll use to authenticate. I write it
out to a file, but I’ve also made sure I add the line "\*.priv.txt" to
my .gitignore file to I don’t accidentally advertise my IAM key to the
whole world.

    # Generate the access key
    aws iam create-access-key --user-name study > aws_study_access_key.priv.txt

    # Print out but redact what was returned
    jq '.AccessKey.SecretAccessKey = "<REDACTED>"' aws_study_access_key.priv.txt

    ## {
    ##   "AccessKey": {
    ##     "UserName": "study",
    ##     "AccessKeyId": "AKIA5BTYAKZGDLOWMOPH",
    ##     "Status": "Active",
    ##     "SecretAccessKey": "<REDACTED>",
    ##     "CreateDate": "2021-07-22T02:32:37Z"
    ##   }
    ## }

We then create a new profile using the AWS CLI using the command
`aws configure --profile terraform`. In all subsequent Terraform code
you will see the following at the top in the provider configuration:

    provider "aws" {
      region     = "ap-southeast-2"
      profile    = "terraform"
    }

This results in Terraform using the specified AWS CLI profile, and thus
will use the IAM access key associated with our ‘study’ user.

We won’t go into the specific IAM policies that we will apply at each
stage in this section. We’ll define and discuss the required policies at
the start of each chapter.

# Azure

Azure makes things easier for us, we:

-   create a resource group that will contains all of our resources
-   Create a ‘Service Principal’ which we will use to authenticate
-   Add this service principal to the resource group as a contributer.

First off, let’s create our resource group:

    az group create --name study --location australiasoutheast

    ## {
    ##   "id": "/subscriptions/251d8e18-0d26-4645-ae17-8db0b1f2f0b6/resourceGroups/study",
    ##   "location": "australiasoutheast",
    ##   "managedBy": null,
    ##   "name": "study",
    ##   "properties": {
    ##     "provisioningState": "Succeeded"
    ##   },
    ##   "tags": null,
    ##   "type": "Microsoft.Resources/resourceGroups"
    ## }

Next we create the service principal. We’ll use a self signed X509
certificate to authenticate. The below openssl commands:

-   Create the RSA key and certificate signing request
-   Sign the CSR to create our certificate
-   Combine the key and certificate into a PKCS12 file (with no
    password)

We’ll store these files outside of this repository in a home directory.

    # Create the RSA key and CSR
    openssl req -newkey rsa:4096 -nodes -keyout "$HOME/.azure/sp.key" -out "/tmp/sp.csr" -config "azure/openssl_req_opts"
    # Sign the CSR with our key to create a self signed cert
    openssl x509 -signkey "$HOME/.azure/sp.key" -in "/tmp/sp.csr" -req -days 365 -out "$HOME/.azure/sp.crt"
    # Combine into a PKCS12 file
    openssl pkcs12 -export -out "$HOME/.azure/sp.pfx" -inkey "$HOME/.azure/sp.key" -in "$HOME/.azure/sp.crt" -passout "pass:"

    ## Generating a RSA private key
    ## ......................................................................++++
    ## .......................................................................................................................++++
    ## writing new private key to '/home/puglet/.azure/sp.key'
    ## -----
    ## Signature ok
    ## subject=C = AU, O = foletta.org, CN = Big Three Study
    ## Getting Private key

With our self-signed certificate, we can create our service principal in
Azure:

    az ad sp create-for-rbac \
        --skip-assignment \
        --cert @~/.azure/sp.crt \
        > azure_sp_cred.priv.txt

    ## WARNING: Certificate expires 2022-07-22 02:32:40+00:00. Adjusting SP end date to match.
    ## WARNING: The output includes credentials that you must protect. Be sure that you do not include these credentials in your code or check the credentials into your source control. For more information, see https://aka.ms/azadsp-cli
    ## WARNING: 'name' property in the output is deprecated and will be removed in the future. Use 'appId' instead.

Here’s what the response looks like. As we’re authenticating using a
certificate, none of these values are considered secret.

    jq -r '.' azure_sp_cred.priv.txt

    ## {
    ##   "appId": "915fe182-ea4b-401d-abb1-f277a6aae4f2",
    ##   "displayName": "azure-cli-2021-07-22-02-32-40",
    ##   "name": "915fe182-ea4b-401d-abb1-f277a6aae4f2",
    ##   "password": null,
    ##   "tenant": "c58cb715-fe75-4057-ae57-5a88a3dd7fa4"
    ## }

We now add this service principal as a contributor to the ‘study’
resource group.

    az role assignment create \
        --assignee $(jq -r '.appId' azure_sp_cred.priv.txt) \
        --role "Contributor" \
        --resource-group "study"

    ## {
    ##   "canDelegate": null,
    ##   "condition": null,
    ##   "conditionVersion": null,
    ##   "description": null,
    ##   "id": "/subscriptions/251d8e18-0d26-4645-ae17-8db0b1f2f0b6/resourceGroups/study/providers/Microsoft.Authorization/roleAssignments/dd8282f4-b9cf-4e96-b5c0-c92af71bd157",
    ##   "name": "dd8282f4-b9cf-4e96-b5c0-c92af71bd157",
    ##   "principalId": "342b6bb3-bcc8-4d61-b2e8-321e972edad3",
    ##   "principalType": "ServicePrincipal",
    ##   "resourceGroup": "study",
    ##   "roleDefinitionId": "/subscriptions/251d8e18-0d26-4645-ae17-8db0b1f2f0b6/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c",
    ##   "scope": "/subscriptions/251d8e18-0d26-4645-ae17-8db0b1f2f0b6/resourceGroups/study",
    ##   "type": "Microsoft.Authorization/roleAssignments"
    ## }

Now within the provider section of the Terraform code we can add the
following to authenticate as the ‘study’ service principal:

    provider "azurerm" {
      features {}

      subscription_id             = "251d8e18-0d26-4645-ae17-8db0b1f2f0b6"
      client_id                   = "5a9e35fa-1da9-499a-95e7-5b18af9b69a4"
      client_certificate_path     = pathexpand("~/.azure/sp.pfx")
      tenant_id                   = "c58cb715-fe75-4057-ae57-5a88a3dd7fa4"
    }

# GCP

GCP also makes things relatively easy for us. We will:

-   Create a ‘project’, much like the Azure ‘resource group’.
-   Create a service account.
-   Generate and save the keys.

First up, we create the project and enable it to bill. At this point,
the ‘gcloud’ CLI is authenticated with a super user account.

    # Create the GCP project
    gcloud projects create prj-gf-study-2 --name study
    # Enable billing
    GCP_BILLING_ID=$(gcloud beta billing accounts list --format json | jq -r '.[] | select(.displayName=="foletta.org") | .name')
    gcloud beta billing projects link prj-gf-study-2 --billing-account=$GCP_BILLING_ID

    ## Create in progress for [https://cloudresourcemanager.googleapis.com/v1/projects/prj-gf-study-2].
    ## Waiting for [operations/cp.5917673829260903081] to finish...
    ## ..done.
    ## Enabling service [cloudapis.googleapis.com] on project [prj-gf-study-2]...
    ## Operation "operations/acf.p2-32906494330-2e15ee6f-c2d6-443f-b3b7-45043b9cf367" finished successfully.
    ## billingAccountName: billingAccounts/01F6E6-5C7544-A9409A
    ## billingEnabled: true
    ## name: projects/prj-gf-study-2/billingInfo
    ## projectId: prj-gf-study-2

Next, we create the service account, generate and then save the
authentication keys.

    # Create the service account
    gcloud iam service-accounts create sa-study --display-name study --project prj-gf-study-2
    # Generate and save the keys for the service account
    gcloud iam service-accounts keys create ~/.gcloud/keys/sa-study.json --iam-account=sa-study@prj-gf-study-2.iam.gserviceaccount.com

    ## Created service account [sa-study].
    ## created key [0bf59d73fd76a0df7ba743eb5f6658d3ac604674] of type [json] as [/home/puglet/.gcloud/keys/sa-study.json] for [sa-study@prj-gf-study-2.iam.gserviceaccount.com]

You can see the returned structure here, with the key ID and key
redacted:

    jq '.+{private_key_id:"<REDACTED>", private_key: "<REDACTED>"}' ~/.gcloud/keys/sa-study.json

    ## {
    ##   "type": "service_account",
    ##   "project_id": "prj-gf-study-2",
    ##   "private_key_id": "<REDACTED>",
    ##   "private_key": "<REDACTED>",
    ##   "client_email": "sa-study@prj-gf-study-2.iam.gserviceaccount.com",
    ##   "client_id": "103373026395117843334",
    ##   "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    ##   "token_uri": "https://oauth2.googleapis.com/token",
    ##   "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    ##   "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/sa-study%40prj-gf-study-2.iam.gserviceaccount.com"
    ## }

We then authorise access to GCP using this service account. This allows
the ‘gcloud’ CLI tool (and thus Terraform, which uses this under the
hood) to make requests using the service account:

    gcloud auth activate-service-account sa-study@prj-gf-study-2.iam.gserviceaccount.com \
        --key-file=$HOME/.gcloud/keys/sa-study.json \
        --project=prj-gf-study-2

    ## Activated service account credentials for: [sa-study@prj-gf-study-2.iam.gserviceaccount.com]

Finally, we switch the gcloud CLI tool to use our service account to
make requests, rather than the super user account we were using
previously:

    gcloud config set account sa-study@prj-gf-study-2.iam.gserviceaccount.com

    ## Updated property [core/account].

Now when we use Terraform with a GCP provider, it will make authenticate
using the current active account.
