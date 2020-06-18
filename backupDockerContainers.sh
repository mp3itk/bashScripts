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
remoteSahre="Remote share: example - //xx.xx.xx.xx/shareFolder"
shareUsername="username"
shareDomain="domain"
sharePassword="password"
localFolder="temp folder which contain exported files"

logfile="logs.log"

saveAsImage()
{

    #Export Containers to Images
    clear
    docker ps -a --format '{{.ID}} {{.Names}}' | while read line ;\
        do c1=`echo $line | awk '{print $1}'`;\
           c2=`echo $line | awk '{print $2}'`;\
               echo "exporting: $c2 as Image" | tee  -a $dbf/$logfile;\
    docker commit $c1 $c2.$currentDate:backup; done
    return
}



export()
{
    #Export images as Tar file
   clear

   docker images |\
        cut -d" " -f 1 |\
        tail -n +2 | \
        while read line ; \
        do echo "exporting: $line as tar file" | tee -a $dbf/$logfile ; docker save -o $dbf/$line.tar $line ;\
    done
    return
}


removeAllImages()
{
    clear
    docker images | awk '{print $3}' | while read line ; do echo "removing old image $line" | tee -a $dbf/$logfile;  docker rmi $line ; done
    return
}



uploadTarFilesAsImages()

{
    clear

    cd $dbf ; ls | while read line ; do echo "Uploading: $line as image" | tee  -a $dbf/$logfile ; docker load -i $dbf/$line ; done
    return
}



mountShare()
{
    #Check if the share folder allready mounted
    umount $localFolder ||  mount -t cifs $remoteSahre -o username=$shareUsername,domain=$shareDomain,password=$sharePassword $localFolder
    clear
    echo "copy files to $remoteSahre\n======================\n" | tee  -a $dbf/$logfile
    rsync -v $dbf/*  $localFolder | tee  -a $dbf/$logfile
    umount $localFolder
    return
}

start()
{
    echo "==== remove all old images ===="  | tee  -a $dbf/$logfile ; echo "===================================\n\n"
    removeAllImages

    echo "==== Start export containers as images ====" | tee  -a $dbf/$logfile ; echo "===================================\n\n"
    saveAsImage

    echo "==== Start Export images as Tar files ====" | tee  -a $dbf/$logfile ; echo "===================================\n\n"
    export

    echo "==== Start upload all tar as images ====" | tee  -a $dbf/$logfile ; echo "===================================\n\n"
    uploadTarFilesAsImages
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
