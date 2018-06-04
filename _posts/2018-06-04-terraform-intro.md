---
title: A Zero-Fricton Terraform Primer
description: What is Terraform and why should you care? How can you learn about it without having to provision real stuff in your Amazon account?
permalink: /article/a-zero-fricton-terraform-primer
---

What is Terraform and why should you care? How can you learn about it without having to provision real stuff in your Amazon account?

## Infrastructure as Code

Back in the days when we started to get away from dealing with real servers in a rack somewhere a number of cloud infrastructure providers appeared, offering access to their virtual estate via a console and - if they were any good - an API.

I've worked in lots of different places which used these cloud providers (OK, mainly Amazon Web Services) and I've seen about as many different ways to manage the infrastructure.

The worst way is of course via the console. Clicking in a GUI is not a good way to make processes repeatable or scalable. Beyond that the options include: CloudFormation, a service from AWS (only works with AWS); HEAT templates from OpenStack, which is very similar to CloudFormation (only works with OpenStack); Chef Provisioning, which is no longer supported by Chef; and of course, Terraform.

All of these tools allow you to define what infrastructure you'd like - virtual machines, load balancers, block storage, databases etc. - as some kind of machine and human readable language (CloudFormation uses JSON, for example). The tool can interpret the code and create the desired resources; the code can be checked into version control and tracked like application code.

## Terraform

