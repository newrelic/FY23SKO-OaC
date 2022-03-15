# Setting up Terraform

## Download files locally

If you haven't already make sure to download all the files locally. You can do that by cloning this repository to your local machine either through Git `git clone https://github.com/kidk/FY23SKO-OaC.git`, or using the following link: [Download repository](https://github.com/kidk/FY23SKO-OaC/archive/refs/heads/main.zip)

## Configure Terraform

1. Open `providers.tf` in your favorite editor and read the comments to learn how Terraform, the New Relic Terraform provider and AWS was configured in this project.

2. Run the commands below to create your own configuration file containing the credentials needed for Terraform to connect to New Relic and AWS.

```
cp configuration.sh.example configuration.sh
```

3. Open `configuration.sh` in your favorite editor and follow the instructions to configure your authentication credentials.

4. Run the following commands to validate your configuration. If you get any errors, double check the `configuration.sh` file.

```shell
# First we load your configuration settings, it should output your New Relic Account ID
source ./configuration.sh

# Second we initiate Terraform to download the latest version of the providers
terraform init

# Now let's test our credentials and see if everything is configured correctly
# The following command shows what Terraform is going to change for you, it's a great
# way to test your code, as it won't initiate any changes for you.
terraform plan
```

The output should look something like this for `terraform init`:
```
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 3.0"...
- Finding newrelic/newrelic versions matching "~> 2.35.1"...
- Installing hashicorp/aws v3.74.0...
- Installed hashicorp/aws v3.74.0 (signed by HashiCorp)
- Installing newrelic/newrelic v2.35.1...
- Installed newrelic/newrelic v2.35.1 (signed by a HashiCorp partner, key ID DC9FC6B1FCE47986)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

and something like this for `terraform plan`:
```
No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
```

If you get any errors like below, or others, double check your authentication parameters, or ask for help from your colleagues or the workshop staff.

```
│ Error: error initializing newrelic-client-go: must use at least one of: ConfigPersonalAPIKey, ConfigAdminAPIKey, ConfigInsightsInsertKey
│
│   with provider["registry.terraform.io/newrelic/newrelic"],
│   on providers.tf line 35, in provider "newrelic":
│   35: provider "newrelic" {
```

## That's it

Well done, you've set up Terraform so it's ready for the next session. It's now time to move over to Part 2 of the workshop: [Creating Synthetic scripts, alerts and dashboards with Terraform](./Part_2-Creating_New_Relic_Resources_With_Terraform.md)
