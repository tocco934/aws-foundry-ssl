# AWS Foundry VTT Deployment with SSL Encryption

_Deploy Foundry VTT with SSL encryption in AWS using CloudFormation._

This is a fork of the [**Foundry CF deploy script**](https://github.com/cat-box/aws-foundry-ssl) by Lupert and Cat.

**Main New Things**

- Supports Foundry 11
- Amazon Linux 2023 on EC2
- Node 20.x
- Newer more cost efficient / performant instance type support, including ARM64

## Installation

_Note:_ You'll need some technical expertise to get this running. It's not quite click-ops, but it's close.

You can also refer to the original repo's wiki, but the gist is:

### Foundry Download

- Download the `NodeJS` installer for FoundryVTT from Foundry's website, upload it to Google Drive
  - Make the link publicly shared (anyone with the link can view)
  - Make note of the link
  - Foundry `11.309` or newer is recommended due to fixing a major security flaw in the WebP decoder

### AWS Setup

- Create an SSH key in AWS EC2, under `EC2 / Network & Security / Key Pairs`
  - You only need to do this once, _the first time_. If you tear down and redeploy the stack you can reuse the same SSH key
  - That said, consider rotating keys (once every six months?) as a good security practise
  - Keep the downloaded private keypair (PEM or PPK) file safe, you'll need it for SSH / SCP access to the EC2 server instance
- Then go to CloudFormation and choose to Create a Stack with new resources
  - Leave `Template is Ready` selected
  - Choose `Upload a template file`
  - Upload the `/cloudformation/Foundry_Deployment.template` file from this project
  - Fill in and check _all_ the details. I've tried to provide sensible defaults. The ones you should pay _particular_ attention to are:
    - Add the Google Drive link for downloading Foundry
    - Set an admin user password (for IAM)
    - Enter your fully qualified domain eg. `mydomain.com`, do _not_ include any `www` or any other prefix
    - Enter your email address for LetsEncrypt
    - Choose the SSH keypair you set up for the EC2
    - (optional) Add your IP to be allowed incoming access via SSH eg. `123.45.67.89/32`. The `/32` (or other valid range) is required and will scope the range to your IP only. You can manually set this up later in EC2 Security Groups if you need.
    - Choose an S3 bucket name for storing files
      - This must be _globally unique_ and not use `.`
      - If you're unsure, something like `foundry-mydomain-com` if you were going to host Foundry on `foundry.mydomain.com` would be a good recommendation

It should be pretty automated from there. Again, just be careful of the LetsEncrypt deploy (5 certificate requests per week) limits. If need be, set the LetsEncrypt SSL testing option to `False` in the CloudFormation setup if you are debugging a failed stack deploy.

## Upgrading From a Previous Instance

**Foundry 11 is a big update.**

Many plugins need to be updated etc. in addition to the base hardware and software it runs on. The best thing to do if you're upgrading from Foundry 10 (or earlier) is to back up all the Foundry stuff from the existing EC2. Once you've got it all, then tear down the previous stack. I don't have experience with copying from one EC2 to another, but setting up a second stack _may_ be possible, before tearing down the first.

You could upgrade it in-place on an older stack, but that's beyond the scope of this project.

I recommend that you reinstall the _add-ons_ you were using manually one-by-one, as many of the add-ons from Foundry 10 have been updated to Foundry 11, and you'll want to make sure dependencies are all in place. Many add-ons have also changed ownership, and will need to be pointed to a new source address.

Your worlds should be okay to bring over, and it should prompt to upgrade them to Foundry's new internal format.

### Transferring Worlds and Data

Downloading the `/foundrydata` folder from one EC2 in anticipation of uploading it to another should suffice. However, if you are using SCP you'll need to do two things:

1. Set permissions back to `foundry`
2. Restart `foundry`

In the `/aws-foundry-ssl/utils` folder, you can run:

`sudo sh ./fix_folder_permissions.sh`, and then
`sudo sh ./restart_foundry.sh`

You may also need to run just the `fix_folder_permissions` script after adding your Foundry license, _but before_ you transfer files. By default Foundry creates more restrictive folder permissions (this may be fixable by optimistically creating them first with the install script, would need to look into this).

## Debugging Failed CloudFormation

As long as you can get as far as the EC2 being spun up, then:

- If you encounter a creation error, try again but set CloudFormation to _preserve_ resources instead of _rollback_
- Disable LetsEncrypt certificate requests (`UseLetsEncryptSSL` set to `False`), until you're happy that it's working to avoid running into the 5-a-week certificate limit
- Add your IP to the Inbound rules of the created Security Group (if you didn't already during the CloudFormation config)
- Grab the EC2's IP from the EC2 web console details
- Open up PuTTy or similar, connect to the IP using the SSH keypair (I'd recommend to only accept the key _once_, rather than accept _always_, as you may end up destroying and recreating, which means this IP shouldn't be treated as permanent)
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
- Fix: LetsEncrypt SSL certbot didn't work on initial startup
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
- New: Can choose to _not_ request LetsEncrypt SSL if you're trying to get it to deploy and you don't want to run into the certificate exhaustion. See https://letsencrypt.org/docs/duplicate-certificate-limit/
- New: Amazon Linux 2023 kernel auto-updating

### Future Considerations

- Improve CloudWatch logs (?)
- Add upgrade scripts eg. for NodeJS versions
- Add script to facilitate transfer between two EC2s?
- Store LetsEncrypt PEM keys in AWS Secrets Manager and retrieve them instead of requesting new ones to work around the issuance limit (is that even possible / supported?)
- Better ownership/permissions defaults?
- Automatically select the `x86_64` or `arm64` image based on instance choice (even possible?)
