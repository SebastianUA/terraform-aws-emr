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
    source                                              = "../"
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
