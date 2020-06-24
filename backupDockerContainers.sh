#!/bin/bash
#############################################
# This Script writed by Daniel Mandelblat  ##
#############################################
clear

userArg=$1

#Current date format
currentDate=`date +'%d.%m.%y'`

#Docker backup folder
dbf='/dbf'


#Remote information
remoteSahre="//15.17.199.47/dockerBackup"
shareUsername="danielm"
shareDomain="inr"
sharePassword="052707Dd"
localFolder="/tmp/mountBackupScript"

logfile="logs.log"
tempImages="/var/log/backupTempScript.txt"

saveAsImage()
{

    #Export Containers to Images

    docker ps -a --format '{{.ID}} {{.Names}}' | while read line ;\
        do c1=`echo $line | awk '{print $1}'`;\
           c2=`echo $line | awk '{print $2}'`;\
               echo "exporting: $c2 as Image" | tee  -a $dbf/$logfile;\
    docker commit $c1 $c2.$currentDate:backup; done
    print "\n\n"
    return
}



export()
{
    #Export images as Tar file

   docker images |\
        cut -d" " -f 1 |\
        tail -n +2 | \
        while read line ; \
        do  echo "$line" >> $tempImages ;\
        echo "exporting: $line as tar file" | tee -a $dbf/$logfile ; docker save -o $dbf/$line.tar $line ;\
    done
    printf "\n\n"
    return
}


removeAllImages()
{

        if [ -s $tempImages ]; then
docker images  --format "{{.Repository}} {{.ID}}" | while read line ; do v1=`echo $line | awk {'print $1'}` v2=`echo $line | awk '{print $2}'`; for i in `cat $tempImages` ;do if [ "$v1" == "$i" ] ; then docker rmi $v2  ;fi  ; done ;done
        fi
        echo > $tempImages
        printf "\n\n"
        return
}



uploadTarFilesAsImages()

{


    cd $dbf ; ls | while read line ; do echo "Uploading: $line as image" | tee  -a $dbf/$logfile ; docker load -i $dbf/$line ; done
    printf "\n\n"
    return
}



mountShare()
{
    if [ ! -d $localFolder ];then mkdir $localFolder ;fi
    #Check if the share folder allready mounted
    umount $localFolder ||  mount -t cifs $remoteSahre -o username=$shareUsername,domain=$shareDomain,password=$sharePassword $localFolder
    clear
    echo "copy files to $remoteSahre\n======================\n" | tee  -a $dbf/$logfile
    rsync -v $dbf/*  $localFolder | tee  -a $dbf/$logfile
    umount $localFolder
    printf "\n\n"
    return
}

start()
{
    echo "==== remove all old images ===="  | tee  -a $dbf/$logfile ; echo "==================================="
    removeAllImages

    echo "==== Start export containers as images ====" | tee  -a $dbf/$logfile ; echo "==================================="
    saveAsImage

    echo "==== Start Export images as Tar files ====" | tee  -a $dbf/$logfile ; echo "==================================="
    export

    echo "==== Start upload all tar as images ====" | tee  -a $dbf/$logfile ; echo "==================================="
    uploadTarFilesAsImages

    echo "==== Start upload all tar's files into share folder ====" | tee  -a $dbf/$logfile ; echo "==================================="
    mountShare
}




if [ $userArg == "backup" ];then
        start
        exit
fi


if [ $userArg == "upload" ];then
        uploadTarFilesAsImages
        exit
fi

if [ $userArg == "remote" ];then
        mountShare
        exit
fi


#If user not gived any argument
clear

printf "Please use next arguments - backup | upload | remote\n"
