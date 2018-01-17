# terraform-aws-linux-cassandra-cluster

Terraform template to launch a 3 node Cassandra cluster on AWS EC2 t2.small instances.

## Dependencies

* Terraform 0.11.2+ - For installation instructions go [here](https://www.terraform.io/intro/getting-started/install.html). Or you can use a Docker image like this [one](https://hub.docker.com/r/hashicorp/terraform/).
* AWS account  - Free; if you don't have an account you can sign up at https://aws.amazon.com/. In this example we use T2.small instances.

## QuickStart

* Clone the repo: `git clone git@github.com:nickbatts/terraform-aws-linux-cassandra-cluster
 && cd terraform-aws-linux-cassandra-cluster
`
* change key_name variable to name of your own key
* `terraform plan` - check to make sure there are no mistakes
* `terraform apply` - review and confirm resources to be created
* `terraform destroy` - terminate instances and clean-up resources

## Helpful Commands

### Cassandra administration
* `/var/log/cassandra/cassandra.log` - database logs for troubleshooting

* `/etc/cassandra/conf/cassandra.yaml` - cassandra configuration file as edited by `./aws_linux_setup_script_cassandra.sh`

* `sudo service cassandra status` - confirm cassandra is running

* `nodetool status` - check cluster status and other nodes

## Authors

* Nick Batts

## License

This project is licensed under the terms of the MIT license.
