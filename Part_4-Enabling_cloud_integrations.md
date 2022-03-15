# Enable cloud integrations to monitor the AWS environment through Terraform with New Relic

The New Relic Cloud integrations are a great way for you to get some great insights into their AWS environment, and link that data to APM, Browser, or even Infrastructure data. The only downside is that it's quite a hassle to set it all up, especially if you have to setup multiple New Relic and/or AWS accounts. Luckily the Observability as Code team has recently released the final bits to make this entire configuration fully automated.

During this part of the workshop we will go through each step on how to set up the Cloud integrations end to end. Now because this requires pretty extensive permissions on the AWS side we will review the code, and if you wish you can test with your own AWS account. The code below is everything a customer would need to get started.