[Terraform](https://www.terraform.io/) is an Infrastructure as Code tool from Hashicorp, who produce other popular pieces of software such as Vagrant. It uses a declarative language, Hashicorp Configuration Language (HCL), to define the desired state of your cloud infrastructure. From this code it generates a dependency graph of the resources and, when run against one or more providers, walks that graph and ensures that the resources exist and are configured as defined.

## Installation

The `terraform` executable is delivered as a single file so it just needs to be downloaded and put onto your system's path. On a \*nix system `/usr/local/bin/` is a good place as it's often already on your `$PATH` environment variable. From https://www.terraform.io/ find the 'Download' link and select the most appropriate version for your system. Download it, unzip it and put the `terraform` file somewhere you can run it, for example `/usr/local/bin/`.

Check that it's installed successfully and find out what version you're running - mine is:
```shell
$ terraform --version
Terraform v0.11.7
```

## Defining Some Infrastructure

Now that Terraform is installed, we need to define what infrastructure we want it to create. We use HCL to define resources for different providers. A simple one is the [random provider](https://www.terraform.io/docs/providers/random/index.html), which generates random data to use, for example, as server names. It doesn't operate against a cloud provider and requires no API keys etc. so is good to illustrate Terraform's workflow. We'll also use the [local provider](https://www.terraform.io/docs/providers/local/index.html) to write that random data out to a file.

Put the following into a file called `example.tf`:
```hcl
variable "name_length" {
  type    = "string"
  default = "2"
  description = "The number of words to put into the random name"
}

resource "random_pet" "server" {
  length = "${var.name_length}"
}

resource "local_file" "random" {                                                   
  content     = "${random_pet.server.id}"                                        
  filename = "${path.module}/random.txt"                                         
}

output "name" {
  value = "${random_pet.server.id}"
}
```

### _Aside: Code Organisation_

_Terraform will look in the directory you tell it to (the current directory by default) and find all of the `*.tf` files - sub-directories are ignored. It'll treat the files it finds as one single definition and draw a graph of all the resources. It's common to see the `variable`s and `output`s split into different files to make it clear where to find them. It's also common, and a good idea, to split code into modules but we won't worry about that today._

In the same directory run: `terraform init`. You should see output which looks a bit like this:

```shell
$ terraform init

Initializing provider plugins...
- Checking for available provider plugins on https://releases.hashicorp.com...
- Downloading plugin for provider "random" (1.3.1)...
- Downloading plugin for provider "local" (1.1.0)...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.local: version = "~> 1.1"
* provider.random: version = "~> 1.3"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Terraform has looked at all of the `*.tf` files, determined which providers are being used and has downloaded the appropriate plugins. These are stored in the `.terraform/` directory which has been created in the current path.

## Planning changes

One amazing feature of Terraform is the ability to preview changes to get an idea of what's actually going to happen when you apply them. Is this change going to modify my loadbalancer in-place or is it going to destroy it and recreate it, taking my application offline for precious minutes?

Let's see what that looks like:

```shell
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.


------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  + local_file.random
      id:        <computed>
      content:   "${random_pet.server.id}"
      filename:  "/home/vagrant/workspace/tfdemo/random.txt"

  + random_pet.server
      id:        <computed>
      length:    "2"
      separator: "-"


Plan: 2 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```

This is the first time we're running it so all the resources we've specified are being created - see the `+` next to their name in the output.

Also pay attention to the "Note" - we haven't saved this plan so whilst we've got a good idea what Terraform will do when we apply it, it's not guaranteed to try to do the same thing. We can store the plan in a file with a unique name by appending a timestamp i.e. `terraform plan -out "plan-$(date +%s)"`.

Running that we instead get this at the end of the output:
```shell
...
This plan was saved to: plan-1527707537

To perform exactly these actions, run the following command to apply:
    terraform apply "plan-1527707537"
```

If we're happy with this plan then we can apply it for real.

## Applying Changes

When we run `terraform apply` and pass it the plan file we get output which looks like the following:

```shell
$ terraform apply "plan-1527707537"
random_pet.server: Creating...
  length:    "" => "2"
  separator: "" => "-"
random_pet.server: Creation complete after 0s (ID: leading-piranha)
local_file.random: Creating...
  content:  "" => "leading-piranha"
  filename: "" => "/home/vagrant/workspace/tfdemo/random.txt"
local_file.random: Creation complete after 0s (ID: 681f312327eab60da028b397bc85af8682fdc185)

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

name = leading-piranha
```

The Random provider gave us a pet name consisting of 2 words and the `output` directive showed it at the end of the program. The `local_file` resource wrote the name into a file called `random.txt` in the current directory:

```
$ cat random.txt
leading-piranha[vagrant@localhost tfdemo]$
```

## Making More Changes

Hmmm, there's no newline at the end of the file. I'd prefer it to be formatted with one so I'll add one into the HCL. The `content` in the `local_file` can be changed to, with a `\n` appended:

```hcl
...
  content     = "${random_pet.server.id}\n"                                      
...
```

If we plan the changes we'll see that _only_ the file is scheduled to change. There's no reason for the `random_pet` resource to be changed at all so Terraform uses it as it is.

```shell
$ terraform plan -out "plan-$(date +%s)"

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

random_pet.server: Refreshing state... (ID: leading-piranha)
local_file.random: Refreshing state... (ID: 681f312327eab60da028b397bc85af8682fdc185)

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

-/+ local_file.random (new resource required)
      id:       "681f312327eab60da028b397bc85af8682fdc185" => <computed> (forces new resource)
      content:  "leading-piranha" => "leading-piranha\n" (forces new resource)
      filename: "/home/vagrant/workspace/tfdemo/random.txt" => "/home/vagrant/workspace/tfdemo/random.txt"


Plan: 1 to add, 0 to change, 1 to destroy.

------------------------------------------------------------------------

This plan was saved to: plan-1528126805

To perform exactly these actions, run the following command to apply:
    terraform apply "plan-1528126805"
```

Applying the changes from the plan we've just made can `cat`ing the file again shows that there's now a newline at the end:
```shell
$ terraform apply "plan-1528126805"
local_file.random: Destroying... (ID: 681f312327eab60da028b397bc85af8682fdc185)
local_file.random: Destruction complete after 0s
local_file.random: Creating...
  content:  "" => "leading-piranha\n"
  filename: "" => "/home/vagrant/workspace/tfdemo/random.txt"
local_file.random: Creation complete after 0s (ID: 82c2862c8ae7053eb94b7aa498265335c5d22b22)

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

Outputs:

name = leading-piranha

$ cat random.txt
leading-piranha
```

## Variables

In the `example.tf` file you can see that we declared a `variable` called `name_length` and referenced it in the `random_pet` resource (`length = "${var.name_length}"`); why not just hard code that number?

To aid code reuse, Terraform lets us pass in different values for the variables we've defined. We use the `-var` flag and the name of the variable, like this:

```shell
$ $ terraform plan -var name_length=3
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

random_pet.server: Refreshing state... (ID: leading-piranha)
local_file.random: Refreshing state... (ID: 82c2862c8ae7053eb94b7aa498265335c5d22b22)

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

-/+ local_file.random (new resource required)
      id:        "82c2862c8ae7053eb94b7aa498265335c5d22b22" => <computed> (forces new resource)
      content:   "leading-piranha\n" => "${random_pet.server.id}\n" (forces new resource)
      filename:  "/home/vagrant/workspace/tfdemo/random.txt" => "/home/vagrant/workspace/tfdemo/random.txt"

-/+ random_pet.server (new resource required)
      id:        "leading-piranha" => <computed> (forces new resource)
      length:    "2" => "3" (forces new resource)
      separator: "-" => "-"


Plan: 2 to add, 0 to change, 2 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```

The plan tells us again what's going to happen - both resources will be destroyed and others created in their place. The file has to be recreated in this case because it's dependent on the value from `random_pet`. Terraform works this out from the dependency graph it generates - it can work out what it needs to recreate based on what's changed and what depends on that.

### _Aside: Dependency Graph_

_The dependency graph for your infrastructure can be seen in the_ [DOT language](https://en.wikipedia.org/wiki/DOT_(graph_description_language) _by running `terraform graph`. If you've got_ [Graphviz](http://www.graphviz.org/) _installed then you can render it by piping the output straight to the `dot` program:_

```shell
$ terraform graph | dot -Tpng -o tfdemo.png
```

This is a really simple example and no critical infrastructure is at stake so we can apply these changes without saving to a plan file by simply running `terraform apply` and either typing "yes" at the prompt or passing the `-auto-approve` flag:

```shell
$ terraform apply -var name_length=3 -auto-approve
random_pet.server: Refreshing state... (ID: leading-piranha)
local_file.random: Refreshing state... (ID: 82c2862c8ae7053eb94b7aa498265335c5d22b22)
local_file.random: Destroying... (ID: 82c2862c8ae7053eb94b7aa498265335c5d22b22)
local_file.random: Destruction complete after 0s
random_pet.server: Destroying... (ID: leading-piranha)
random_pet.server: Destruction complete after 0s
random_pet.server: Creating...
  length:    "" => "3"
  separator: "" => "-"
random_pet.server: Creation complete after 0s (ID: scarcely-intense-mammoth)
local_file.random: Creating...
  content:  "" => "scarcely-intense-mammoth\n"
  filename: "" => "/home/vagrant/workspace/tfdemo/random.txt"
local_file.random: Creation complete after 0s (ID: a3f2f24388d1e4ddd72872a833469002f2ad5b75)

Apply complete! Resources: 2 added, 0 changed, 2 destroyed.

Outputs:

name = scarcely-intense-mammoth
```

Note that we need to pass the same parameters to the apply phase that we passed in planning. This is one very good reason to save the plan and use that when running `apply`.

## State

Along with the `.terraform/` directory which stores the provider plugins you'll notice that there's a `terraform.tfstate` file there too. A quick examination shows that it's text, which we can read!

```shell
$ file terraform.tfstate
terraform.tfstate: ASCII text
```

This is the state of our resources, in JSON format. The state represents Terraform's view of the defined resources. If you run the `plan` command with the same arguments in the same directory then Terraform will tell us that there's nothing to do:

```shell
$ terraform plan -var name_length=3

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

random_pet.server: Refreshing state... (ID: scarcely-intense-mammoth)
local_file.random: Refreshing state... (ID: a3f2f24388d1e4ddd72872a833469002f2ad5b75)

------------------------------------------------------------------------

No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your
configuration and real physical resources that exist. As a result, no
actions need to be performed.
```

If you're running Terraform to create your cloud infrastructure then make sure the state is committed to source control or - particularly if you're working with other engineers - persisted in one of the [supported backends](https://www.terraform.io/docs/backends/index.html).

## Wrapping Up

This illustrates a typical workflow for Terraform: code -> plan -> apply -> commit. To make it as easy as possible to follow along we've used providers which only operate locally, but if you added an `aws_instance` resource then the random server name we've generated could easily be used to set the `Name` tag on the EC2 instance. Terraform will pick up the standard `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables and your workflow remains unchanged as you provision real infrastructure.

