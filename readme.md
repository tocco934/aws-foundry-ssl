# AWS Foundry VTT Deployment with SSL Encryption

_Deploys Foundry VTT with SSL encryption in AWS using CloudFormation_

This is a fork of the [**updated Foundry CF deploy script**](https://github.com/cat-box/aws-foundry-ssl) by Lupert and Cat. I'm trying to bring it up to spec with Amazon Linux 2023 and a few other things. The main impetus is Node 18.x to support Foundry v11.

---

### New Features

Nothing too fancy yet, just playing around.

There are a fair few things broken nowadays in the original. Of note where I'm muddling my way around as I can't claim to be an expert on any of this:

- S3 bucket ACL permissions need to be updated (stricter default policy as of circa April 2023)
- `yum` is deprecated in favour of `dnf`
- Node install script needs to be updated to use `dnf`
- `amazon-linux-extras` no longer exists? Need to install `nginx` probably also via `dnf`
- New default security seems to necessitate `sudo` in a few more places
- I don't know anything about the non-Amazon domain registrars so I'm removing them
- Try to figure out why the SSL CertBot doesn't work on initial startup
- `t3` instances are fine, but `t3a` instances are cheaper for very similar workloads
  - Investigate whether ARM-based `t4g` instances are viables
