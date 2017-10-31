provider "aws" {
  region     = "eu-central-1"
}

resource "aws_security_group" "oc_kafka" {
  name        = "${var.name}-kafka-sg"
  description = "${var.name}-Kafka Security Group"
}

resource "aws_security_group_rule" "allow-kafka" {
  type              = "ingress"
  from_port         = 9092
  to_port           = 9095
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.oc_kafka.id}"
}

resource "aws_security_group_rule" "allow-zookeeper" {
  type              = "ingress"
  from_port         = 2888
  to_port           = 2888
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.oc_kafka.id}"
}

resource "aws_security_group_rule" "allow-zookeeper_leader" {
  type              = "ingress"
  from_port         = 3888
  to_port           = 3888
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.oc_kafka.id}"
}

resource "aws_security_group_rule" "allow-ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.oc_kafka.id}"
}

resource "aws_security_group_rule" "allow-ssh" {
  type              = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]  security_group_id = "${aws_security_group.oc_kafka.id}"
}

data "aws_ami" "node-ami" {
  most_recent = true
  filter {
    name = "image-id"
    values = ["ami-d74be5b8"]
  }

}

resource "aws_key_pair" "kafka_key" {
  key_name   = ""
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_instance" "brokers" {
  ami = "${data.aws_ami.node-ami.id}"
  count = "${var.worker-count}"
  instance_type = "${var.worker-instance-type}"
  key_name = "${aws_key_pair.kafka_key.key_name}"
  vpc_security_group_ids = [
    "${aws_security_group.oc_kafka.id}"]

  root_block_device {
    delete_on_termination = true
  }

  tags {
    Name = "${var.name}-worker-${count.index + 1}"
  }
}

resource "null_resource" "ansible-provision" {

  depends_on = ["aws_instance.brokers"]

  provisioner "local-exec" {
    command =  "echo \"\n[kafka]\" > ansible-inventory"
  }

  provisioner "local-exec" {
    command =  "echo \"${join("\n",formatlist("%s ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/id_rsa", aws_instance.brokers.*.public_ip))}\" >> ansible-inventory"
  }
}
