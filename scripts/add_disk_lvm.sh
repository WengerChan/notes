#! /usr/bin/env bash

# Add disk to LVM VG, and expand LV

function getLvmInfo(){
    if [ -z "$1" ]; then
        echo "ERROR! The variable 'directoryName' is undefined !"
        exit 1
    fi

    if [ -d "$1" ]; then
        echo "Directory '$1' exists. Continues..."
    else
        echo "ERROR! CANNOT find the directory '$1' !"
        exit 1
    fi

    df -hT | grep "$1$" &> /dev/null

    if [ $? -eq 0 ]; then
        # fs
        filesystemType=$(df -hT | grep "$1" | awk -F' ' '{print $2}')
        # lv, vg
        lv_PATH=$(lsblk -l | grep "$1" | awk -F' ' '{print $1}' | head -n 1)
        read lvName vgName < <(lvdisplay -c "/dev/mapper/$lv_PATH" | sed 's/^ *//g'| awk -F':' '{print $1,$2}')
    else
        echo "ERROR! CANNOT find \'$1\' in 'df -hT'!"
        exit 1
    fi
}


function lvmExpand(){
    # Usage: lvm_Expand "$diskName" "$vgName" "$lvName" "$filesystemType"

    pvs | grep "$1" &> /dev/null
    if [ $? -eq 0 ]; then
        echo "ERROR! Physical volume '$1' is existed !"
        exit 1
    fi

    pvcreate "$1" && vgextend "$2" "$1" && lvextend -l +100%FREE "$3"

    # expand filesystem
    case $4 in
        'ext4'|'ext3'|'ext2') 
            resize2fs "$3" ;;
        'xfs') 
            xfs_growfs "$3" ;;
        *)
            echo "UNKONWN filesystem"
            return 1 ;;
    esac

    if [ $? -eq 0 ]; then
        echo "Success !"
    else
        echo "Expand filesystem failed ! "
        exit 1
    fi
}


function main(){

    # 1. 获取新增磁盘名
    diskName=$(ls -lvrt /dev/disk/by-path | tail -n 1 | awk -F'/' '{print "/dev/"$NF}')

    # 2. 待扩容目录
    directoryName="$1"

    # 3. 待扩容目录对应 vg,lv,fs
    getLvmInfo "$directoryName"

    # 4. 执行扩容
    # 变量取值示例：
    #    diskName='/dev/sdc', '/dev/vdb', etc.
    #    vgName='vg_data'
    #    lvName='/dev/mapper/vg_data-lv_data' or '/dev/vg_data/lv_data'
    #    filesystemType='xfs', 'ext4', etc.
    
    if [ -z "$diskName" -o -z "$vgName" -o -z "$lvName" -o -z "$filesystemType" ]; then
        echo "Find at least one variable is NULL !"
        exit 1
    else
        lvmExpand "$diskName" "$vgName" "$lvName" "$filesystemType"
    fi
}


main "$1"