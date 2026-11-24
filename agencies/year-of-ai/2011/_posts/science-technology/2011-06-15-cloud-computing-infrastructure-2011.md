---
title: "Cloud Computing and Infrastructure in 2011"
date: 2011-06-15
categories: [Science & Technology]
tags: [cloud-computing, infrastructure, aws, azure]
excerpt: "Explosive growth of Amazon Web Services and Microsoft Azure transformed computing from on-premise to cloud-based infrastructure."
preview: /images/previews/cloud-computing-and-infrastructure-in-2011.svg
permalink: /news/science-technology/cloud-computing-infrastructure-2011/
---

**Category:** Science & Technology

**Key figures:** Andy Jassy (Senior VP, Amazon Web Services), Werner Vogels (CTO, Amazon), Scott Guthrie (VP, Microsoft Azure), Eric Schmidt (CEO, Google), Drew Houston (CEO, Dropbox), Jim Curry (GM, Rackspace)

## Summary

2011 marked a pivotal inflection point for cloud computing adoption, as Amazon Web Services (AWS) solidified its market leadership with a wave of new services while Microsoft entered the competitive fray with an expanding Windows Azure platform. AWS launched dozens of new features and services throughout the year—including Elastic Beanstalk (January 2011), CloudFormation (February 2011), and the general availability of the Route 53 DNS service (May 2011)—cementing its position as the default infrastructure layer for startups and enterprises alike. Meanwhile, Google announced Google Cloud Storage in May 2011, and an April outage on AWS's US-EAST-1 region (April 21–25) that took down Reddit, Foursquare, and Quora simultaneously illustrated both the centrality and the fragility of concentrated cloud infrastructure.

By 2011, the major cloud platforms had collectively made elastic computing economically accessible: startups could rent server capacity by the hour rather than purchase and co-locate physical hardware, eliminating months of capital expenditure and provisioning delays. This structural shift would prove foundational to the AI revolution of the following decade.

## Amazon Web Services: The Dominant Platform

AWS, launched in 2006 with S3 object storage and EC2 compute instances, celebrated its fifth year in 2011 as the undisputed cloud leader. Analysts estimated AWS revenues at $750 million to $1 billion for 2011—a figure Amazon did not officially disclose but which grew to $3.1 billion by 2013. The platform's scale advantages were enormous: AWS operated data centers across the US-EAST, US-WEST, EU-WEST, AP-SOUTHEAST, and AP-NORTHEAST regions, with announced plans for additional availability zones.

Key service launches in 2011:

| Service | Launch Date | Significance |
|---------|------------|--------------|
| AWS Elastic Beanstalk | January 2011 | Platform-as-a-Service; deploy web apps without managing servers |
| Amazon SES | January 2011 | Scalable bulk and transactional email-sending service |
| AWS CloudFormation | February 2011 | Infrastructure-as-code; provision entire architectures from templates |
| Amazon Route 53 | May 2011 (GA) | DNS service reached general availability with ELB alias records and weighted routing |
| AWS Direct Connect | August 2011 | Dedicated private network links between customer data centers and AWS |
| Amazon ElastiCache | August 2011 | Managed in-memory caching (Memcached) for application performance |

Elastic Beanstalk, in particular, was significant: it abstracted away the complexity of server configuration, load-balancing, and auto-scaling, allowing developers to deploy web applications by simply uploading code. This accelerated the adoption of cloud infrastructure among development teams without dedicated DevOps expertise.

## The April 2011 AWS Outage

On April 21, 2011, a network configuration error in AWS's US-EAST-1 region (Virginia) triggered a cascading failure affecting Elastic Block Store (EBS) volumes. The outage lasted approximately four days—with partial services restored April 22 but full recovery not complete until April 25—and affected hundreds of companies that relied on the region as their primary or sole infrastructure provider.

The most visible casualties included Reddit, Foursquare, Quora, HootSuite, and portions of Netflix. The event attracted widespread press coverage and prompted the first serious industry-wide discussions about cloud vendor lock-in, geographic redundancy, and disaster-recovery architecture. AWS published a detailed post-mortem describing the failure mechanism—a cascading EBS re-mirroring storm triggered by a configuration change—and subsequently improved isolation between availability zones.

The outage paradoxically accelerated cloud adoption in one counterintuitive way: it demonstrated that cloud failures were recoverable and publicly documented, whereas on-premise failures were often silently worse and entirely undocumented.

## Microsoft Azure

Microsoft had launched Windows Azure as a public beta in November 2009 and made it generally available on February 1, 2010. Throughout 2011, Microsoft significantly expanded Azure's capabilities and geographic footprint, positioning it as an enterprise-friendly alternative to AWS. Unlike AWS's Linux-first heritage, Azure was built to run Windows Server workloads, Active Directory environments, and Microsoft SQL Server databases—enabling existing enterprise customers to extend their on-premise Microsoft investments into the cloud.

Microsoft's enterprise sales relationships gave Azure a distinct distribution advantage over AWS in large organizations: CIOs who had maintained Microsoft Enterprise Agreements could negotiate Azure capacity through existing procurement channels rather than adopting a new vendor. By late 2011, Azure supported virtual machines (IaaS), Azure SQL Database, Azure Storage, and the beginnings of the platform services that would mature into Azure App Service and Azure Functions in later years.

