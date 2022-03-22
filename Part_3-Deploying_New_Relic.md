# Deploy an AWS EC2 instance and deploy New Relic with Ansible

Now that you've learned how to create dashboard, alerts and synthetic with Terraform, let's take a look at another Terraform use case. In this exercise we will show how to manage your infrastructure through Terraform. This is a typical use-case customers will have where they will create their AWS EC2 instances through Terraform, and deploy New Relic to monitor, all automatically.

Pre-requisites:

1. A text editor such as VS Code
2. A New Relic account that you can create Ingest API tokens for
3. AWS Authentication tokens (The SKO team will provide these for you)

If you get stuck then refer to the [reference example](./reference/Part_4/aws-ec2.tf), but try to peek at that only as a last resort once you have tried fixing you own code ;)


## Spin up an EC2 instance

1) Let's first create a file in the root directory (where `providers.tf` is located) to put your configuration for the EC2 instance. Terraform allows you to make as many files ending with `.tf` as you want, it will automatically pick them up when running `terraform apply` or `terraform plan`. This is a great way to structure your Terraform configuration.

Use your favorite editor to create the following file `aws-ec2.tf`.

2) Now you need to tell Terraform to create an EC2 instance. For that you will use the `aws_instance` resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

Below is a simple example to get started. You first get the most recent image or AMI for Ubuntu 20.04 from Amazon. This a great example of the difference between a `resource` (`resource "aws_instance" "web"`) and `data` (`data "aws_ami" "ubuntu"`). `data` is used to get information or configuration, `resource` is used to set or update configuration. For example in this case you don't want to create a new Amazon image (AMI), but want to use an existing one, so you use `data`. But you do want to create a new EC2 instance, and not use an existing one, so you use `resource`.

```
# Get the most recent image for Ubuntu 20.04
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
}
```

Once you copied the code into the `aws-ec2.tf` file and saved it. Run `terraform apply` to spin up your EC2 instance.

You will get a long output that looks something like this:

```
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following
symbols:
  + create

Terraform will perform the following actions:

  # aws_instance.web will be created
  + resource "aws_instance" "web" {
      + ami                                  = "ami-01b996646377b6619"
      + arn                                  = (known after apply)
...
```

Go ahead and apply that by typing `yes` + enter.

```
aws_instance.web: Creating...
aws_instance.web: Still creating... [10s elapsed]
aws_instance.web: Creation complete after 17s [id=i-0aa82fb62183b7f96]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

Congrats you've just created your first EC2 compute instance through Terraform.

3) Now wouldn't it be great if you could connect to it?

You've now configured your instance to spin up, but no way to connect to it. So let's change that by adding some network configuration, copy our local ssh key, and output the public IP address of your server. A private key is needed to connect to your machine, generate one for yourself locally using the command below:

`ssh-keygen -m PEM -f ~/.ssh/skofy23.pem`

You don't need to enter a passphrase, you can just leave it empty.

```
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /Users/samuel/.ssh/skofy23.pem
Your public key has been saved in /Users/samuel/.ssh/skofy23.pem.pub
The key fingerprint is:
SHA256:uCyIk/gkcELI5w/verysecretstuff samuel@C02XF59LJG5J
The key's randomart image is:
+---[RSA 3072]----+
|                 |
|   000     000   |
|   000     000   |
|   000     000   |
|                 |
|                 |
|   XX       XX   |
|    XXXXXXXX     |
|                 |
+----[SHA256]-----+
```

Copy the code below to the top of your `aws-ec2.tf` file.

```
data "aws_vpc" "web_vpc" {
  default = true
}

resource "aws_security_group" "web_security_group" {
  vpc_id = data.aws_vpc.web_vpc.id
}

