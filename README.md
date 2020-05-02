# Work with AWS Elastic MapReduce via terraform

A terraform module for making EMR.

*NOTE*: Full Terrafrom modules that I have is located here: [https://github.com/SebastianUA/terraform](https://github.com/SebastianUA/terraform)

## Usage
----------------------
Import the module and retrieve with ```terraform get``` or ```terraform get --update```. Adding a module resource to your template, e.g. `main.tf`:

```
#
# MAINTAINER Vitaliy Natarov "vitaliy.natarov@yahoo.com"
#
terraform {
    required_version = "~> 0.12.12"
}

provider "aws" {
    region                  = "us-east-1"
    shared_credentials_file = pathexpand("~/.aws/credentials")
}

module "emr" {
    source                                              = "./module"
    name                                                = "TEST"
    environment                                         = "stage"

    # EMR security
    enable_emr_security_configuration                   = false
    emr_security_configuration_name                     = "emr-security-config"
    emr_security_configuration_configuration            = file("./additional_files/erm-security-config.json")

    # EMR cluster
    enable_emr_cluster                                  = true
    emr_cluster_name                                    = "emr-cluster-name"
    emr_cluster_release_label                           = "emr-5.29.0"
    emr_cluster_service_role                            = "arn:aws:iam::167127734783:role/emr-service-role"

    emr_cluster_applications                            = ["Spark", "Presto", "Spark"]
    emr_cluster_additional_info                         = file("./additional_files/emr-cluster-additional_info.json")
    emr_cluster_termination_protection                  = false
    emr_cluster_keep_job_flow_alive_when_no_steps       = true
    emr_cluster_ebs_root_volume_size                    = 30
    emr_cluster_configurations_json                     = file("./additional_files/emr-cluster-configurations_json.json")
    emr_cluster_autoscaling_role                        = "arn:aws:iam::167127734783:role/emr-service-role"

    emr_cluster_ec2_attributes                          =[{
        # If you want to use public subnet. Tested! :
        # subnet_id                           = "subnet-32xfzfds4"
        # emr_managed_master_security_group   = "sg-8980fd9sfdsf"
        # emr_managed_slave_security_group    = "sg-8980fd9sfdsf"
        # instance_profile                    = "arn:aws:iam::167127734783:instance-profile/emr-service-role"

        # If you want to use private subnet:
        subnet_id                           = "sg-6u99fdsf"
        emr_managed_master_security_group   = "sg-0ac2ce954f45c8f6a"
        emr_managed_slave_security_group    = "sg-0ac2ce954f45c8f6a"
        # You cannot specify a ServiceAccessSecurityGroup for a cluster launched in public subnet
        service_access_security_group       = "sg-0919aabecaea96510"
        instance_profile                    = "arn:aws:iam::167127734783:instance-profile/emr-service-role"
    }]

    emr_cluster_master_instance_group_ebs_config        = [{
        instance_type   = "m4.large"
        instance_count  = 1

        ebs_config_size                 = 10
        ebs_config_type                 = "gp2"
        ebs_config_volumes_per_instance = 1
    }]

    emr_cluster_core_instance_group_ebs_config          = [{
        instance_type                   = "c4.large"
        instance_count                  = 1
        # bid_price                       = "1.30"
        autoscaling_policy              = file("./additional_files/emr-cluster-core_instance_group-autoscaling_policy.json")

        ebs_config_size                 = 10
        ebs_config_type                 = "gp2"
        ebs_config_volumes_per_instance = 1
    }]

    # it's not working when uses private sabnet;
    # The VPC/subnet configuration was invalid: Your cluster needs access to SQS to enable debugging but subnet does not have route to access SQS. Learn more about private subnet configurations: https://docs.aws.amazon.com/ElasticMapReduce/latest/ManagementGuide/emr-plan-vpc-subnet.html
    #emr_cluster_bootstrap_action                        = [{
    #    path = "s3://elasticmapreduce/bootstrap-actions/run-if"
    #    name = "runif"
    #    args = ["instance.isMaster=true", "echo running on master node"]
    #}]

    #emr_cluster_step                                    = [{
    #    name                = "Setup Hadoop Debugging"
    #    action_on_failure   = "TERMINATE_CLUSTER"
    #
    #    hadoop_jar  = "command-runner.jar"
    #    hadoop_args = ["state-pusher-script"]
    #}]

    # EMR instance group
    enable_emr_instance_group                           = true
    emr_instance_group_name                             = "emr-instance-group"
    emr_instance_group_instance_type                    = "m5.xlarge"
    emr_instance_group_instance_count                   = 1
    emr_instance_group_ebs_config                       = [{
        size                 = 10
        type                 = "gp2"
        volumes_per_instance = 1
    }]

    emr_instance_group_autoscaling_policy               = file("./additional_files/emr-cluster-core_instance_group-autoscaling_policy.json")
    emr_instance_group_configurations_json              = null


    tags                                                = map(
        "Env", "stage",
        "Orchestration", "Terraform",
        "Createdby", "Vitaliy Natarov",
    )
}

```

## Module Input Variables
----------------------
- `name` - Name to be used on all resources as prefix (`default = TEST`)
- `environment` - Environment for service (`default = STAGE`)
- `tags` - A list of tag blocks. Each element should have keys named key, value, etc. (`default = ""`)
- `enable_emr_cluster` - Enable emr cluster usage (`default = ""`)
- `emr_cluster_name` - The name of the job flow (`default = ""`)
- `emr_cluster_release_label` - (Required) The release label for the Amazon EMR release (`default = ""`)
- `emr_cluster_service_role` - (Required) IAM role that will be assumed by the Amazon EMR service to access AWS resources (`default = ""`)
- `emr_cluster_scale_down_behavior` - (Optional) The way that individual Amazon EC2 instances terminate when an automatic scale-in activity occurs or an instance group is resized. (`default = ""`)
- `emr_cluster_additional_info` - (Optional) A JSON string for selecting additional features such as adding proxy information. Note: Currently there is no API to retrieve the value of this argument after EMR cluster creation from provider, therefore Terraform cannot detect drift from the actual EMR cluster if its value is changed outside Terraform. (`default = ""`)
- `emr_cluster_security_configuration` - (Optional) The security configuration name to attach to the EMR cluster. Only valid for EMR clusters with release_label 4.8.0 or greater (`default = ""`)
- `emr_cluster_log_uri` - (Optional) S3 bucket to write the log files of the job flow. If a value is not provided, logs are not created (`default = ""`)
- `emr_cluster_applications` - (Optional) A list of applications for the cluster. Valid values are: Flink, Hadoop, Hive, Mahout, Pig, Spark, and JupyterHub (as of EMR 5.14.0). Case insensitive (`default = ""`)
- `emr_cluster_termination_protection` - (Optional) Switch on/off termination protection (default is false, except when using multiple master nodes). Before attempting to destroy the resource when termination protection is enabled, this configuration must be applied with its value set to false. (`default = ""`)
- `emr_cluster_keep_job_flow_alive_when_no_steps` - (Optional) Switch on/off run cluster with no steps or when all steps are complete (default is on) (`default = ""`)
- `emr_cluster_ebs_root_volume_size` - (Optional) Size in GiB of the EBS root device volume of the Linux AMI that is used for each EC2 instance. Available in Amazon EMR version 4.x and later. (`default = ""`)
- `emr_cluster_custom_ami_id` - (Optional) A custom Amazon Linux AMI for the cluster (instead of an EMR-owned AMI). Available in Amazon EMR version 5.7.0 and later. (`default = ""`)
- `emr_cluster_configurations` - (Optional) List of configurations supplied for the EMR cluster you are creating (`default = ""`)
- `emr_cluster_configurations_json` - (Optional) A JSON string for supplying list of configurations for the EMR cluster. (`default = ""`)
- `emr_cluster_visible_to_all_users` - Optional) Whether the job flow is visible to all IAM users of the AWS account associated with the job flow. Default true (`default = True`)
- `emr_cluster_autoscaling_role` - (Optional) An IAM role for automatic scaling policies. The IAM role provides permissions that the automatic scaling feature requires to launch and terminate EC2 instances in an instance group. (`default = ""`)
- `emr_cluster_step_concurrency_level` - (Optional) The number of steps that can be executed concurrently. You can specify a maximum of 256 steps. Only valid for EMR clusters with release_label 5.28.0 or greater. (default is 1) (`default = 1`)
- `emr_cluster_master_instance_group` - (Optional) Configuration block to use an Instance Group for the master node type. Cannot be specified if master_instance_type argument or instance_group configuration blocks are set. (`default = ""`)
- `emr_cluster_master_instance_group_ebs_config` - (Optional) Configuration block to use an Instance Group for the master node type. Cannot be specified if master_instance_type argument or instance_group configuration blocks are set. (`default = ""`)
- `emr_cluster_core_instance_group` - (Optional) Configuration block to use an Instance Group for the core node type. Cannot be specified if core_instance_count argument, core_instance_type argument, or instance_group configuration blocks are set. (`default = ""`)
- `emr_cluster_core_instance_group_ebs_config` - (Optional) Configuration block to use an Instance Group for the core node type. Cannot be specified if core_instance_count argument, core_instance_type argument, or instance_group configuration blocks are set. (`default = ""`)
- `emr_cluster_ec2_attributes` - (Optional) Attributes for the EC2 instances running the job flow. (`default = ""`)
- `emr_cluster_kerberos_attributes` - (Optional) Kerberos configuration for the cluster. (`default = ""`)
- `emr_cluster_bootstrap_action` - (Optional) Ordered list of bootstrap actions that will be run before Hadoop is started on the cluster nodes. (`default = ""`)
- `emr_cluster_step` - (Optional) List of steps to run when creating the cluster. Defined below. It is highly recommended to utilize the lifecycle configuration block with ignore_changes if other steps are being managed outside of Terraform. This argument is processed in attribute-as-blocks mode. (`default = ""`)
- `enable_emr_instance_group` - Enable emr instance group usage (`default = ""`)
- `emr_instance_group_name` - Human friendly name given to the instance group. Changing this forces a new resource to be created. (`default = ""`)
- `emr_instance_group_cluster_id` - ID of the EMR Cluster to attach to. Changing this forces a new resource to be created. (`default = ""`)
- `emr_instance_group_instance_type` - (Required) The EC2 instance type for all instances in the instance group. Changing this forces a new resource to be created. (`default = ""`)
- `emr_instance_group_instance_count` - (optional) target number of instances for the instance group. defaults to 0. (`default = ""`)
- `emr_instance_group_bid_price` - (Optional) If set, the bid price for each EC2 instance in the instance group, expressed in USD. By setting this attribute, the instance group is being declared as a Spot Instance, and will implicitly create a Spot request. Leave this blank to use On-Demand Instances. (`default = ""`)
- `emr_instance_group_ebs_optimized` - (Optional) Indicates whether an Amazon EBS volume is EBS-optimized. Changing this forces a new resource to be created. (`default = ""`)
- `emr_instance_group_autoscaling_policy` - (Optional) The autoscaling policy document. This is a JSON formatted string. See EMR Auto Scaling (`default = ""`)
- `emr_instance_group_configurations_json` - (Optional) A JSON string for supplying list of configurations specific to the EMR instance group. Note that this can only be changed when using EMR release 5.21 or later. (`default = ""`)
- `emr_instance_group_ebs_config` - (Optional) One or more ebs_config blocks as defined below. Changing this forces a new resource to be created. (`default = ""`)
- `enable_emr_security_configuration` - Enable emr security configuration usage (`default = ""`)
- `emr_security_configuration_configuration` - (Required) A JSON formatted Security Configuration (`default = ""`)
- `emr_security_configuration_name` - (Optional) The name of the EMR Security Configuration. By default generated by Terraform. (`default = ""`)
- `emr_security_configuration_name_prefix` - (Optional) Creates a unique name beginning with the specified prefix. Conflicts with emr_security_configuration_name. (`default = ""`)

