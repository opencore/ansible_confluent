# ansible_confluent

Ansible Playbooks to install a Kafka cluster with SSL security based on the Confluent OSS platform

# Get started

Create a few ec2 machines, copy the inventories/ec2.inv.template file and set your external ip addresses in there.

Edit vars/global_settings.yml to your liking.

Run the playbooks with

`ansible-playbook playbook.yml -i inventories/ec2.inv -s -u username --private-key key.pem`


After installation your client certificates will have been copied to the clientcerts directory.