## Google and the PaaS Competition

Google had been operating App Engine—its platform-as-a-service offering—since 2008, but made a significant push into infrastructure in 2011 with the announcement of **Google Cloud Storage** (May 2011) and the private beta of **Google Compute Engine** (announced at Google I/O 2012, but infrastructure laid in 2011). Google's cloud strategy in 2011 remained notably fragmented compared to AWS's integrated service portfolio, a gap that would take Google years to close.

Meanwhile, Salesforce.com's Force.com platform and Heroku (acquired by Salesforce for $212 million in December 2010) were expanding the PaaS market for web-application development. Heroku's acquisition was particularly notable: it gave Salesforce a developer-friendly Ruby-on-Rails deployment platform that attracted the startup community and illustrated how PaaS would complement IaaS in the cloud ecosystem.

## Consumer Cloud Services

Beyond enterprise infrastructure, 2011 witnessed explosive growth in consumer cloud services that shared the same underlying infrastructure layer:

- **Dropbox** reached 25 million users by January 2011 and approximately 50 million by October 2011, making it the fastest-growing cloud-storage service by absolute user count.
- **iCloud**, Apple's consumer cloud service, launched October 12, 2011 alongside the [iPhone 4S and Siri]({{ '/news/science-technology/iphone-4s-siri/' | relative_url }}), replacing the older MobileMe service and providing seamless file, photo, and app-data synchronization across Apple devices.
- **Netflix** completed its transition from a DVD-by-mail service to a streaming-first business during 2011, processing tens of billions of API calls per month through AWS infrastructure—making it one of the largest individual cloud customers in the world.

## OpenStack and the Open-Source Response

**OpenStack**—the open-source cloud-infrastructure platform first launched by Rackspace and NASA in 2010—expanded rapidly through 2011, allowing organizations to build private or public cloud infrastructure using commodity hardware. In October 2011, Rackspace announced plans to spin OpenStack out into an independent OpenStack Foundation (formally launched in September 2012), drawing dozens of corporate backers including AMD, Citrix, Dell, HP, IBM, and Intel.

OpenStack represented the industry's response to concerns about vendor lock-in with AWS and Azure. While AWS's proprietary APIs and services had created significant switching costs, OpenStack offered a theoretically portable infrastructure layer. In practice, the complexity of operating OpenStack proved challenging for most organizations, but it seeded the open-source cloud ecosystem that would eventually produce Kubernetes, Terraform, and other infrastructure tools.

## Significance

The rapid maturation of cloud infrastructure in 2011 established the technical and economic foundations essential for later artificial intelligence and machine learning systems. IBM's [Watson defeating Jeopardy! champions]({{ '/news/science-technology/watson-jeopardy-2011/' | relative_url }}) in February 2011 demonstrated what was computationally possible when massive compute resources were applied to machine-learning problems—but Watson ran on purpose-built hardware. Cloud infrastructure democratized access to equivalent compute for thousands of smaller organizations.

Massive-scale ML training on datasets numbering in terabytes became feasible only through elastic cloud resources. The pay-as-you-go pricing model eliminated capital expenditure barriers for startups experimenting with deep learning. By 2011, the infrastructure layer supporting AI's subsequent explosive growth was largely in place: distributed computing frameworks, data warehouses, and managed services that made training large neural networks economically viable.

The competition between AWS and Azure established the duopoly that continues shaping the AI infrastructure landscape today. [Mark Zuckerberg's Facebook]({{ '/news/people/mark-zuckerberg-2011/' | relative_url }}), [Instagram's rapid growth]({{ '/news/science-technology/instagram-founding/' | relative_url }}), and the rise of [Android]({{ '/news/science-technology/android-mobile-rise/' | relative_url }}) as a mobile platform all ran on cloud infrastructure that 2011's expansions made possible. The Groupon and LinkedIn IPOs of 2011 were also businesses whose entire technical stacks ran in the cloud—a first for companies going public at that scale.

## Sources

- Amazon Web Services (2011). AWS service launch announcements and post-mortem. https://aws.amazon.com/about-aws/whats-new/2011/
- Amazon (April 29, 2011). "Summary of the Amazon EC2 and Amazon RDS Service Disruption." https://aws.amazon.com/message/65648/
- Microsoft Azure (2011). "Windows Azure Expands." https://azure.microsoft.com/en-us/blog/
- OpenStack Foundation announcement (September 2011). https://www.openstack.org/
- IDC Cloud Computing Market Analysis (2011). Cited in industry press.

<!-- BEGIN GENERATED: Related -->
## Related

- [IBM Watson Wins Jeopardy!](/news/science-technology/watson-jeopardy-2011/) — a 2011 milestone in the compute-intensive AI that cloud resources would democratize
- [Android Mobile Platform Rise](/news/science-technology/android-mobile-rise/) — the mobile platform whose services ran on cloud infrastructure
- [Instagram Founding & iOS Launch](/news/science-technology/instagram-founding/) — a fast-scaling 2011 app built entirely on cloud infrastructure
- [Mark Zuckerberg in 2011](/news/people/mark-zuckerberg-2011/) — Facebook's cloud-scale growth in the same year
<!-- END GENERATED: Related -->
