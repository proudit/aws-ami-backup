# AWS EC2(AMI) Backup Script 
AWS EC2 Backup Script.

 Get the AMI backup of the specified instance, 
 and 
 Delete "AMI and Snapshot" that associated with the specified generation before
  
## Installation
  
Copy this Script at worckdir.
Run Script in shell , or Run Script in crontab.
  
## Usage
  
/path/to/ami-backup.sh [InstanceID] [aws-config-profile] 
  
 Default Setting  
 Genaration($Gen) = 1  
 aws-config-profile(none) = default config 
  
## Credits
  
toguma (toguma@proudit.jp)
  
## License
  
MIT: http://rem.mit-license.org

