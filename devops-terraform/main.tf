provider "aws" {
  region = "eu-west-2"
}

# Create a VPC
resource "aws_vpc" "public-private" {
  tags {
      Name = "Naz - VPC"
  }
  cidr_block = "11.2.0.0/16"
}

data "aws_ami" "web" {
  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "name"
    values = ["naz-web-prod*"]
  }

  most_recent = true
}

resource "aws_subnet" "web" {
  vpc_id = "${aws_vpc.public-private.id}"
  cidr_block = "11.2.1.0/24"
  map_public_ip_on_launch = true
  tags {
      Name = "Web - Public"
  }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "Allow all traffic through port 80"
  vpc_id      = "${aws_vpc.public-private.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
      Name = "web"
  }
}

resource "aws_instance" "naz-instance" {
  ami = "${aws_ami.web.id}"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  subnet_id = "${aws_subnet.web.id}"
  user_data = "${data.template_file.init_script.rendered}"
  depends_on = ["aws_instance.naz-db-instance"]

  tags {
    Name = "web-naz"
  }
}

data "template_file" "init_script" {
  template = "${file("${path.module}/init.sh")}"
}

resource "aws_security_group" "naz-db" {
  name = "naz-db"
  vpc_id = "${aws_vpc.public-private.id}"

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    security_groups = ["${aws_security_group.web.id}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "naz-db-subnet" {
  vpc_id = "${aws_vpc.public-private.id}"
  cidr_block = "11.2.2.0/24"
  map_public_ip_on_launch = false
  tags {
      Name = "DB - Private"
  }

}

resource "aws_instance" "naz-db-instance" {
  ami = "ami-4fc3d02b"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.naz-db.id}"]
  subnet_id = "${aws_subnet.naz-db-subnet.id}"
  private_ip = "11.2.2.51"

  tags {
      Name = "db-naz"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.public-private.id}"
}

# Add route to internet gateway in route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.public-private.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_route_table" "local" {
  vpc_id = "${aws_vpc.public-private.id}"
}

resource "aws_route_table_association" "associate" {
  subnet_id = "${aws_subnet.naz-db-subnet.id}"
  route_table_id = "${aws_route_table.local.id}"
}