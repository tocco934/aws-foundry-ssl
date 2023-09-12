#!/bin/bash

# grab variables
source /foundryssl/variables_temp.sh
source /foundryssl/variables.sh

# download foundry from patreon link or google drive
cd /home/foundry/foundry-install


if [[ `echo ${foundry_download_link}  | cut -d '/' -f3` == 'drive.google.com' ]]; then
    fileid=`echo ${foundry_download_link} | cut -d '/' -f6`
    while (( FS_Retry < 4 )) ; do
        sudo wget --quiet --save-cookies cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=${fileid}" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p' > confirm.txt
        sudo wget --load-cookies cookies.txt -O foundry.zip 'https://docs.google.com/uc?export=download&id='${fileid}'&confirm='$(<confirm.txt) && rm -rf cookies.txt confirm.txt
        filesize=$(stat -c%s "./foundry.zip")
        echo "Size of foundry.zip = $filesize bytes."
        if (( filesize > 100000000 )); then
            echo "Filesize seems about right! Proceeding."
            break
        else
            echo "Filesize looking too small. Retrying."
            ((FS_Retry++))
        fi
    done
else
    sudo wget -O foundry.zip "${foundry_download_link}"
fi

unzip -u foundry.zip
rm -f foundry.zip

# allow rwx in the Data folder only for ec2-user
chown -R foundry:foundry /home/foundry/ /foundrydata
find /foundrydata -type d -exec chmod 765 {} +
find /foundrydata -type f -exec chmod 664 {} +

# start foundry and add to boot
sudo cp /aws-foundry-ssl/files/foundry/foundry.service /etc/systemd/system/foundry.service
sudo chmod 644 /etc/systemd/system/foundry.service
sudo systemctl daemon-reload
sudo systemctl start foundry
sudo systemctl enable foundry


# configure foundry aws json file
F_DIR='/foundrydata/Config/'
echo "Start time: $(date +%s)"
while (( Edit_Retry < 45 )) ; do
    if [ -d $F_DIR ]; then
        echo "Directory found time: $(date +%s)"
        sudo cp /aws-foundry-ssl/files/foundry/options.json /foundrydata/Config/options.json
        sudo cp /aws-foundry-ssl/files/foundry/AWS.json /foundrydata/Config/AWS.json
        sudo sed -i "s|ACCESSKEYIDHERE|${access_key_id}|g" /foundrydata/Config/AWS.json
        sudo sed -i "s|SECRETACCESSKEYHERE|${secret_access_key}|g" /foundrydata/Config/AWS.json
        sudo sed -i "s|REGIONHERE|${region}|g" /foundrydata/Config/AWS.json
        sudo sed -i 's|"awsConfig":.*|"awsConfig": "/foundrydata/Config/AWS.json",|g' /foundrydata/Config/options.json
        break
    else
        echo  echo "Directory not found time: $(date +%s)"
        ((Edit_Retry++))
        sleep 1s
    fi
done