## Module Output Variables
----------------------
- `emr_cluster_arn` - The ARN of the cluster.
- `emr_cluster_name` - The name of the cluster.
- `emr_cluster_id` - The ID of the EMR Cluster
- `emr_cluster_release_label` - The release label for the Amazon EMR release.
- `emr_cluster_master_public_dns` - The public DNS name of the master EC2 instance.
- `emr_cluster_log_uri` - The path to the Amazon S3 location where logs for this cluster are stored.
- `emr_cluster_applications` - The applications installed on this cluster.
- `emr_cluster_ec2_attributes` - Provides information about the EC2 instances in a cluster grouped by category: key name, subnet ID, IAM instance profile, and so on.
- `emr_cluster_bootstrap_action` - A list of bootstrap actions that will be run before Hadoop is started on the cluster nodes.
- `emr_cluster_configurations` - The list of Configurations supplied to the EMR cluster.
- `emr_cluster_service_role` - The IAM role that will be assumed by the Amazon EMR service to access AWS resources on your behalf.
- `emr_cluster_visible_to_all_users` - Indicates whether the job flow is visible to all IAM users of the AWS account associated with the job flow.
- `emr_cluster_tags` - The list of tags associated with a cluster.
- `emr_instance_group_id` - The EMR Instance ID
- `emr_instance_group_running_instance_count` - The number of instances currently running in this instance group.
- `emr_instance_group_status` - The current status of the instance group.
- `emr_security_configuration_id` - The ID of the EMR Security Configuration (Same as the name)
- `emr_security_configuration_name` - The Name of the EMR Security Configuration
- `emr_security_configuration_configuration` - The JSON formatted Security Configuration
- `emr_security_configuration_creation_date` - Date the Security Configuration was created


## Authors

Created and maintained by [Vitaliy Natarov](https://github.com/SebastianUA). An email: [vitaliy.natarov@yahoo.com](vitaliy.natarov@yahoo.com).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/SebastianUA/terraform/blob/master/LICENSE) for full details.
