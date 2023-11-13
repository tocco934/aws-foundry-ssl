# AWS Foundry VTT CloudFormation Deployment with TLS Encryption

This is a fork of the [**Foundry CF deploy script**](https://github.com/cat-box/aws-foundry-ssl) by Lupert and Cat.

**Main New Things**

- Supports Foundry 11
- Amazon Linux 2023 on EC2
- Node 20.x
- Newer more cost efficient / performant instance type support, including ARM64

## Installation

_Note:_ You'll need some technical expertise and basic familiarity with AWS to get this running. It's not quite click-ops, but it's close.

You can also refer to the original repo's wiki, but the gist is:

### Foundry VTT Download

1. Download the `NodeJS` installer for Foundry VTT from the Foundry VTT website, upload it to Google Drive

- Make the link publicly shared (anyone with the link can view)
- Make note of the link, or

2. have a Foundry VTT Patreon download link handy, or
3. upload it somewhere else it can be fetched publicly

It's not recommended to use the time-limited links that you can get from the Foundry VTT site, but if that works for you, it's also an option.

**Note:** Foundry `11.313` or newer is recommended due to Electron fixing a _second_ major security flaw in the WebP decoder.

### AWS Setup

- This script currently relies on your `default` VPC, which should be set up automatically when you first create your acccount. If you have a custom VPC, you'll need to edit this script to use it
- Create an SSH key in **EC2**, under `EC2 / Network & Security / Key Pairs`
  - You only need to do this once, _the first time_. If you tear down and redeploy the stack you can reuse the same SSH key
  - That said, consider rotating keys regularly as a good security practise
  - Keep the downloaded private keypair (PEM or PPK) file safe, you'll need it for [SSH / SCP access](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-to-linux-instance.html) to the EC2 server instance
- Then go to **CloudFormation** and choose to **Create a Stack** with new resources
  - Leave `Template is Ready` selected
  - Choose `Upload a template file`
  - Upload the `/cloudformation/Foundry_Deployment.template` file from this project
  - Fill in and check _all_ the details. I've tried to provide sensible defaults. At a minimum if you leave the defaults, the ones that need to be filled in are:
    - Add the link for downloading Foundry
    - Set an admin user password (for IAM)
    - Enter your domain name and TLD eg. `mydomain.com`
      - **Important:** Do _not_ include `www` or any other sub-domain prefix
    - Enter your email address for LetsEncrypt TLS (https) certificate issuance
    - Choose the SSH key pair you set up in the EC2 Key Pairs
    - _Optional:_ Add your IP to be allowed incoming access via SSH with a slash range eg. `123.45.67.89/32`. The `/xx` [subnet range](https://www.calculator.net/ip-subnet-calculator.html) on the end is required - if you aren't sure, use `/32`. You can always manually set or change this later in **EC2 Security Groups**
    - Choose an S3 bucket name for storing files - this name must be _globally unique_ across all S3 buckets that exist on AWS
      - If you host Foundry on eg. `foundry.mydomain.com` then `foundry-mydomain-com` would be a good recommendation

It should be pretty automated from there. Again, just be careful of the LetsEncrypt issuance limits.

If need be, set the LetsEncrypt TLS testing option to `False` in the CloudFormation setup if you are debugging a failed stack deploy. Should you run out of LetsEncrypt TLS requests, then you'll need to wait a week before trying again.

## Security and Updates

As of the `v1.1.0` release, Linux auto-patching is enabled by default. A utility script also exists to help you manage this if you want to disable or re-enable or run it.

It's also recommended to SSH into the instance and run `sudo dnf upgrade` every so often to make sure your packages are up to date with the latest fixes and security releases.

## Upgrading From a Previous Instance

**Foundry 11 is a big update.**

Many plugins need to be updated etc. in addition to the base hardware and software it runs on. The best thing to do if you're upgrading from Foundry 10 (or earlier) is to back up all the Foundry stuff from the existing EC2. Once you've got it all, then tear down the previous stack. I don't have experience with copying from one EC2 to another, but setting up a second stack _may_ be possible, before tearing down the first.

You could upgrade it in-place on an older stack, but that's beyond the scope of this project.

It's recommended that you reinstall the _add-ons_ you were using manually one-by-one. Many of the add-ons from Foundry 10 have been updated to Foundry 11, and you'll want to make sure dependencies are all in place. Many add-ons have also changed ownership, and will need to be pointed to a new source address. Finally, some add-ons are not compatible with Foundry 11.

Your worlds should be okay to bring over, and it should prompt you to upgrade them to Foundry's new internal storage format.

### Transferring Worlds and Data

Downloading the `/foundrydata` folder from one EC2 in anticipation of uploading it to another should suffice. If you're using SCP you'll need to do two things:

1. Set permissions back to `foundry`
2. Restart the `foundry` service

In the `/aws-foundry-ssl/utils` folder, you can run:

`sudo sh ./fix_folder_permissions.sh`, and then
`sudo sh ./restart_foundry.sh`

If you get permissions errors, you may also need to run just the `./fix_folder_permissions.sh` script after adding your Foundry license, but _before_ you transfer files. By default Foundry creates more restrictive folder permissions.

### IPv6 Support

This is still a bit experimental as currently this script relies on your default VPC. If you haven't set your VPC to support IPv6, ideally you'll need to manually make the following changes first:

- **VPC**: Add a new IPv6 CIDR (Amazon-provided)
- **Subnets**
  - **CIDR Range**: Edit IPv6 CIDRs for each subnet in the VPC. Each subnet should end in a unique incrementing number starting at 0 for the first, 1 for the second, etc. in any order. For example: `1234:5678:90a:bc00::/64`, `1234:5678:90a:bc01::/64`, `1234:5678:90a:bc02::/64`...
  - **Assign IPv6**: Choose a single subnet, then Edit subnet settings. Turn on `Enable auto-assign IPv6 address`. You likely also want to change `Hostname type` from `IP name` to `Resource name`. Make these changes for each of your subnets in the VPC
- **Route Tables**: Add a new route for `::/0` pointed to your Internet Gateway (same as the `0.0.0.0/0` entry)

If you've already deployed Foundry, edit the EC2 Security Group to add `::/0` for the HTTP, HTTPS, and custom IP ranges in the Inbound rules.

IPv6 _only_ is certainly possible, still figuring that out as AWS will start charging for IPv4 addresses from January 2024.

Right now there's no (easy) way to get the IPv6 address of an EC2 instance in a CloudFormation script (see [this GitHub issue](https://github.com/aws-cloudformation/cloudformation-coverage-roadmap/issues/916) for the complete silence from Amazon). Thus there's no easy way to set the `AAAA` record using CloudFormation. Adding a whole Python lambda _just_ to get an IPv6 address, while impressive in execution, is a tremendous hack and not something I'd like to implement.

If you enable IPv6, you'll also need to add the IPv6 `AAAA` records to your Route 53 zone manually for the time being.

## Debugging Failed CloudFormation

As long as you can get as far as the EC2 being spun up, then:

- If you encounter a creation error, try setting CloudFormation to _preserve_ resources instead of _rollback_ so you can check the troublesome resources
- Disable LetsEncrypt certificate requests (`UseLetsEncryptTLS` set to `False`), until you're happy that it's working to avoid running into the certificate issuance limit
- Add your IP to the Inbound rules of the created Security Group (if you didn't already during the CloudFormation config)
- Grab the EC2's IP from the EC2 web console details
- Open up PuTTy or similar, connect to the IP using the SSH keypair (I'd recommend to only accept the key _once_, rather than accept _always_, as you may end up destroying this instance)
- Check the setup logs
  - `sudo tail -f /tmp/foundry-setup.log` if setup scripts are still running, or
  - `sudo cat /tmp/foundry-setup.log | less` if setup scripts have finished running

Hopefully that gives you some insight in what's going on...

## Notes

### Removed Features

- Removed code for dealing with non-AWS registrars, as I don't have the means or time to support them
  - If you use a non-AWS registrar, you probably know what you're doing and can re-implement or configure it

### Fixes and Features

- Fix: S3 bucket ACL permissions were updated for the stricter [default policy](https://aws.amazon.com/about-aws/whats-new/2022/12/amazon-s3-automatically-enable-block-public-access-disable-access-control-lists-buckets-april-2023/) as of circa April 2023
- Fix: S3 permissions and configuration was changed in Foundry 11
- Fix: New default AMI security seems to necessitate `sudo` in the install script
- Fix: LetsEncrypt TLS certbot didn't work on initial startup
  - Please be aware of the 5-certificates-per-week maximum issuance in case of redeploying multiple times when setting up or if testing things
  - I had to learn a lot about systemd timers, in this case splitting certbot into two timers for the one service
  - Note that certbot _must_ be run after the domain is set up. I've allowed a 30s buffer, but if say CloudFormation takes longer to set up Route53 it may fail
- Fix: Seemed to be a conflict between running the install scripts on the EC2 and CloudFormation setting up the DNS
  - DNS script now tests that the domain is not "empty string", and also makes sure the recordset exists before it tries to upsert it to avoid conflict with CloudFormation
- Fix: Fixed legacy option warning in `certbot`'s CLI call
- Fix: Some AWS Route53 issues where a `.` needed to be on the end of the domain
- Uplift: `yum` calls were changed use `dnf`. `yum` itself [is deprecated](https://github.com/rpm-software-management/yum) in favour of `dnf`.
- Uplift: All legacy `crontab` timers have been migrated to [`systemd` timers](https://wiki.archlinux.org/title/Systemd/Timers)
- Uplift: Node install script [was deprecated](https://github.com/nodesource/distributions); Instead it installs with `dnf`
- Uplift: `amazon-linux-extras` [no longer exists](https://aws.amazon.com/linux/amazon-linux-2023/faqs/); Instead it installs `nginx` with `dnf`
- Uplift: Tidied up some other bits and pieces, added a few extra echoes to help diagnose logging
- Uplift: `t3a` instances are fine, but `t4g` instances are cheaper for very similar workloads so they're now the default
  - I found Foundry would _just_ run on a `.micro` instance, but it'd also run out of memory and cause the EC2 to freak out. This resulted in CPU usage (and hosting costs) to spiral out of control, so I removed that size
  - `m6`-class instances added for people who are made of moneybags, replacing the older `m4` instances
- New: Send certbot's update logs to CloudWatch
- New: Can choose to _not_ request LetsEncrypt TLS if you're trying to get it to deploy and you don't want to run into the certificate issuance limit. See https://letsencrypt.org/docs/duplicate-certificate-limit/
- New: Amazon Linux 2023 kernel auto-updating

### Future Considerations

- Improve CloudWatch logs (?)
- Add script to facilitate transfer between two EC2s?
- Store LetsEncrypt PEM keys in AWS Secrets Manager and retrieve them instead of requesting new ones to work around the issuance limit (is that even possible / supported?)
- Better ownership/permissions defaults?
- Automatically select the `x86_64` or `arm64` image based on instance choice (even possible?)
- Consider using SSH forwarding via SSM or EC2 Instance Connect instead of key pair stuff, would need to look into this
- IPv6 support (AWS will soon start charging for IPv4 address assignments)
