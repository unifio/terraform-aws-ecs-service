Terraform module that creates an ECS service with the following features

* Runs an ECS service with or without an AWS load balancer.
* Stream logs to a CloudWatch log group encrypted with a KMS key.
* Associate multiple target groups with Network Load Balancers (NLB) and Application Load Balancers (ALB).
* Supports running ECS tasks on EC2 instances or Fargate.

## Default container definition (hello world app)

We create an initial task definition using the `golang:alpine` image as a way
to validate the initial infrastructure is working: visiting the site shows
a simple Go hello world page listening on two configurable ports. This is
meant to get a proof of concept instance up and running and to help with
testing.

If you want to customize the listener ports for the hello world app, you can
modify the `hello_world_container_ports` variable.

In production usage, we expect deployment tooling to manage the container
definitions going forward, not Terraform.

## Terraform Versions

Terraform 0.12. Pin module version to ~> 3.0. Submit pull-requests to master branch.

Terraform 0.11. Pin module version to ~> 1.14. Submit pull-requests to terraform011 branch.

## Usage

### ECS service associated with an Application Load Balancer (ALB)

```hcl
module "app_ecs_service" {
  source = "trussworks/ecs-service/aws"

  name        = "app"
  environment = "prod"

  ecs_cluster                   = aws_ecs_cluster.mycluster
  ecs_vpc_id                    = module.vpc.vpc_id
  ecs_subnet_ids                = module.vpc.private_subnets
  kms_key_id                    = aws_kms_key.main.arn
  tasks_desired_count           = 2

  associate_alb      = true
  alb_security_group = module.security_group.id
  target_groups =
  [
    {
      container_port             = 8443
      container_healthcheck_port = 8443
      lb_target_group_arn        = module.alb.arn
    }
  ]
}
```

### ECS Service associated with a Network Load Balancer(NLB)

```hcl
module "app_ecs_service" {
  source = "trussworks/ecs-service/aws"

  name        = "app"
  environment = "prod"

  ecs_cluster                   = aws_ecs_cluster.mycluster
  ecs_vpc_id                    = module.vpc.vpc_id
  ecs_subnet_ids                = module.vpc.private_subnets
  kms_key_id                    = aws_kms_key.main.arn
  tasks_desired_count           = 2

  associate_nlb          = true
  nlb_subnet_cidr_blocks = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]

  lb_target_groups =
  [
    {
      container_port             = 8443
      container_healthcheck_port = 8080
      lb_target_group_arn        = module.nlb.arn
    }
  ]
}
```

### ECS Service without any AWS load balancer

