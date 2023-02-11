# Yogafire
Collection of tools useful for AWS(ec2).

## Installation

You can choose one of the following.

### Local Machine

cpanm https://github.com/toritori0318/p5-Yogafire/tarball/master

### Yoga Commands with Docker

1. Run the following to generate an empty .yoga file

    ```bash
    touch $HOME/.yoga
    chmod 600 $HOME/.yoga
    ```
2. Add the following to your shell startup file such as .bashrc / .zshrc / ...

    ```bash
    alias yoga="docker run -it --platform linux/amd64 -v ~/.yoga:/root/.yoga -v ~/.aws:/root/.aws toritori0318/p5-yogafire:latest"
    ```

### Commands

    Common commands:
                    config: Yogafire Config Manager
                       use: Use profile

    Instance commands:
      change-instance-type: EC2 Change Instance Type
                       cmd: Execute remote command
           copy-and-launch: EC2 Copy and launch
              create-image: EC2 Create Image
             expand-volume: EC2 Expand Volume
                       get: Rsync get file from remote. (rsync -avuc)
                 get-noopt: Rsync get file from remote.
                      info: EC2 Instance Infomation
                        ls: EC2 List Instance
                       put: Rsync put local file to remote.(rsync -avuc)
                 put-noopt: Rsync put local file to remote.
                    reboot: EC2 Reboot Instances
                       ssh: EC2 SSH Instance
                  ssh-tmux: EC2 SSH Instance
                     start: EC2 Start Instances
                      stop: EC2 Stop Instances
                 terminate: EC2 Terminate Instance
    
    Image commands:
                    ls-ami: Image List
             run-instances: Running Instance
    
    Vpc commands:
                 vpc-graph: VPC Graph View
                  vpc-info: VPC List vpcs
    
    Plugin commands:
           all-region-info: All Region Info
                amiwatcher: EC2 image status watcher
                aws-status: Show AWS Status
           ec2-params-dump: EC2 Parameter Dumper
                ec2watcher: EC2 instance status watcher
                     hosts: Operation for hosts file
             instance-type: Show Instance Types
                    region: Show AWS Regions
                    render: Render Tool
                 scale-ec2: Update EC2 Count
        show-copy-snapshot: Image List
                 sshconfig: Operation for sshconfig
                   summary: EC2 instance summary report
           update-ec2-tags: Update EC2 Tags

## Tutorial

http://d.hatena.ne.jp/tori243/20130102/1357142925

## Configuration(Priority)

1. AWS environment
  - AWS_ACCESS_KEY_ID
  - AWS_SECRET_ACCESS_KEY
  - AWS_DEFAULT_REGION
  - AWS_PROFILE
2. $HOME/.yoga ([example](/example/config/yoga))
3. [AWS CLI Config](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)

### Default value of configration

The `_yoga_default` key can be used as the default value for all profiles.

[Here's](/example/config/yoga) an example.

## Yoga Profile

- Show profile list

    ```
    % yoga use

    --------- profiles ---------
       [aws_profile] hoge-profile  ----> .aws/config profile
       [aws_profile] fuga-profile  ----> .aws/config profile
     * global                      ----> current profile
    ```

- Set default profile
    ```
    % yoga use hoge-profile

    --------- profiles ---------
       [aws_profile] hoge-profile  ----> .aws/config profile
       [aws_profile] fuga-profile  ----> .aws/config profile
       global
     * hoge-profile                ----> current profile
    ```

- Specify directly by command
    ```
    % yoga ls --profile fuga-profile
    ...
    ```
