provider "aws" {
  region = "us-west-2"
}

#data "aws_subnet_ids" "private" {
#  vpc_id = "${aws_default_vpc.default.id}"
#}

# load availability zones
data "aws_availability_zones" "available" {}

#resource "aws_default_vpc" "default" {
#  tags {
#      Name = "Default VPC"
#  }
#}

resource "aws_instance" "tf-cassandra-cluster-seed-1" {
  count = "1"
  ami = "${var.os == "linux" ? var.cluster_ami["linux"] : var.cluster_ami["ubuntu"]}"
  instance_type = "t2.small"

  availability_zone = "${element(data.aws_availability_zones.available.names, 0)}"
  #subnet_id  = "${element(data.aws_subnet_ids.private.ids, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.terraform-cassandra-sg.id}"]

  key_name = "${var.key_name}"

  user_data = "${file("./aws_${var.os}_setup_script_cassandra.sh")}"

  connection {
    user = "${var.os == "linux" ? "ec2-user" : "ubuntu"}"
    private_key = "${file("${var.key_location}")}"
    timeout = "5m"
  }

  provisioner "remote-exec" {
    inline = [<<-EOF
echo "testing"
sudo sleep 90
echo 'testing connection - ${self.private_ip}' | sudo tee testing.txt
sudo sed -i "s/- seeds: \"127.0.0.1\"/- seeds: \"${self.private_ip}\"/g" /etc/cassandra/cassandra.yaml
echo 'SED complete'
sudo reboot
                EOF
]
  }

  tags {
    Name =            "tf-cassandra-cluster-seed-1"
    Description =     "testing deploying cassandra cluster with terraform and AWS linux"
    Owner =           "BattsNick"
    Version =         "0.9"
  }
}

resource "aws_instance" "tf-cassandra-cluster-seed-2" {
  count = "1"
  ami = "${var.os == "linux" ? var.cluster_ami["linux"] : var.cluster_ami["ubuntu"]}"
  instance_type = "t2.small"

  availability_zone = "${element(data.aws_availability_zones.available.names, 1)}"
  #subnet_id  = "${element(data.aws_subnet_ids.private.ids, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.terraform-cassandra-sg.id}"]

  key_name = "${var.key_name}"

  user_data = "${file("./aws_${var.os}_setup_script_cassandra.sh")}"

  connection {
    user = "${var.os == "linux" ? "ec2-user" : "ubuntu"}"
    private_key = "${file("${var.key_location}")}"
    timeout = "5m"
  }

  provisioner "remote-exec" {
    inline = [<<-EOF
sudo sleep 90
echo 'testing connection - ${self.private_ip},${aws_instance.tf-cassandra-cluster-seed-1.private_ip}' | sudo tee testing.txt
sudo sed -i 's/- seeds: "127.0.0.1"/- seeds: "${self.private_ip},${aws_instance.tf-cassandra-cluster-seed-1.private_ip}"/g' /etc/cassandra/cassandra.yaml
echo 'SED complete'
sudo reboot
                EOF
]
  }

  tags {
    Name =            "tf-cassandra-cluster-seed-2"
    Description =     "testing deploying cassandra cluster with terraform and AWS linux"
    Owner =           "BattsNick"
    Version =         "0.9"
  }
  depends_on = ["aws_instance.tf-cassandra-cluster-seed-1"]
}

resource "aws_instance" "tf-cassandra-cluster-node-1" {
  count = "1"
  ami = "${var.os == "linux" ? var.cluster_ami["linux"] : var.cluster_ami["ubuntu"]}"
  instance_type = "t2.small"

  availability_zone = "${element(data.aws_availability_zones.available.names, 2)}"
  #subnet_id  = "${element(data.aws_subnet_ids.private.ids, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.terraform-cassandra-sg.id}"]

  key_name = "${var.key_name}"

  user_data = "${file("./aws_${var.os}_setup_script_cassandra.sh")}"

  connection {
    user = "${var.os == "linux" ? "ec2-user" : "ubuntu"}"
    private_key = "${file("${var.key_location}")}"
    timeout = "5m"
  }

  provisioner "remote-exec" {
    inline = [<<-EOF
sudo sleep 90
echo 'testing connection - ${self.private_ip},${aws_instance.tf-cassandra-cluster-seed-1.private_ip}' | sudo tee testing.txt
sudo sed -i 's/- seeds: "127.0.0.1"/- seeds: "${aws_instance.tf-cassandra-cluster-seed-1.private_ip},${aws_instance.tf-cassandra-cluster-seed-2.private_ip}"/g' /etc/cassandra/cassandra.yaml
echo 'SED complete'
sudo reboot
                EOF
]
  }

  tags {
    Name =            "tf-cassandra-cluster-node-1"
    Description =     "testing deploying cassandra cluster with terraform and AWS linux"
    Owner =           "BattsNick"
    Version =         "0.9"
  }
  depends_on = ["aws_instance.tf-cassandra-cluster-seed-2"]
}

resource "aws_security_group" "terraform-cassandra-sg" {
  name = "terraform-cassandra-sg"
  description = "Managed by Terraform - Allows internal connections to necessary Cassandra ports from security group"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    self = true
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["216.85.150.198/32","76.25.233.7/32"]
    self = true
  }

  ingress {
    from_port = 7000
    to_port = 7000
    protocol = "tcp"
    self = true
  }

  ingress {
    from_port = 7001
    to_port = 7001
    protocol = "tcp"
    self = true
  }

  ingress {
    from_port = 7199
    to_port = 7199
    protocol = "tcp"
    self = true
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    self = true
  }

  ingress {
    from_port = 9042
    to_port = 9042
    protocol = "tcp"
    self = true
  }

  ingress {
    from_port = 9160
    to_port = 9160
    protocol = "tcp"
    self = true
  }
}


output "public_dns_1" {
  value = "${aws_instance.tf-cassandra-cluster-seed-1.public_dns}"
}

output "public_dns_2" {
  value = "${aws_instance.tf-cassandra-cluster-seed-2.public_dns}"
}

output "public_dns_3" {
  value = "${aws_instance.tf-cassandra-cluster-node-1.public_dns}"
}

output "OS" {
  value = "${var.os}"
}