```hcl
module "app_ecs_service" {
  source = "trussworks/ecs-service/aws"

  name        = "app"
  environment = "prod"

  ecs_cluster                   = aws_ecs_cluster.mycluster
  ecs_vpc_id                    = module.vpc.vpc_id
  ecs_subnet_ids                = module.vpc.private_subnets
  kms_key_id                    = aws_kms_key.main.arn
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_security\_group\_ids | In addition to the security group created for the service, a list of security groups the ECS service should also be added to. | `list(string)` | `[]` | no |
| alb\_security\_group | Application Load Balancer (ALB) security group ID to allow traffic from. | `string` | `""` | no |
| assign\_public\_ip | Whether this instance should be accessible from the public internet. Default is false. | `bool` | `false` | no |
| associate\_alb | Whether to associate an Application Load Balancer (ALB) with the ECS service. | `bool` | `false` | no |
| associate\_nlb | Whether to associate a Network Load Balancer (NLB) with the ECS service. | `bool` | `false` | no |
| cloudwatch\_alarm\_actions | The list of actions to take for cloudwatch alarms | `list(string)` | `[]` | no |
| cloudwatch\_alarm\_cpu\_enable | Enable the CPU Utilization CloudWatch metric alarm | `bool` | `true` | no |
| cloudwatch\_alarm\_cpu\_threshold | The CPU Utilization threshold for the CloudWatch metric alarm | `number` | `80` | no |
| cloudwatch\_alarm\_mem\_enable | Enable the Memory Utilization CloudWatch metric alarm | `bool` | `true` | no |
| cloudwatch\_alarm\_mem\_threshold | The Memory Utilization threshold for the CloudWatch metric alarm | `number` | `80` | no |
| cloudwatch\_alarm\_name | Generic name used for CPU and Memory Cloudwatch Alarms | `string` | `""` | no |
| command | The command that is passed to the container | `list(string)` | `[]` | no |
| container\_definitions | Container definitions provided as valid JSON document. Default uses golang:alpine running a simple hello world. | `string` | `""` | no |
| container\_image | The image of the container. | `string` | n/a | yes |
| cost\_tags | Additional tags for cost tracking | `map(string)` | `{}` | no |
| disableNetworking | When this parameter is true, networking is disabled within the container | `bool` | `false` | no |
| dnsSearchDomains | A list of DNS search domains that are presented to the container | `list(string)` | `[]` | no |
| dnsServers | A list of DNS servers that are presented to the container | `list(string)` | `[]` | no |
| dockerLabels | A key/value map of labels to add to the container | `map(string)` | `{}` | no |
| dockerSecurityOptions | A list of strings to provide custom labels for SELinux and AppArmor multi-level security systems | `list(string)` | `[]` | no |
| ecr\_repo\_arns | The ARNs of the ECR repos.  By default, allows all repositories. | `list(string)` | <pre>[<br>  "*"<br>]</pre> | no |
| ecs\_cluster | ECS cluster object for this task. | <pre>object({<br>    arn  = string<br>    name = string<br>  })</pre> | n/a | yes |
| ecs\_instance\_role | The name of the ECS instance role. | `string` | `""` | no |
| ecs\_subnet\_ids | Subnet IDs for the ECS tasks. | `list(string)` | n/a | yes |
| ecs\_use\_fargate | Whether to use Fargate for the task definition. | `bool` | `false` | no |
| ecs\_vpc\_id | VPC ID to be used by ECS. | `string` | n/a | yes |
| entryPoint | The entry point that is passed to the container | `list(string)` | `[]` | no |
| environment | Environment tag, e.g prod. | `string` | n/a | yes |
| extraHosts | A list of hostnames and IP address mappings to append to the /etc/hosts file on the container | `list(string)` | `[]` | no |
| family | The image family for the task definition | `string` | n/a | yes |
| fargate\_task\_cpu | Number of cpu units used in initial task definition. Default is minimum. | `number` | `256` | no |
| fargate\_task\_memory | Amount (in MiB) of memory used in initial task definition. Default is minimum. | `number` | `512` | no |
| healthCheck | The health check command and associated configuration parameters for the container | `any` | `{}` | no |
| hostname | The hostname to use for your container | `string` | `""` | no |
| interactive | When this parameter is true, this allows you to deploy containerized applications that require stdin or a tty to be allocated | `bool` | `false` | no |
| ipc\_mode | The IPC resource namespace to use for the containers in the task | `string` | n/a | yes |
| kms\_key\_id | KMS customer managed key (CMK) ARN for encrypting application logs. | `string` | n/a | yes |
| lb\_target\_groups | List of load balancer target group objects containing the lb\_target\_group\_arn, container\_port and container\_health\_check\_port. The container\_port is the port on which the container will receive traffic. The container\_health\_check\_port is an additional port on which the container can receive a health check. The lb\_target\_group\_arn is either Application Load Balancer (ALB) or Network Load Balancer (NLB) target group ARN tasks will register with. | <pre>list(<br>    object({<br>      container_port              = number<br>      container_health_check_port = number<br>      lb_target_group_arn         = string<br>      }<br>    )<br>  )</pre> | `[]` | no |
| links | The link parameter allows containers to communicate with each other without the need for port mappings | `list(string)` | `[]` | no |
| linuxParameters | Linux-specific modifications that are applied to the container, such as Linux KernelCapabilities | `any` | `{}` | no |
| logs\_cloudwatch\_group | CloudWatch log group to create and use. Default: /ecs/{name}-{environment} | `string` | `""` | no |
| logs\_cloudwatch\_retention | Number of days you want to retain log events in the log group. | `number` | `90` | no |
| memoryReservation | The soft limit (in MiB) of memory to reserve for the container | `number` | `0` | no |
| mountPoints | The mount points for data volumes in your container | `list(any)` | `[]` | no |
| name | The service name. | `string` | n/a | yes |
| nlb\_subnet\_cidr\_blocks | List of Network Load Balancer (NLB) CIDR blocks to allow traffic from. | `list(string)` | `[]` | no |
| pid\_mode | The process namespace to use for the containers in the task | `string` | n/a | yes |
| placement\_constraints | An array of placement constraint objects to use for the task | `list(string)` | `[]` | no |
| portMappings | The list of port mappings for the container | `list(any)` | `[]` | no |
| privileged | When this parameter is true, the container is given elevated privileges on the host container instance (similar to the root user) | `bool` | `false` | no |
| pseudoTerminal | When this parameter is true, a TTY is allocated | `bool` | `false` | no |
| readonlyRootFilesystem | When this parameter is true, the container is given read-only access to its root file system | `bool` | `false` | no |
| register\_task\_definition | Registers a new task definition from the supplied family and containerDefinitions | `bool` | `true` | no |
| repositoryCredentials | The private repository authentication credentials to use | `map(string)` | `{}` | no |
| resourceRequirements | The type and amount of a resource to assign to a container | `list(string)` | `[]` | no |
| secrets | The secrets to pass to the container | `list(string)` | `[]` | no |
| systemControls | A list of namespaced kernel parameters to set in the container | `list(string)` | `[]` | no |
| tags | The metadata that you apply to the task definition to help you categorize and organize them | `map(string)` | `{}` | no |
| target\_container\_name | Name of the container the Load Balancer should target. Default: {name}-{environment} | `string` | `""` | no |
| tasks\_desired\_count | The number of instances of a task definition. | `number` | `1` | no |
| tasks\_maximum\_percent | Upper limit on the number of running tasks. | `number` | `200` | no |
| tasks\_minimum\_healthy\_percent | Lower limit on the number of running tasks. | `number` | `100` | no |
| ulimits | A list of ulimits to set in the container | `list(any)` | `[]` | no |
| user | The user name to use inside the container | `string` | `""` | no |
| volumes | A list of volume definitions in JSON format that containers in your task may use | `list(any)` | `[]` | no |
| volumesFrom | Data volumes to mount from another container | `list(string)` | `[]` | no |
| workingDirectory | The working directory in which to run commands inside the container | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| aws\_ecs\_cluster\_name | Name of the ECS cluster |
| aws\_ecs\_service\_name | Name of the ECS service |
| awslogs\_group | Name of the CloudWatch Logs log group containers should use. |
| awslogs\_group\_arn | ARN of the CloudWatch Logs log group containers should use. |
| ecs\_security\_group\_id | Security Group ID assigned to the ECS tasks. |
| instance\_role\_policy | ARN of the Instance Role Policy |
| task\_container\_definitions | A list of container definitions in JSON format that describe the different containers that make up your task |
| task\_definition\_arn | Full ARN of the Task Definition (including both family and revision). |
| task\_definition\_family | The family of the Task Definition. |
| task\_definition\_revision | The revision of the task in a particular family |
| task\_execution\_role | The role object of the task execution role that the Amazon ECS container agent and the Docker daemon can assume. |
| task\_execution\_role\_arn | The ARN of the task execution role that the Amazon ECS container agent and the Docker daemon can assume. |
| task\_execution\_role\_name | The name of the task execution role that the Amazon ECS container agent and the Docker daemon can assume. |
| task\_role | The IAM role object assumed by Amazon ECS container tasks. |
| task\_role\_arn | The ARN of the IAM role assumed by Amazon ECS container tasks. |
| task\_role\_name | The name of the IAM role assumed by Amazon ECS container tasks. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Upgrade Path

### 2.x.x to 3.0.0

In 3.0.0 the module added support for multiple load balancer target groups. To support this change, `container_port`, `container_health_check_port` and `lb_target_group` are being replaced with `lb_target_groups`

#### Without a load balancer

If you are using this module without an ALB or NLB then you can remove any references to `container_port`, `container_health_check_port` and `lb_target_group` if you were doing so.

#### Using with ALB or NLB target groups

If you are using an NLB or NLB target groups with this module then you will need replace the values of `container_port`, `container_health_check_port` and `lb_target_group` with

Below is an example of how the module would be instantiated prior to version 3.0.0

```hcl
module "app_ecs_service" {
  source = "trussworks/ecs-service/aws"
  ...
  container_port                  = 8443
  container_health_check_port     = 8080
  lb_target_group_arn             = module.alb.arn
  ...
}
```

In 3.0.0 the same example will look like the following

```hcl
module "app_ecs_service" {
  source = "trussworks/ecs-service/aws"
  ...
  lb_target_groups =
  [
    {
      container_port                  = 8443
      container_health_check_port     = 8080
      lb_target_group_arn             = module.alb.arn
    }
  ]
  ...
}
```


### 2.0.0 to 2.1.0

In 2.1.0 KMS log encryption is required by default. This requires that you create and attach a new AWS KMS key ARN.
As an example here is how to set that up (please review on your own):

```hcl
data "aws_iam_policy_document" "cloudwatch_logs_allow_kms" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }

    actions = [
      "kms:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Allow logs KMS access"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.us-west-2.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "main" {
  description         = "Key for ECS log encryption"
  enable_key_rotation = true

  policy = data.aws_iam_policy_document.cloudwatch_logs_allow_kms.json
}
```

**NOTE:** Best practice is to use a separate KMS key per ECS Service. Do not re-use KMS keys if it can be avoided.

### 1.15.0 to 2.0.0

v2.0.0 of this module is built against Terraform v0.12. In addition to
requiring this upgrade, the v1.15.0 version of the module took the name
of the ECS cluster as a parameter; v2.0.0 takes the actual object of the
ECS cluster as a parameter instead. You will need to update previous
instances of this module with the altered parameter.

## Developer Setup

Install dependencies (macOS)

```shell
brew install pre-commit go terraform terraform-docs
```

### Testing

[Terratest](https://github.com/gruntwork-io/terratest) is being used for
automated testing with this module. Tests in the `test` folder can be run
locally by running the following command:

```text
make test
```

Or with aws-vault:

```text
AWS_VAULT_KEYCHAIN_NAME=<NAME> aws-vault exec <PROFILE> -- make test
```
