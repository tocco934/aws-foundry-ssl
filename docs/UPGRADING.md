# Upgrading from a previous installation

**Foundry 11 is a big update.**

Many plugins need to be updated etc. in addition to the base hardware and software it runs on. The best thing to do if you're upgrading from Foundry 10 (or earlier) is to back up all the Foundry stuff from the existing EC2. Once you've got it all, then tear down the previous stack. I don't have experience with copying from one EC2 to another, but setting up a second stack _may_ be possible, before tearing down the first.

You could upgrade it in-place on an older stack, but that's beyond the scope of this project.

It's recommended that you reinstall the _add-ons_ you were using manually one-by-one. Many of the add-ons from Foundry 10 have been updated to Foundry 11, and you'll want to make sure dependencies are all in place. Many add-ons have also changed ownership, and will need to be pointed to a new source address. Finally, some add-ons are not compatible with Foundry 11.

Your worlds should be okay to bring over, and it should prompt you to upgrade them to Foundry's new internal storage format.

### Transferring Worlds and Data

Downloading the `/foundrydata` folder from your old EC2 in anticipation of uploading it to another should suffice.

If you're using SCP you'll need to do two things after uploading to your new instance:

1. Set permissions back to `foundry`
2. Restart the `foundry` service

In the `/aws-foundry-ssl/utils` folder, you can run:

`sudo sh ./fix_folder_permissions.sh`, and then
`sudo sh ./restart_foundry.sh`

If you get permissions errors, you may also need to run just the `./fix_folder_permissions.sh` script after adding your Foundry license, but _before_ you transfer files. By default Foundry creates more restrictive folder permissions.
