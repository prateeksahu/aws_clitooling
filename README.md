# Bash Script to control AWS EC2 Instances

I have had a rough time starting and stopping instances to save cost but also
getting bogged down with the DHCP IPs on every start. This script is written
for Ubuntu/Debian systems to control your instance from you command line and
also configure your ~/.ssh/config so that you don't have to manually check the
IP and update before you can start working.

## Usage

```
Usage: ./controlInstance.sh <EC2 Instance Name> [OPT] [profile]
Options: start, stop
Profile: [default], ...
Start will create and entry in .ssh/config for given instance name.
If an entry already exists, it will replace the hostname with the new Public Hostname.
```

## How to run

The tool depends on awscli toolchain. If you already have an existing aws
account configured please create another profile name to register a new account.
Steps to do so are enumerated below. The original account will be under
`default` profile. The script uses `default` if no profile is given as
argument. If you have not configured any aws account then the script will
prompt you to configure it the first time you run it.

### Create new profile

Skip if you do not have an existing profile. Replace `<profile-name>` with an
appropriate value (eg `project`).
```
$> awscli --profile <profile-name> configure
Access key: <use your access key>
Secret key: <use your secret key>
default region: <use the default location for EC2 instances>
default output: json
```
### Run the script

Run: `./controlInstance vm-name start` or `./controlInstance vm-name start
project`

Stop: `./controlInstance vm-name stop` or `./controlInstance vm-name stop project`

When start command is used, the script creates a new .ssh/config instance if
the vm is being started for the very first time. If it has previously been
started using the script, it will overwrite the existing entry to reflect the
new IP.

When setting it up for the first time, we will need the username and complete
path to .pem file (for the associated vm-name) to setup the config entry.

After it, you can connect to the ec2 instance by `ssh vm-name`.
