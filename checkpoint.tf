##########################################
############# Management #################
##########################################
# Deploy CP Management cloudformation template - sk130372
# Run a user-data script to configure the manager with rules 
# and CME setup including the VPN mesh 
resource "aws_cloudformation_stack" "checkpoint_Management_cloudformation_stack" {
  name = "${var.project_name}-Management"

  parameters = {
    VPC             = aws_vpc.management_vpc.id

    AdminCIDR       = aws_vpc.management_vpc.cidr_block
    ManagementSubnet= aws_subnet.management_subnet.id
    GatewaysAddresses                        = var.outbound_cidr_vpc
    KeyName         = var.key_name
    Shell           = "/bin/bash"
  }

  template_url       = "https://cgi-cfts.s3.amazonaws.com/management/management.yaml"
  capabilities       = ["CAPABILITY_IAM"]
  disable_rollback   = true
  timeout_in_minutes = 50
}



# note: install log file in /var/log/cloud-user-data
# CME log file in 
# sed -i '/template_name/c\\${var.outbound_configuration_template_name}: autoscale-2-nic-management' /etc/cloud-version ,

##########################################
########### Outbound ASG  ################
##########################################
# East West and Egress traffic
# Deploy CP TGW cloudformation template
resource "aws_cloudformation_stack" "checkpoint_tgw_cloudformation_stack" {
  name = "${var.project_name}-Outbound-ASG"

  parameters = {
    VpcCidr                                  = var.outbound_cidr_vpc
    AvailabilityZones                        = join(", ", data.aws_availability_zones.azs.names)
    NumberOfAZs                              = length(data.aws_availability_zones.azs.names)
    PublicSubnetCidrA                        = cidrsubnet(var.outbound_cidr_vpc, 8, 0)
    PublicSubnetCidrB                        = cidrsubnet(var.outbound_cidr_vpc, 8, 64)
    PublicSubnetCidrC                        = cidrsubnet(var.outbound_cidr_vpc, 8, 128)
    PublicSubnetCidrD                        = cidrsubnet(var.outbound_cidr_vpc, 8, 196)
    ManagementDeploy                         = "No"
    KeyPairName                              = var.key_name
    GatewaysAddresses                        = var.outbound_cidr_vpc
    GatewayManagement                        = "Locally managed"
    GatewaysInstanceType                     = var.outbound_asg_server_size
    GatewaysMinSize                          = "1"
    GatewaysMaxSize                          = "2"
    GatewaysBlades                           = "On"
    GatewaysLicense                          = "${var.cpversion}-BYOL"
    GatewaysPasswordHash                     = var.password_hash
    GatewaysSIC                              = var.sic_key
    ControlGatewayOverPrivateOrPublicAddress = "private"
    ManagementServer                         = var.template_management_server_name
    ConfigurationTemplate                    = var.outbound_configuration_template_name
    Name                                     = "${var.project_name}-CheckPoint-TGW"
    Shell                                    = "/bin/bash"
  }

  #template_url       = "https://s3.amazonaws.com/CloudFormationTemplate/checkpoint-tgw-asg-master.yaml" 
  #template_url = "https://raw.githubusercontent.com/CheckPointSW/CloudGuardIaaS/3fa4695c23e976155dc0b2fcd48e806960f3b15c/aws/templates/tgw-asg-r8030/checkpoint-tgw-asg-master.yaml"
  #template_url = "https://cc-checkpoint.s3.amazonaws.com/checkpoint-tgw-asg-master.yaml"
  template_url = "https://cc-checkpoint.s3.us-east-1.amazonaws.com/checkpoint-tgw-asg-master.yaml?response-content-disposition=inline&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEAgaCWV1LXdlc3QtMiJIMEYCIQCgNQvxqXOxvhpOCoR%2FWLPic2wiCZjn097knhr8G43RAQIhAMpSCsjVCiDLtbYVtoc48hANX5aWfadFUThAFP9WpMvHKv8CCDEQAxoMNjc1Mzk2MDkzMzUzIgxaxn3TBn3Twaw97cgq3ALwtDfvlKRWfsyyPCf%2Bv2%2BCl%2Bx%2BLbg3QfsswwZoNmHKAQpAjPm7jIB3qkDir0FndpJz%2FDv%2B8NrhE%2BL758MOg%2F3TZqaK9h92YW%2BTeYjNTO%2FzkV3F0IqrSLadgUEE6nMY8GJZGPVsvPoxDhOUWMMS1R5HFN6hqXRPuMRmU3du563WUiCsQDbfuHpliQTMtjaEuRBkZlId83i1g3MueJTmI6tHPUwsxGiuXTu0wUUwhPMbaVYtS8lhoLdSVQw1UvBHVSIFUOmRCjA%2FsDF%2BgXagWIl9GZ9LTh%2B7lSfZOEhF9cLNqScea99oKVLI0vL9Rl5Zf8PkiemRQq0T1c92WBKjWCf8kZW5G%2BzZo6XE12TzHHJRNDRWEkXecnklNS9%2B02Q7pGE5U9YKrlio475XVEppH6xSX6wIf04IBuY%2Fx9bHKkzgf9JwbJNrvNSpZk5irnwVKihuCP3UorEdBYwwCnQwtYf3lQY6sgISlIEzaWjRPgY1FYl11iFiNZUhZ6f88A6EfwRmUm6ZGAZVY0JVS9hyUOnde%2F3nSirZUWwhoVZUZeV1t5JQbMYRV%2FB9CUOlHr9%2FJSr67NylF%2BeII71%2Bs%2Bsz73VYQDEjKceqW4IR7b82ROCqvxvynwaUS4RFvis46nDqkq9ZVCY0uEhLKc%2F5ykmAJyHy%2Bo3rGZjxkRuMSe3lyvsWspnE18NcxeXbOh7fuA9pJabCc5MyHFjYfbtWd1GLabTwxMz0RQ%2BUmuxkk77ZnQ07aPYJ4zE4NaZNG4a3SWlnIWoRHz2Hp0q88oVJ79pnsaGi1Pq2zsaAzqzzzXZbjtQ%2BX%2FA8LjezLMoBSp%2Fx9QdOwNmbsjTFGjKHZ1CykyZCFhwXKM7a6v2dcUeg1Jw0BuTZCAfIvask51s%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20220630T154651Z&X-Amz-SignedHeaders=host&X-Amz-Expires=43200&X-Amz-Credential=ASIAZ2QF6QWU4PTEZMOM%2F20220630%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Signature=836f3ed12e7df644e7ace68d752e24eb95d83d66fb0c75e45ad66f0755e2ccab"
  capabilities       = ["CAPABILITY_IAM"]
  disable_rollback   = true
  timeout_in_minutes = 50
}
##########################################
########### Inbound ASG  #################
##########################################
# Northbound hub
# Deploy CP ASG cloudformation template
resource "aws_cloudformation_stack" "checkpoint_inbound_asg_cloudformation_stack" {
  name = "${var.project_name}-Inbound-ASG"

  parameters = {
    VPC                                      = aws_vpc.inbound_vpc.id
    ControlGatewayOverPrivateOrPublicAddress = "private"
    ManagementServer                         = var.template_management_server_name
    ConfigurationTemplate                    = var.inbound_configuration_template_name
    KeyName                                  = var.key_name
    Shell                                    = "/bin/bash"
    GatewaysSubnets                          = aws_subnet.inbound_subnet[1].id
    GatewaySICKey                            = var.sic_key
  }

  template_url       = "https://cgi-cfts.s3.amazonaws.com/autoscale/autoscale.yaml"
  capabilities       = ["CAPABILITY_IAM"]
  disable_rollback   = true
  timeout_in_minutes = 50
}
