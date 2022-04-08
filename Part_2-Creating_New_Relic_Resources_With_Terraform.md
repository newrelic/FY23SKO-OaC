# Part 2: Creating New Relic Resources with Terraform
In this exercise you are going to create an alert, notification channel and some synthetics in New Relic via terraform and you will test it works by sending some test data.

Pre-requsites:

1. A text editor such as VS Code
2. A New Relic account that you can create ingest API tokens for
3. The output of part 1

If you get stuck then refer to the [reference example](./reference/Part_2/newrelic.tf), but try to peek at that only as a last resort once you have tried fixing you own code ;)

## Step 1: Configure terraform
You should already have the [providers.tf](./providers.tf) and [configuration.sh](./configuration.sh.example) file and terraform installed and initialised from Part 1. If not refer to ["Part 1: Setting Up Terraform" instructions](./Part_1-Setting_up_Terraform.md) to get up and running.


## Step 2: Lights on the board
Your first step is to make sure that everything is configured correctly. You'll create an alert policy in the your test New Relic account and confirm it appears.

Create a new file called `newrelic.tf`  and add the following code, **remembering to change YOUR_USERNAME to your New Relic user name!**:
```terraform
resource "newrelic_alert_policy" "policy" {
  name = "YOUR_USERNAME alert policy"
  incident_preference = "PER_POLICY"
}
```

Now `source` the configuration file  if you havent already done so (you only need to do this once) and then run the terraform plan to see what changes are suggested.

```bash
source ./configuration.sh
terraform plan
```

You should see something like this:

```
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # newrelic_alert_policy.policy will be created
  + resource "newrelic_alert_policy" "policy" {
      + account_id          = (known after apply)
      + id                  = (known after apply)
      + incident_preference = "PER_POLICY"
      + name                = "jbuchanan terraform alert policy"
    }

Plan: 1 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```

Now *apply* the configuration with:

```bash
terraform apply
```

