#!/bin/sh

Gen=1
InstanceID=$1
Customer=$2
PostfixDate=`date +%Y%m%d%H%M%S`
TagName=`/usr/bin/aws ec2 describe-tags --profile "${Customer}"| grep ${InstanceID} | grep Name | awk '{print $5}'`

resultCreate="success"
resultDelete="success"
ImageName="___created_image_name____"

if [ "$TagName" = "" ]; then
  echo "tag name is empty"
  exit 1
fi

createAmi(){
  echo "[`date '+%Y/%m/%d %H:%M:%S'`] create ami"
  ImageName=`/usr/bin/aws ec2 create-image --instance-id ${InstanceID} --name "${TagName}-${PostfixDate}" --description "${TagName} daily backup ${InstanceID} ${PostfixDate}" --no-reboot --profile "${Customer}"`
  echo "[`date '+%Y/%m/%d %H:%M:%S'`] $ImageName created"
  if [ $? -eq 0 ]; then
    createTagResponce=`/usr/bin/aws ec2 create-tags --resources ${ImageName} --tags "Key=Name,Value=${TagName}-${PostfixDate}" --profile "${Customer}"`
    if [ "$createTagResponce" = "true" ]; then
      echo "[`date '+%Y/%m/%d %H:%M:%S'`] ${TagName}-${PostfixDate} tag created"
    else
      resultCreate="failure"
    fi
  else
    resultCreate="failure"
  fi
}

deleteAmi(){
  deleteImage=$1

  deleteSnapshot=`/usr/bin/aws ec2 describe-images --image-ids $deleteImage --profile "${Customer}" --query "Images[*].BlockDeviceMappings[*].Ebs.SnapshotId"`

  echo "[`date '+%Y/%m/%d %H:%M:%S'`] delete ami $deleteImage"
  tmpResult=1
  if [ "" = "$1" ]; then
    echo "[`date '+%Y/%m/%d %H:%M:%S'`] deleteImage is empty"
  else
    deleteResponce=`/usr/bin/aws ec2 deregister-image --image-id ${deleteImage} --profile "${Customer}"`
    if [ "$deleteResponce" = "true" ]; then
      tmpResult=0
      echo "[`date '+%Y/%m/%d %H:%M:%S'`] ${deleteImage} deleted"

      deleteSnapResponce=`/usr/bin/aws ec2 delete-snapshot --snapshot-id $deleteSnapshot --profile "${Customer}"`
        if [ "$deleteSnapResponce" = "true" ]; then
          tmpResult=0
        echo "[`date '+%Y/%m/%d %H:%M:%S'`] ${deleteSnapshot} deleted"
        fi
    fi
  fi
  if [ $tmpResult -eq 1 ]; then
    resultDelete="failure"
  fi
}

deleteAmis(){
  # for the created image not appear 
  echo -n > /tmp/ami-backup
  /usr/bin/aws ec2 describe-images --filters Name=tag:Name,Values=${TagName}-* --query "Images[*].[Name,ImageId]" --profile "${Customer}" > /tmp/ami-backup  
  if [ "$resultCreate" = "success" -a `cat /tmp/ami-backup | grep $ImageName | wc -l` -eq 0 ]; then
    echo "${TagName}-${PostfixDate}  $ImageName" >> /tmp/ami-backup
  fi


  listAmi=`cat /tmp/ami-backup | sort -r | sed -e "1,${Gen}d" | awk '{print $2}'`
  for ami in ${listAmi}
  do
    deleteAmi $ami
  done
}

createAmi
deleteAmis

if [ "$resultCreate" = "success" -a "$resultDelete" = "success" ]; then
  echo "[`date '+%Y/%m/%d %H:%M:%S'`] ami backup success"
else
  echo "[`date '+%Y/%m/%d %H:%M:%S'`] ami backup failure"
fi
