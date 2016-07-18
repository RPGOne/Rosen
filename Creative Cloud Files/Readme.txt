AWS PV Driver Upgrade
=====================

Version
=======
Current version is 7.3.2


Prerequisites
=============
- .NET Framework 4.5 or later
- Windows Server 2012 or Windows Server 2012 R2


Before You Start
================
- This upgrade automatically reboots the system while updating critical system components. 
  Therefore, we strongly recommend that you back up all critical data before performing the upgrade. 
- If this instance is currently running the Citrix PV Driver, please be aware that all disks except the system disk (usually C:) will be taken offline during the upgrade process. It is recommended to manually take all non-system disks offline before proceeding.

Installation
============
- Run AWSPVDriverSetup.msi as an Administrator to install the latest version and clean up the old version.
- Wait for reboot (~5 minutes, depending on the boot speed of the instance). 
- The instance is unreachable during the upgrade, but will come back online after the upgrade finishes.


Silent Install
==============
- Run AWSPVDriverSetup.msi with the '/quiet' option. For example:
  'AWSPVDriverSetup.msi /quiet'
- Reboots happen automatically. You cannot use the '/norestart' option to stop the reboot.


Verification
============
- Verify driver has been installed by checking device manager and under storage controllers look for AWS PV Storage Host Adapter and check the driver properties and make sure the version is correct.
- If the upgrade fails, review the log file, 'C:\Program Files\Amazon\XenTools\AWSPVDriverMSI.log'.


Known Issues
============
- If you install the upgrade into a new directory, the old driver directories are not deleted.
