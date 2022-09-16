---
title: "Surviving Continuous Deployment in Distributed Systems"
date: 2022-09-16T07:01:49+02:00
draft: false
---

DevOps culture has been around for quite some time. Some good books exist on the topic, starting with the canonical "Continuous Delivery", novels like "The Phoenix Project" and "Project Unicorn" or great text books such as "The DevOps Handbook".

When attempting to establish DevOps culture with continuous delivery as part of it, there are many challenges we need to overcome. Everybody uses pipelines and automated builds nowadays. But becoming a mature dev team that brings down cycle times to mere minutes requires more than that.

ThoughtWorks just recently released this great article explaining some of the concepts that we need as dev practices in order to make master-based development work with continuous deployment, esp. in distributed systems:

* https://www.thoughtworks.com/insights/blog/continuous-delivery/surviving-continuous-deployment-distributed-systems

The article highlights some hands-on practices, such as feature toggles, baby commits, expand/contract when refactoring critical parts of a system - and, of course, developer discipline to make it work. A great read!