resource "aws_security_group_rule" "web_security_group_rule_egress" {
  security_group_id = aws_security_group.web_security_group.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "web_security_group_rule_ingress" {
  security_group_id = aws_security_group.web_security_group.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

output "ec2instance" {
  value = aws_instance.web.public_ip
}

// We generate a random string for the aws_key_pair so you don't have collisions with other users
resource "random_string" "user" {
  length  = 6
  upper   = false
  lower   = true
  number  = true
  special = false
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-${random_string.user.result}"
  public_key = file("~/.ssh/skofy23.pem.pub")
}
```

Now you need to assign this network configuration to your machine, you can do so by adding the following code snippet to the `resource "aws_instance" "web"` resource.

```
key_name = aws_key_pair.deployer.id
vpc_security_group_ids = [aws_security_group.web_security_group.id]
associate_public_ip_address = true
```

It should look something like this:
```
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  key_name = aws_key_pair.deployer.id
  vpc_security_group_ids = [aws_security_group.web_security_group.id]
  associate_public_ip_address = true
}
```

Once you copied the code into the `aws-ec2.tf` file and saved it. Run `terraform apply` to update your EC2 instance with the new network configuration. While you wait for the command to finish take a look at all the changes you did, and try to find out what they're doing.

The output after confirming the change (`Enter a value: yes`) should look something like this:

```
aws_instance.web: Creating...
aws_security_group_rule.web_security_group_rule_egress: Creation complete after 3s [id=sgrule-1670264497]
aws_security_group_rule.web_security_group_rule_ingress: Creation complete after 5s [id=sgrule-1720592362]
aws_instance.web: Still creating... [10s elapsed]
aws_instance.web: Creation complete after 17s [id=i-0759b1faa54779e31]

Apply complete! Resources: 5 added, 0 changed, 1 destroyed.

Outputs:

ec2instance = "44.201.195.165"
```

Notice that you received an IP Address (value of `ec2instance`) at the end of the output. Write that down so you can use it later, you can also see it again by typing `terraform output`. This is a great example how Terraform is a two way system, you can send a configure, but you can also retrieve and use data from the provider.

You can test connecting to your machine by running the following command: `ssh -i ~/.ssh/skofy23.pem ubuntu@SERVER_IP_ADDRESS`. Accept `yes` if it asks you to confirm the connection

```
ssh -i ~/.ssh/skofy23.pem ubuntu@44.201.195.165                   ✔  took 1m 41s
The authenticity of host '44.201.195.165 (44.201.195.165)' can't be established.
ED25519 key fingerprint is SHA256:kyCj12vslrvLNaLTWHspjr7jHireuEHdcfc5xVY0DmM.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '44.201.195.165' (ED25519) to the list of known hosts.
Welcome to Ubuntu 20.04.3 LTS (GNU/Linux 5.11.0-1028-aws x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Thu Feb 17 09:58:49 UTC 2022

  System load:  0.59              Processes:             109
  Usage of /:   18.3% of 7.69GB   Users logged in:       0
  Memory usage: 20%               IPv4 address for ens5: 172.31.88.114
  Swap usage:   0%

1 update can be applied immediately.
To see these additional updates run: apt list --upgradable


The list of available updates is more than a week old.
To check for new updates run: sudo apt update


The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.
```

That's it, congrats you've just configured your first machine through Terraform. You can now disconnect from server by running the following comment `exit`.

```
logout
Connection to 44.201.195.165 closed.
```

## Configure Ansible

Now that you have a host to play with, let's deploy some software. In this section you are going to deploy New Relic infrastructure with Ansible. Ansible is a great solution to deploy software and configuration across thousands of servers. It differs from Terraform in it's goal that it's made for servers, and Terraform is made for configuration of providers.

1) Start by opening the directory `ansible` in your terminal. You can do that by running `cd ansible`.
If you run `ls -l` you should output similar to this. Important that you see the `THIS_IS_THE_RIGHT_ANSIBLE_DIRECTORY` file:

```
total 0
-rw-r--r--  1 samuel  admin   0 Mar  4 09:13 THIS_IS_THE_RIGHT_ANSIBLE_DIRECTORY
drwxr-xr-x  3 samuel  admin  96 Feb 17 11:15 hosts
```

2) Set up hosts file

We need to configure Ansible to talk to our host. Ansible can support up to thousands of hosts. You can group them to your liking, and easily change the configuration for each of them based on the group you add them to. For now let's keep it simple and just use one group, the `all` group.

Open `hosts/production` to add the IP address of your server that you created through Terraform. It should look something similar to this:

```
# Add the IP address of your server here
# example: 192.168.1.1 ansible_user=ubuntu
44.201.195.165 ansible_user=ubuntu
```

You can test if everything was setup correctly by running the following command: `ansible --private-key=~/.ssh/skofy23.pem all -i hosts/ -m ping` This pings all the hosts to make sure we're able to access them.

```
192.168.1.10 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

You now have confirmation that Ansible can connect to the host. As you can imagine this is very important if you want to run commands.

2) Create an Ansible playbook

Ansible playbooks are the actions Ansible will execute on the hosts. Let's create a file called `newrelic-playbook.yml` and add the following content.

```
---
- name: Deploy New Relic infrastructure
  hosts: all
  become: yes
  tasks:
    - name: create a file in home directory
      copy:
        dest: "/home/ubuntu/hello"
        content: |
          Hi :D
          You've just created your first file through Ansible
          * dance party gif *
```

After you've saved the file, run the following command: `ansible-playbook --private-key=~/.ssh/skofy23.pem  -i hosts/ newrelic-playbook.yml`

Congrats you just created your first Ansible playbook, and used it to configure your host.

3) Add the New Relic infrastructure agent

