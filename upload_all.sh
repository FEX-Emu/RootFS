#!/bin/sh
b2 upload-file fex-rootfs /mnt/Work/Projects/work/FEX-rootfs/RootFS_Ubuntu_20_04/Ubuntu_20_04.sqsh Ubuntu_20_04/`date +%Y-%m-%d`/Ubuntu_20_04.sqsh
b2 upload-file fex-rootfs /mnt/Work/Projects/work/FEX-rootfs/RootFS_Ubuntu_20_04/Ubuntu_20_04.ero Ubuntu_20_04/`date +%Y-%m-%d`/Ubuntu_20_04.ero

b2 upload-file fex-rootfs /mnt/Work/Projects/work/FEX-rootfs/RootFS_Ubuntu_22_04/Ubuntu_22_04.sqsh Ubuntu_22_04/`date +%Y-%m-%d`/Ubuntu_22_04.sqsh
b2 upload-file fex-rootfs /mnt/Work/Projects/work/FEX-rootfs/RootFS_Ubuntu_22_04/Ubuntu_22_04.ero Ubuntu_22_04/`date +%Y-%m-%d`/Ubuntu_22_04.ero

b2 upload-file fex-rootfs /mnt/Work/Projects/work/FEX-rootfs/RootFS_Ubuntu_22_10/Ubuntu_22_10.sqsh Ubuntu_22_10/`date +%Y-%m-%d`/Ubuntu_22_10.sqsh
b2 upload-file fex-rootfs /mnt/Work/Projects/work/FEX-rootfs/RootFS_Ubuntu_22_10/Ubuntu_22_10.ero Ubuntu_22_10/`date +%Y-%m-%d`/Ubuntu_22_10.ero

FEXRootFSFetcher /mnt/Work/Projects/work/FEX-rootfs/RootFS_Ubuntu_20_04/Ubuntu_20_04.sqsh
FEXRootFSFetcher /mnt/Work/Projects/work/FEX-rootfs/RootFS_Ubuntu_20_04/Ubuntu_20_04.ero

FEXRootFSFetcher /mnt/Work/Projects/work/FEX-rootfs/RootFS_Ubuntu_22_04/Ubuntu_22_04.sqsh
FEXRootFSFetcher /mnt/Work/Projects/work/FEX-rootfs/RootFS_Ubuntu_22_04/Ubuntu_22_04.ero

FEXRootFSFetcher /mnt/Work/Projects/work/FEX-rootfs/RootFS_Ubuntu_22_10/Ubuntu_22_10.sqsh
FEXRootFSFetcher /mnt/Work/Projects/work/FEX-rootfs/RootFS_Ubuntu_22_10/Ubuntu_22_10.ero

