---
title: Everything You Need To Know About Networking On AWS
published: true
description: An overview of virtual private networking on Amazon Web Services - with ASCII diagrams!
cover_image: https://thepracticaldev.s3.amazonaws.com/i/g8grvc4s3jo1hm7mltah.png
tags: AWS, Networking
permalink: /article/everything-you-need-to-know-about-networking-on-aws
---

Disclaimer: I'm not a network engineer and never have been - a tame network engineer has been consulted to ensure factual and terminological accuracy. The following is an in-exhaustive run down of everything I've learnt from building and using network infrastructure on Amazon Web Services. If you find you have no reference point for this information then have a poke around the "VPC" section of the AWS control panel (or get in touch to tell me I'm talking nonsense).

## Parts of a Network You Should Know About

If you're running infrastructure and applications on AWS then you will encounter all of these things. They're not the only parts of a network setup but they are, in my experience, the most important ones.

### VPC

A virtual private cloud - VPC - is a private network space in which you can run your infrastructure. It has an address space (CIDR range) which you choose e.g. `10.0.0.0/16`. This determines how many IP addresses you can assign within the VPC. Each server you create inside the VPC will need an IP address so this address space defines the limit of how many resources you can have within the network. The `10.0.0.0/16` address space can use the addresses from `10.0.0.0` to `10.0.255.255`, which is 65,536 IP addresses.

The VPC is the basis of your network on AWS and all new accounts include a default VPC with a subnets in each availability zone.

```
+---------------+
|     VPC       |     The Internet
|               |
|               |
|  10.0.0.0/16  |
|               |
|               |
+---------------+
```

### Subnets

A subnet is a section of your VPC, with its own CIDR range and rules on how traffic can flow. Its CIDR range has to be a subset of the VPC's, for example `10.0.1.0/24` which would allow for IPs from `10.0.1.0` to `10.0.1.255` giving 256 possible IP addresses.

Subnets are often denominated as 'public' or 'private' depending on whether traffic can reach them from outside the VPC (the Internet). This visibility is controlled by the traffic routing rules and each subnet can have its own rules.

A subnet has to be in a specific availability zone within a region so it's good practice to have a subnet in each zone. If you plan to have public and private subnets then there should be one of each per availability zone.

```
+---------------------------+
|            VPC            |
|                           |
+------------+ +------------+
||  Subnet 1 | |  Subnet 2 ||
||10.0.1.0/24| |10.0.2.0/24||
||           | |           ||
|------------+ +------------|
+---------------------------+
```
#### Availability Zones

We've said that there should be subnets per availability zone, but what does that actually mean?

Each AWS region is divided into 2 or more different zones which, between them, aim to guarantee a very high level of availability for that region. Essentially, at least one zone should be able to operate, even if others suffer outages (:fire:).

```
+----------+          +----------+
|us-ea)t-1a|          |us-east-1b|
|_____(____|          |__________|
|     )    |          |          |
|   ( &()  |          |    ✔     |
|  ) () &( |          |    8-)   |
+----------+          +----------+
```

### Routing Tables

A routing table contains rules about how IP packets in the subnets can travel to different IP addresses. There is always a default route table which will only allow traffic to travel locally, within the VPC. If a subnet has no routing table associated with it then it uses the default one. These would be 'private' subnets.

If you want external traffic to be able to get to a subnet then you need to create a routing table with a rule explicitly allowing this. Subnets associated to that routing table would be 'public'.

All of the subnets in the default VPCs are associated with a route table which makes them public.

### Internet Gateways

The routing table which makes a subnet public needs to reference an Internet gateway to allow the flow of external IP packets into and out of the VPC. You create your Internet gateway and then create a rule which says that packets to `0.0.0.0/0` - all IP addresses - need to go to there.

```
          Route table
         +-------------------+
         | 10.0.0.0/8: local | Requests within the VPC go over local connections.
      +--+ 0.0.0.0/0: ig-123 | Requests to any other IPs go via the Internet Gateway.
      |  |                   |
      |  +-------------------+
      |
      |
+-----+-------+          +-------------+
|  Subnet 1   |          |  Subnet 2   |
| 10.0.1.0/24 |          | 10.0.2.0/24 |
|             |          |             |
|             | 10.0.2.9 |             |
|             +--------->|             |
|             |          |             |
+-------+-----+          +-------------+
        | 8.8.4.4
        |
        |   +--------+
        +-->| ig-123 |
            |        +-----> The Internet
            +--------+
```

### NAT Gateways

If you have an EC2 instance in a private subnet - one which doesn't allow traffic from the Internet to reach it - then there's also no way for IP packets to reach the Internet. We need a mechanism for sending those packets out, and then routing the replies correctly. This is called network address translation and is very likely done in your house by your wifi router.

A NAT gateway is a device which sits in the public subnets, accepts any IP packets bound for the Internet coming from the private subnets, sends those packets on to their destination and then sends the returning packets back to the source.

It's not necessary to have NAT gateways if you don't intend instances in your private subnets to talk outside if your VPC but if you do need to do that e.g. using an external API, SaaS database etc. then you can simply set up an EC2 instance (might be cheaper, depending on your traffic), configured appropriately, or use an AWS managed NAT gateway resource (will be easier to manage because you won't be doing it).

```
  +---------------------+
  |   Public Subnet     |
  |   10.0.1.0/24       |
  |                     |
  |    +------------+   |
  |    |            +----------->   The Internet
  |    |  nat-123   |   |
  |    |            |   |
  |    +-------^----+   |
  |            |        |
  +------------|--------+
               |
               | 8.8.4.4
               |                       Route table
  +------------+---------+    +---------------------+
  |  Private Subnet      +----+  10.0.0.0/16: local |
  |  10.0.20.0/24        |    |  0.0.0.0/0: nat-123 |
  |                      |    +---------------------+
  +----------------------+
```
 - The public subnet contains the NAT gateway
 - A request is made from the private subnet to an IP address somewhere on the Internet
 - The route table says that it needs to go to the NAT gateway
 - The NAT gateway sends it on

### Security Groups

VPC network Security groups denote what traffic can flow to (and from) EC2 instances within your VPC. A security groups can specify ingress (inbound) and egress (outbound) traffic rules, limiting them to certain sources (inbound) and destinations (outbound). They are associated with EC2 instances rather than subnets.

By default all traffic is allowed out, but no traffic is allowed in. Inbound rules can specify a source address - either a CIDR block or another security group - and a port range. When the source is another security group then that must be within the same VPC. For example, a VPC is created with a default security group which allows traffic from anything which has that same security group. Assigning the group to everything created in the VPC (not necessarily the most secure practice) means that all those resources can talk to each another.

```
                   +---------------+
                   | sg-abcde      |
                   | ALLOW TCP 443 |
                   +----+----------+
                         |
                    +----+------+
                    |  i-67890  |
 10.0.1.123:22      |           | 10.0.1.123:443
------------------>X|           <----------------
                    |           |
                    +-----------+
```
 - An instance (i-67890) has a security group (sg-abcde) which allows TCP traffic on port 443
 - A request is made to its IP address (10.0.1.123) on port 22 which doesn't get through
 - A request is made to port 443 on the instance and the traffic is allowed

## Putting it All Together

The complete picture of your virtual private network looks something like the picture below, with public and private subnets spread across availability zones, network address translation sitting in the public subnets and route tables to specify how packets are routed. EC2 instances are run in any subnet and have security groups attached to them.

```
                                        +-------+                                  
                                        | ig-1  |                                  
                                        |       |                                  
        vpc-123: 10.0.0.0/16  |         |       |        |                         
       +----------------------+---------+-------+--------+---------------------+
       |                      |                          |                     |   
       |  +-----+             |  +-----+                 |  +-----+            |   
       |  | NAT |             |  | NAT |                 |  | NAT |            |   
public |  |     |             |  |     |                 |  |     |            |   
subnets|  +-----+             |  +-----+                 |  +-----+            |   
       |                      |                          |                     |   
       |                      |                          |                     |   
       |                      |                          |                     |   
       |              +-------+                  +-------+             +-------+
       |              | rt-1a |                  | rt-1b |             | rt-1c |
       | 10.0.1.0/24  |       | 10.0.2.0/24      |       | 10.0.3.0/24 |       |   
-------+-----------------------------------------------------------------------+
       | 10.0.4.0/24  | rt-2a | 10.0.5.0/24      | rt-2b | 10.0.6.0/24 | rt-2c |
       |              |       |                  |       |             |       |   
       |              +-------+                  +-------+             +-------+
private|                      |                          |                     |   
subnets|                      |                          |                     |   
       |                      |                          |                     |   
       |                      |                          |                     |   
       |                      |                          |                     |   
       |                      |                          |                     |   
       |                      |                          |                     |   
       |                      |                          |                     |   
       +----------------------+--------------------------+---------------------+
       |         AZ 1         |          AZ 2            |        AZ 3         |
```