This should apply the configuration and let you know what was created like this:
```
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

Go to you New Relic One account and navigate to the Alerts secition and then select **"Alert conditions (Policies)"** and you should find your new alert policy called "**YOUR_USERNAME** terraform alert policy". If it's there then well done, you've created your first New Relic resource via terraform!

> If you don't see your policy then double check your API keys, account number and configuration. If necessary compare to the [reference](./reference/Part_2/newrelic.tf) example.


## Step 3: Add an NRQL Condition to the policy
An alert policy with no conditions is not very useful. You need to add an alert condition to the policy your created above. To do this we will use the documentation to find the resource we need and utilise the examples to configure it.

> It's important to understand where to find the right documentation and how to use it, so this entire exercise will require you to find examples in online documentation and use them in your code.

Start by finding the New Relic Terraform Provider documentation. Open up your favourite search engine and search for **"new relic terraform provider"**, with any luck the first result will take you to our [New Relic Terraform Provider docs](https://registry.terraform.io/providers/newrelic/newrelic/latest/docs).

In the "resources" section find the **"newrelic_nrql_alert_condition"** resource documentation. (Can't find it? Try [here](https://registry.terraform.io/providers/newrelic/newrelic/latest/docs/resources/nrql_alert_condition)) There are plenty of examples in the documentation that you can copy and paste and then amend. Notice in the **first example** there are two resources, the **"new_relic_alert_policy"** resource which you have already got in your project and the **"newrelic_nrql_alert_condition"** resource.

Copy and paste *just* the larger **"newrelic_nrql_alert_condition"** configuration block from the **first example**  into `newrelic.tf` under the resource we added earlier.

```terraform
resource "newrelic_nrql_alert_condition" "foo" {
 ... Find the newrelic_nrql_alert_condition resource in the example in the documentation and copy the entire block into your newrelic.tf ...
}
```

You need to tidy this example up and configure it to your own needs. You can refer to the documentation to understand all the configuration options here but for now make the following changes:
1. The resource  itself is called "foo" rename it to "demo"
2. `account_id`: Set this value to `var.NEW_RELIC_ACCOUNT_ID`
3. `policy_id`: This controls which policy the condition is a member of, we need to supply the ID of the policy we created above. To do this set the value to `newrelic_alert_policy.policy.id` (our policy resource is named "policy" not "foo"!)
4. `name`: This is the name of the condition as it appears in New Relic. Set it to the following but using your username: `"YOUR_USERNAME Demo alert condition"`.
5. Delete the `description` and `runbook_url` attributes, you won't use them today.
6. `aggregation_method`: Set this to `"event_timer"`
7. **Add** an attribute `aggregation_timer` with a value of `60`
8. Delete `aggregation_delay`, `expiration_duration`, `open_violation_on_expiration` and `close_violations_on_expiration`. These settings control signal loss which you want to disable for this example.
9. `slide_by`: Set this to zero.
10. `nrql > query`: This is an NRQL condition so you need to specify the NRQL here, set the value to: `select count(*) from tfdemo` (This "tfdemo" event type doesnt exist yet, we'll deal with that later.)
11. In the `critical` block make the following changes:
    - set the `threshold` to `0` and
    - set the `threshold_duration` to `120`
    - set the `threshold_occurrences` to `"at_least_once"`
12. Delete the entire `warning` block, you don't need warnings for this example.

Run `terraform apply` and you **should get an error** like this:

```
│ Error: Reference to undeclared input variable
│
│   on newrelic.tf line 9, in resource "newrelic_nrql_alert_condition" "demo":
│    9:   account_id                     = var.NEW_RELIC_ACCOUNT_ID
│
│ An input variable with the name "NEW_RELIC_ACCOUNT_ID" has not been declared. This variable can be declared with a variable "NEW_RELIC_ACCOUNT_ID" {} block.
```

---

### A side note on variables!
Why did you get an error here? Well you have supplied as the value for the `account_id` attribute an input variable called `var.NEW_RELIC_ACCOUNT_ID`. In terraform you can supply and use variables but you *must* define the variables you plan to use before using them.

> In this case the value for the account ID is passed in automatically via an environment variable in [configuration.sh](./configuration.sh.example#L26). In terraform any environment variable prefixed "TF_VAR" such as "TF_VAR_WHATEVER" becomes an input variable called "WHATEVER". So in our case the environment variable `TF_VAR_NEW_RELIC_ACCOUNT_ID`, which contains your account ID, is mapped to the variable `NEW_RELIC_ACCOUNT_ID`.

So, you need to **fix this** by defining the input variable you plan to use. Variables tend to be put at the top of the file or in their own `variables.tf` file. For now just add the following right at the top of `newrelic.tf`:
```terraform
variable "NEW_RELIC_ACCOUNT_ID" { type = string }
```

This tells terraform that we will be supplying a variable called `NEW_RELIC_ACCOUNT_ID` and that it should be a `string`. Terraform lets you define all [shapes and sizes of variable](https://www.terraform.io/language/values/variables) and set default values too.

---

Now run `terraform apply` again and it should succeed:

```
newrelic_nrql_alert_condition.demo: Creating...
newrelic_nrql_alert_condition.demo: Creation complete after 5s [id=1863121:23885590]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

Check in New Relic One that the condition has indeed been created.

> What did this all do? It created an NRQL alert condition that will fire if the count of records in tfdemo event is non-zero. Once you've applied the configuration take a look at the settings of the condition within the New Relic One to understand it better.


## Step 4: Add a notification channel
When an alert fires it should notify someone. You're going to send your alert notifications to Slack! The first one there might win a prize! We will use the documentation to learn how to add a notification channel to the project.

