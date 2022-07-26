resource "aws_vpc" "Main" {                
   cidr_block       = var.main_vpc_cidr
   tags = {
     Name = "dev-vpc"
}     
   instance_tenancy = "default"
 }
 resource "aws_internet_gateway" "IGW" {    
    vpc_id =  aws_vpc.Main.id               
 }
 resource "aws_subnet" "publicsubnets" {    
   vpc_id =  aws_vpc.Main.id
   cidr_block = "${var.public_subnets}"        
 }                   
 resource "aws_subnet" "privatesubnets" {
   vpc_id =  aws_vpc.Main.id
   cidr_block = "${var.private_subnets}"          
 }
 resource "aws_route_table" "PublicRT" {   
    vpc_id = aws_vpc.Main.id
         route {
    cidr_block = "0.0.0.0/0"               
    nat_gateway_id = aws_nat_gateway.NATgw.id
     }
 }
 resource "aws_route_table" "PrivateRT" {    
    vpc_id = aws_vpc.Main.id
         route {
    cidr_block = "0.0.0.0/0"            
    nat_gateway_id = aws_nat_gateway.NATgw.id
    }
 }
 resource "aws_route_table_association" "PublicRTassociation" {
    subnet_id = aws_subnet.publicsubnets.id
    route_table_id = aws_route_table.PublicRT.id
 }
 resource "aws_route_table_association" "PrivateRTassociation" {
    subnet_id = aws_subnet.privatesubnets.id
    route_table_id = aws_route_table.PrivateRT.id
 }
 resource "aws_eip" "nateIP" {
   vpc   = true
 }
 resource "aws_nat_gateway" "NATgw" {
   allocation_id = aws_eip.nateIP.id
   subnet_id = aws_subnet.publicsubnets.id
 }
 resource "aws_vpc" "mainvpc" {
  cidr_block = "10.101.0.0/16"
}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = "acl-06c73702796078eea"

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.101.0.0/16"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.101.0.0/16"
    from_port  = 80
    to_port    = 80
  }
}
resource "aws_flow_log" "my-jagan-bucket-s3-test" {
  log_destination      = aws_s3_bucket.my-jagan-bucket-s3-test.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = "vpc-0b2d4955ec9855eb2"
  destination_options {
    file_format        = "parquet"
    per_hour_partition = true
  }
}
resource "aws_s3_bucket" "my-jagan-bucket-s3-test" {
  bucket = "my-jagan-bucket-s3-test"
  versioning {
        enabled = true
    }

    lifecycle_rule {
        enabled = true

        noncurrent_version_expiration {
            days = 7
        }
    }
}
resource "aws_s3_bucket_logging" "my-jagan-bucket-s3-test" {
  bucket = "my-jagan-bucket-s3-test"

  target_bucket = "my-jagan-bucket-s3-test"
  target_prefix = "AWSLogs/"
}
resource "aws_kms_key" "mykey" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}
resource "aws_s3_bucket_server_side_encryption_configuration" "my-jagan-bucket-s3-test" {
  bucket = "my-jagan-bucket-s3-test"

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.mykey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
resource "aws_s3_bucket_intelligent_tiering_configuration" "my-jagan-bucket-s3-test" {
  bucket = "my-jagan-bucket-s3-test"
  name   = "EntireBucket"
  
  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 125
  }
}
