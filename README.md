# AWS Foundry VTT Deployment with SSL Encryption

_Deploy Foundry VTT with SSL encryption in AWS using CloudFormation._

This is a fork of the [**Foundry CF deploy script**](https://github.com/cat-box/aws-foundry-ssl) by Lupert and Cat.

This version brings it up to date with some newer functionality and supports Foundry 11.

It's working, but still considered experimental.

### Removed Features

- Removed code for dealing with non-AWS registrars, as I don't have the means or time to support them
  - If you use a non-AWS registrar, you probably know what you're doing and can re-implement or configure it

### Fixes and Features

- Fix: S3 bucket ACL permissions were updated for the stricter [default policy](https://aws.amazon.com/about-aws/whats-new/2022/12/amazon-s3-automatically-enable-block-public-access-disable-access-control-lists-buckets-april-2023/) as of circa April 2023
- Fix: New default AMI security seems to necessitate `sudo` in a few more places
- Fix The SSL CertBot didn't work on initial startup (but please be aware of the 5-per-week issuance in case of redeploying multiple times)
- Fix: Seemed to be a conflict between running the install scripts on the EC2 and CloudFormation setting up the DNS
  - Timer script now tests that the domain is not "empty string", and also makes sure the recordset exists before it tries to upsert it
- Fix: Fixed legacy option warning in `certbot`'s CLI call
- Fix: Some AWS Route53 issues where a `.` needed to be on the end of the domain
- Uplift: `yum` calls were changed use `dnf`. `yum` itself [is deprecated](https://github.com/rpm-software-management/yum) in favour of `dnf`.
- Uplift: All legacy `crontab` timers have been migrated to [`systemd` timers](https://wiki.archlinux.org/title/Systemd/Timers)
- Uplift: Node install script [was deprecated](https://github.com/nodesource/distributions) and so now it installs with `dnf`
- Uplift: `amazon-linux-extras` no longer exists; Instead install `nginx` via `dnf`
- Uplift: Tidied up some other bits and pieces, added a few extra echoes to help diagnose logging
- Uplift: `t3` instances are fine, but `t3a` instances are cheaper for very similar workloads so they're now the default
  - I found Foundry would run on a `.micro` instance, but it would also easily go OOM and cause the EC2 to freak out. This would cause CPU usage (and your hosting costs) to spiral out of control so they're no longer an option
  - I've also added ARM-based `t4g` instances as an option, which is cheaper (ever so slightly) than the `t3` and `t3a` equivalents
  - `m6`-class instances added for people who are made of moneybags, replacing the older `m4` instances
- New: Send certbot's update logs to CloudWatch
- New: Can choose to stop LetsEncrypt running if you're trying to get it to deploy and you don't want to run into the certificate exhaustion. See https://letsencrypt.org/docs/duplicate-certificate-limit/

### Future Considerations

- The `ec2-user` and `foundry` users permissions easily conflict with each other eg. if you use SCP to upload things to `/foundrydata`
  - Add script to fix `/foundrydata` permissions?
- Is AWS LightSail even a possibility?
- Improve CloudWatch logs (?)
- Add upgrade scripts eg. for when NodeJS 20.x becomes the default
- Add script to facilitate transfer between two EC2s?
- Store LetsEncrypt PEM keys in AWS Secrets Manager and retrieve them instead of requesting new ones to work around the issuance limit (is that even possible / supported?)
- Investigate FoundryVTT not wanting to save preferences (???)
- Better ownership/permissions?

## Upgrading From a Previous Instance

Foundry 11 is a big update.

Many plugins need to be updated etc. in addition to the base hardware and software it runs on. The best thing to do if you're upgrading from Foundry 10 (or earlier) is to back up all the Foundry stuff from the existing EC2. Once you've got it all, then tear down the previous stack. I don't have experience with copying from one EC2 to another, but setting up a second stack _may_ be possible, before tearing down the first.

You could upgrade it in-place on an older stack, but that's beyond the scope of this update.

I recommend that you reinstall the _add-ons_ you were using manually one-by-one, as many of the add-ons from Foundry 10 have been updated to Foundry 11, and you'll want to make sure dependencies are all in place. Your worlds should be okay to bring over, and it should upgrade them to Foundry's new internal format.

If you use SCP to transfer things into `/foundrydata`, make sure you set the correct permissions and user ownership after transfer.

## Installation

_Note:_ You'll need some technical expertise to get this running. It's not necessarily click-ops, but it's close.

Full instructions TBC. You can also refer to the original repo's wiki, but the gist is:

- Download the NodeJS install of FoundryVTT from Foundry's website, upload it to Google Drive
  - Make the link publicly shared
  - Make note of the link
- Set up an SSH key in AWS EC2, under Key Pairs (you only ever need to do this _once_, you can reuse it again if needed. Consider rotating keys for better security)
  - Keep the downloaded private keypair file safe, you'll need it for SCP / PuTTy / SSH access
- Then upload the CloudFormation script from the `/cloudformation/` folder to AWS, and fill in _all_ the details. Pay particular attention to:
  - Add the Google Drive link for downloading Foundry
  - Choose the SSH keypair you set up

It should be pretty automated from there. Again, just be careful of the LetsEncrypt deploy limits. If need be, set the LetsEncrypt testing option to `False` if you are deploying rapidly.

### Debugging

If you can get as far as the EC2 being spun up, then:

- If you encounter a creation error, try again but set CloudFormation to _keep_ resources instead of _rollback_
- Disable LetsEncrypt / SSL certificate requests in the CF setup, until you're happy that it's working (to avoid running into the limit)
- Add your IP to the Inbound rules of the created Security Group (if you didn't already during the CloudFormation config)
- Grab the EC2's IP
- Open up PuTTy or similar, connect to the IP with the SSH keypair from earlier (accept once, as you may end up destroying and recreating, which means this IP shouldn't be treated as permanent)
- `sudo tail -f /tmp/foundry-setup.log`

Hopefully that gives you some insight in what's going on...