Look for the **"newrelic_alert_channel"** resource in the documentation and find the Slack example low down on the page in the "Additional examples" section. (Can't find the docs? Try [here](https://registry.terraform.io/providers/newrelic/newrelic/latest/docs/resources/alert_channel)) Copy the Slack example into `newrelic.tf` beneath the alert condition you added previously.

```terraform
resource "newrelic_alert_channel" "foo" {
 ... Find the slack example in the example in the docs and copy into your newrelic.tf ...
}
```

As with the previous task you'll use this example code as a basis for your own and make changes accordingly. Update as follows:

1. Change the resource name from "foo" to "sko_slack" (note the underscore here!)
2. `name`: Set this to the value "**YOUR_USERNAME** SKO Slack Channel" - this is the name that will appear in the New Relic One
3. `config.url`: Set this to the URL of the Slack webhook found in the [session credentials document](https://bit.ly/oac-sko-fy23).
4. `config.channel`: Set this to `fy23sko-oac-session`

Run `terraform apply` and observe the notification channel has been created by viewing it in New Relic One.

## Step 5: Connect the notification channel
You have created an alert policy and a notification channel, but you haven't connected them together. Multiple policies may leverage a single channel so this step is done seperately.

Find the **"newrelic_alert_policy_channel"** resource documentation. (Can't find the docs? Try [here](https://registry.terraform.io/providers/newrelic/newrelic/latest/docs/resources/alert_policy_channel)) This is the resource that subscribes channels to policies and the docs has a full example. Copy and paste **just the last resource** `newrelic_alert_policy_channel` from the first example into the end of `newrelic.tf`:

```terraform
resource "newrelic_alert_policy_channel" "foo" {
    ... Find the newrelic_alert_policy_channel resource in the documentation example and copy into your newrelic.tf ...
}
```

Same as above you will need update the example to suit your needs:

1. Change the name of the resource from "foo" to "subscribe"
2. `policy_id`: This is where you identify the policy you're adding the channel to, in this case you need to reference the policy you created abiove. Set the value to: `newrelic_alert_policy.policy.id`
3. The `channel_ids` attribute is a list of channels IDs. You only have one channel, so set the value to reference your single channel like this: `[newrelic_alert_channel.sko_slack.id]`


Apply this change with `terraform apply` and confirm in New Relic One that your alert policy now has a notification channel attached.

---

### A side note about referencing resources
Whilst we're here lets talk about resource referencing. In the step above you connected the alert policy resource you created initially to the notification channel resource. When you refer to a resource in terraform you specify its attributes in the following format:

```
<resource_type>.<resource_name>.<attribute>
```

So in your case you needed to supply the `id` of the resource type `newrelic_alert_policy` named `policy`:

```
newrelic_alert_policy.policy.id
```

## Step 6: Testing the alert
Everything is now setup and your alert policy and condition is diligently looking for problems. Lets send some data to trigger the alert and light up the slack channel.

Update the command below with an **ingest license key** (remember, this is your Ingest Licence key and not User Licence Key) and your **account ID**, then run it a few times in your terminal to generate data. You should shortly see your alert policy trigger and with any luck your name appear in the slack channel!

Use this command if your account is in the **US** data centre:
```bash
curl -X POST -H "Content-Type: application/json" \
-H "Api-Key: LICENSE-KEY-HERE" \
https://insights-collector.newrelic.com/v1/accounts/ACCOUNT-ID-HERE/events \
--data '[
  {
    "eventType":"tfdemo",
    "apples":1
  }
]'
```

Use this command if your account is in the **EU** data centre:
```bash
curl -X POST -H "Content-Type: application/json" \
-H "Api-Key: LICENSE-KEY-HERE" \
https://insights-collector.eu01.nr-data.net/v1/accounts/ACCOUNT-ID-HERE/events \
--data '[
  {
    "eventType":"tfdemo",
    "apples":1
  }
]'
```

Ensure you get a response like this with **`"success:true"`** in it. If not double check you've included an ingest key (not a user key!) and your account ID in the correct places:
```json
{"success":true, "uuid":"0b92fafc-0001-b000-0000-017f277bfc27"}
```


## Step 7: Dynamically generated resources
So far you have created single resources. One of terraform's super powers is its ability to generate multiple resources automatically. In this step you will generate multiple synthetic ping monitors.

Find the **"newrelic_synthetics_monitor"** resource in the documentation (Can't find it? Try [here](https://registry.terraform.io/providers/newrelic/newrelic/latest/docs/resources/synthetics_monitor)).

As before you need to start by copying the first example found in the documentation into the end of `newrelic.tf`.

```terraform
resource "newrelic_synthetics_monitor" "foo" {
  ... Copy the resource from the first example in the documentation into your newrelic.tf ...
}
```

Make the following changes to the example:

1. Change the name of the resource from **"foo"** to **"ping"**
2. `name`: set this attribute to `"SKO Ping New Relic"`
3. `locations`: Two locations is a bit much for this exercise, so change the value to target a single location: `["AWS_US_EAST_1"]`
4. `uri`: Set this to `"https://newrelic.com/"`
5. Delete the `validation_string` attribute.

Run `terraform apply` and confirm the basic Ping synthetic appears in your New Relic One account.

---
Now you have this basic ping monitor in place you will update it use terraforms ability to generate resources to test multiple URLs. To do this we need to specify the list of URL's, you will use a local variable for this. Add the following code just above the `newrelic_synthetics_monitor` resource you just created (it doesnt actually matter where it goes in the file but it makes sense to put it above the synthetic resource):

```terraform
locals {
  pingURLs = [
    {
      name = "New Relic"
      uri = "https://newrelic.com"
    },
    {
      name = "NR Developer Site"
      uri = "https://developer.newrelic.com"
    },
    {
      name = "NR Learn Site"
      uri = "https://learn.newrelic.com"
    }
  ]
}
```

You can see this variable contains an array of three URI's to check. Now go back and update the `newrelic_synthetics_monitor` you created before with the following changes:

1. Add a **new** attribute `count` and set its value to `length(local.pingURLs)`. *This attribute is conventionally added as the first attribute.*
2. Change the value of `name` to `"SKO Ping ${local.pingURLs[count.index].name}"`
3. Change the value of `uri` to `local.pingURLs[count.index].uri` (no quotes!)

Run `terraform apply` and confirm that you can see all three synthetic monitors in your account.

### Whoa! What happened here?
Providing a [count](https://www.terraform.io/language/meta-arguments/count) attribute to a resource instructs terraform to generate multiple copies of that resource. You specify how many resources you want, in this case the length of the array `local.pingURLs`, which is three.

The `name` and `uri` attributes use `count.index` to reference the elements of the array. For `name` we need to use interpolation `${...}` syntax to include the variable within the string. For the `uri` we don't need that interpolation syntax as we're using the value directly.


## Step 8: Wrapping Up
In this exercise you learned how to setup New Relic resources using the terraform provider. You know where to find the documentation and how to use it and the examples to construct your terraform code. Hopefully you can see how generating resources from simple configuration is also possible. Not only can you generate multiple copies of a single resource but you can also call entire modules that generate multiple sub resources. *Creating three or three hundred ping monitors is almost as easy as creating one!*

You can now go on and apply what you have learned to create synthetic journeys, dashboards, workloads and all manner of other New Relic resources that are supported by the provider.

If you wish to tear down the resources you created in your New Relic account run the **destroy** command. This will delete all the resources managed by terraform in this exercise in one go. You can try this now:

```bash
terraform destroy
```

You can re-create all your resources again by running:
```bash
terraform apply
```

---
You can now proceed to [Part 3 - Deploying New Relic](./Part_3-Deploying_New_Relic.md)

## Further reading
There is a lot to learn about terraform and their documentation is very good. Its worth understanding what terraform state is and how it might be managed. Its also really useful to know how to create your own modules that will allow you to package up a number of resources into a easy to use package.

- [Terraform state explained](https://www.terraform.io/language/state)
- [Getting Started with Terraform (guided demo)](https://developer.newrelic.com/automate-workflows/get-started-terraform/)
- [Using terraform modules and remote state storage (guided demo)](https://developer.newrelic.com/terraform/terraform-modules/)
- [Using terragrunt for managing multiple environments (guided demo)](https://developer.newrelic.com/terraform/terragrunt-configuration/)
- [Simple Terraform Boilerplate](https://github.com/jsbnr/nr-simple-terraform-boilerplate)
- [Automated Github workflow template](https://github.com/jsbnr/nr-terraform-workflow-template)
