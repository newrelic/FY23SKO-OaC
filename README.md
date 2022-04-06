[![Community Project header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Project.png)](https://opensource.newrelic.com/oss-category/#community-project)

# Observability as Code Workshop

This repository contains all the instructions and files needed to get a first introduction into Observability as Code. The workshop includes 5 parts, which focus on Terraform, Ansible and the CLI.

## Requirements

* Laptop with Mac OS X. Windows is not supported for this workshop
* [Homebrew](https://brew.sh/)
* [Visual Studio Code](https://code.visualstudio.com/) or another code editor
* Terraform / Ansible / New Relic CLI / Git: `brew install terraform ansible newrelic-cli git`
* (Optional, if needed) Apple Command Line Tools: `xcode-select --install`

You can check if everything is installed correctly by running the following commands:

```
terraform -v
ansible --version
newrelic -v
git --version
```

You should get output similar to this. The version numbers don't need to be exactly the same.
```
terraform -v
ansible --version
newrelic -v
git --version
Terraform v1.1.5
on darwin_amd64
+ provider registry.terraform.io/hashicorp/aws v3.74.0
+ provider registry.terraform.io/newrelic/newrelic v2.35.1

ansible [core 2.12.1]
  config file = None
  configured module search path = ['/Users/samuel/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/local/Cellar/ansible/5.2.0/libexec/lib/python3.10/site-packages/ansible
  ansible collection location = /Users/samuel/.ansible/collections:/usr/share/ansible/collections
  executable location = /usr/local/bin/ansible
  python version = 3.10.1 (main, Dec  6 2021, 22:25:40) [Clang 13.0.0 (clang-1300.0.29.3)]
  jinja version = 3.0.3
  libyaml = True
newrelic version 0.41.17
git version 2.34.1
```

## Getting Started

Clone this repository to your local machine either through Git `git clone https://github.com/newrelic/FY23SKO-OaC.git`, or using the following link: [Download repository](https://github.com/newrelic/FY23SKO-OaC/archive/refs/heads/main.zip)

* Part 1: [Setting up Terraform](./Part_1-Setting_up_Terraform.md)
* Part 2: [Creating New Relic Resources with Terraform](./Part_2-Creating_New_Relic_Resources_With_Terraform.md)
* Part 3: [Deploy an AWS EC2 instance and deploy New Relic with Ansible](./Part_3-Deploying_New_Relic.md)
* Part 4: [Enabling New Relic Cloud Integrations](./Part_4-Enabling_cloud_integrations.md)
* Part 5: [Bonus Round! Common CLI use-cases](./Part_5-Bonus_round_CLI.md)

## Support

If you're completing the workshop during a New Relic session, please flag the session organisers for support. If you are doing this on your own, feel free to create a Github ticket so the workshop creators can help you.

## Contribute

We encourage your contributions to improve Observability as Code workshop! Keep in mind that when you submit your pull request, you'll need to sign the CLA via the click-through using CLA-Assistant. You only have to sign the CLA one time per project.

If you have any questions, or to execute our corporate CLA (which is required if your contribution is on behalf of a company), drop us an email at opensource@newrelic.com.

**A note about vulnerabilities**

As noted in our [security policy](../../security/policy), New Relic is committed to the privacy and security of our customers and their data. We believe that providing coordinated disclosure by security researchers and engaging with the security community are important means to achieve our security goals.

If you believe you have found a security vulnerability in this project or any of New Relic's products or websites, we welcome and greatly appreciate you reporting it to New Relic through [HackerOne](https://hackerone.com/newrelic).

If you would like to contribute to this project, review [these guidelines](./CONTRIBUTING.md).

To all contributors, we thank you!  Without your contribution, this project would not be what it is today.

## License
Observability as Code workshop is licensed under the [Apache 2.0](http://apache.org/licenses/LICENSE-2.0.txt) License.