Next up, you need to add the New Relic Infrastructure agent to your application in order to monitor our host CPU, Memory, Disk and other metrics.

Take a look at the `Getting started` Ansible documentation to see how you could add the New Relic infrastructure agent to Ansible and to learn more about how it works. You don't need to follow the instructions right now, but it's a good reference for the future. https://github.com/newrelic/infrastructure-agent-ansible#getting-started

Ansible, like Terraform, has a handy package manager that you can use to import the New Relic Infrastructure playbook, this saves you a lot of time installing and configuring the Infrastructure agent yourself. The first step is to download the latest version of the `newrelic.newrelic-infra` package:

`ansible-galaxy install newrelic.newrelic-infra`

The output should look something like this:

```
Starting galaxy role install process
- changing role newrelic.newrelic-infra from 0.6.1 to unspecified
- downloading role 'newrelic-infra', owned by newrelic
- downloading role from https://github.com/newrelic/infrastructure-agent-ansible/archive/0.10.4.tar.gz
- extracting newrelic.newrelic-infra to /Users/samuel/.ansible/roles/newrelic.newrelic-infra
- newrelic.newrelic-infra (0.10.4) was installed successfully
```

Now the only thing that's left is to add this role to our `newrelic-playbook.yml` playbook. Copy the code below:

```
roles:
    - role: newrelic.newrelic-infra
      vars:
        nrinfragent_config:
          license_key: your_super_secret_license_key
```

You might need to play with the indentation a bit, the `roles` section should be at the same level as `tasks`. If you get stuck, you can check out [the example file](./reference/Part_4/newrelic-playbook.yml).

One change you need to do before you apply this is to change the `license_key` from `your_super_secret_license_key` to the license key for your New Relic account. This is the New Relic license key you can find on https://one.newrelic.com/api-keys

After you've set up the license key, and saved the file, run the following command: `ansible-playbook --private-key=~/.ssh/skofy23.pem  -i hosts/ newrelic-playbook.yml`

You should see a lot of output of Ansible applying all the changes required to install New Relic infrastructure.

```
...
TASK [newrelic.newrelic-infra : install agent] ********************************************************************************
changed: [44.201.195.165]

TASK [newrelic.newrelic-infra : install integrations] *************************************************************************
ok: [44.201.195.165]

TASK [newrelic.newrelic-infra : setup agent config] ***************************************************************************
changed: [44.201.195.165]

TASK [newrelic.newrelic-infra : setup agent service] **************************************************************************
ok: [44.201.195.165]

RUNNING HANDLER [newrelic.newrelic-infra : restart newrelic-infra] ************************************************************
changed: [44.201.195.165]

PLAY RECAP ********************************************************************************************************************
44.201.195.165             : ok=9    changed=5    unreachable=0    failed=0    skipped=8    rescued=0    ignored=0
```

If it succeeds without any errors you've just installed New Relic infrastructure fully automated. Imagine if you had to write all these steps yourself, or do it all manually. Now everytime you have a new host you just need to add it to the 'hosts` files, and Ansible takes care of the rest.

# That's it

You can now proceed to [Part 4 - Enable Cloud integrations](./Part_4-Enabling_cloud_integrations.md)
