function RunBackup {
Param1=$1
echo ""
echo "Backuping database ..."
while read LINE
do
    local _Key=`echo $LINE | grep "=>" | awk -F"=>" '{print $1}' | awk 'gsub(/^ *| *$/,"")' | sed "s/'//g"`
    case $_Key in
    "host")
        local _Host=`echo $LINE | awk -F"=>" '{print $2}' | awk 'gsub(/^ *| *$/,"")' | sed "s/'//g" | sed "s/,$//"`
        ;;
    "port")
        local _Port=`echo $LINE | awk -F"=>" '{print $2}' | awk 'gsub(/^ *| *$/,"")' | sed "s/'//g" | sed "s/,$//"`
        ;;
    "dbname")
        local _DBName=`echo $LINE | awk -F"=>" '{print $2}' | awk 'gsub(/^ *| *$/,"")' | sed "s/'//g" | sed "s/,$//"`
        ;;
    "user")
        local _DBUser=`echo $LINE | awk -F"=>" '{print $2}' | awk 'gsub(/^ *| *$/,"")' | sed "s/'//g" | sed "s/,$//"`
        ;;
    "password")
        local _DBPasswd=`echo $LINE | awk -F"=>" '{print $2}' | awk 'gsub(/^ *| *$/,"")' | sed "s/'//g" | sed "s/,$//"`
	break;
        ;;
    esac
done < $ProjConfPath/database.php

if [ "$Param1" == "toftp" ];then
      ping -c 1 192.168.0.201 |grep '0% packet loss' > /dev/null 2>&1

     if [ $? -eq 0 ];then
                cat /etc/hosts|grep www.download.aysaas.com > /dev/null 2>&1
                 if [ ! $? -eq 0 ];then
                        sudo bash -c "echo '192.168.0.201 www.download.aysaas.com' >> /etc/hosts"
                 fi
     fi
   SiteType=`echo $AccessAddr|awk -F '.' '{print $2}'`  
   [[ $SiteType != demo && $SiteType != proj && $SiteType != test ]] && SiteType=proj
   mysqldump -h"$_Host" -u"$_DBUser" -p"$_DBPasswd" $_DBName > /tmp/${_DBName}_$TimeStamp.sql
   cd /tmp 
   tar -zcpf ${_DBName}_$TimeStamp.sql.tar.gz ${_DBName}_$TimeStamp.sql
   rm ${_DBName}_$TimeStamp.sql
   ftp -v -n $BACKUP_FTP_HOST $BACKUP_FTP_PORT << EOF
user $BACKUP_FTP_USER $BACKUP_FTP_PASS
type binary
cd mysql
rmdir $SiteType
mkdir $SiteType
cd  $SiteType
put ${_DBName}_$TimeStamp.sql.tar.gz
bye
EOF
  rm ${_DBName}_$TimeStamp.sql.tar.gz
  cd -
  echo "${_DBName} has been backup to ftp server" 
  echo "Download  url is  http://www.download.aysaas.com:3300/databases/mysql/$SiteType/${_DBName}_$TimeStamp.sql.tar.gz"
  exit 0
fi

if [[ $TimeStamp == "" ]]; then
    mysqldump -h"$_Host" -u"$_DBUser" -p"$_DBPasswd" $_DBName > $BackupDir${_DBName}_`date +%y%m%d%H%M%S`.sql
    local _Status=$?
else
    mysqldump -h"$_Host" -u"$_DBUser" -p"$_DBPasswd" $_DBName > $BackupDir/${_DBName}_$TimeStamp.sql
    local _Status=$?
fi
 
if [[ $_Status == 1 ]]; then
    echo ""
    echo "It looks like something wrong when backup database !"
    exit 1
else
    echo ""
    echo "Backup database is OK !"
fi

}

function RunRollback () {
local _CommitID=$1

echo ""
echo "Rollbacking database ..."
while read LINE
do
    local _Key=`echo $LINE | grep "=>" | awk -F"=>" '{print $1}' | awk 'gsub(/^ *| *$/,"")' | sed "s/'//g"`
    case $_Key in
    "host")
        local _Host=`echo $LINE | awk -F"=>" '{print $2}' | awk 'gsub(/^ *| *$/,"")' | sed "s/'//g" | sed "s/,$//"`
        ;;
    "port")
        local _Port=`echo $LINE | awk -F"=>" '{print $2}' | awk 'gsub(/^ *| *$/,"")' | sed "s/'//g" | sed "s/,$//"`
        ;;
    "dbname")
        local _DBName=`echo $LINE | awk -F"=>" '{print $2}' | awk 'gsub(/^ *| *$/,"")' | sed "s/'//g" | sed "s/,$//"`
        ;;
    "user")
        local _DBUser=`echo $LINE | awk -F"=>" '{print $2}' | awk 'gsub(/^ *| *$/,"")' | sed "s/'//g" | sed "s/,$//"`
        ;;
    "password")
        local _DBPasswd=`echo $LINE | awk -F"=>" '{print $2}' | awk 'gsub(/^ *| *$/,"")' | sed "s/'//g" | sed "s/,$//"`
        break;
	;;
    esac
done < $ProjConfPath/database.php

local TimeStamp=`cat $DataPath/pullog | grep $_CommitID | tail -n 1 | awk -F"|" '{print $2}'`
if [[ -f ${_DBName}_$TimeStamp.sql ]]; then
    echo ""
    echo "Dropping database $_DBName ..."
    mysql -h"$_Host" -u"$_DBUser" -p"$_DBPasswd" -e "drop database $_DBName"
    if [[ $? == 0 ]]; then
        echo ""
        echo "Dropping database $_DBName is OK !"
        echo ""
        echo "Creating database $_DBName ..."
        mysql -h"$_Host" -u"$_DBUser" -p"$_DBPasswd" -e "create database $_DBName"
        if [[ $? == 0 ]]; then
            echo ""
            echo "Create database $_DBName is OK !"
            echo ""
            echo "Importing ${_DBName}_$TimeStamp.sql ..."
            mysql -h"$_Host" -u"$_DBUser" -p"$_DBPasswd" $_DBName < ${_DBName}_$TimeStamp.sql
            if [[ $? == 0 ]]; then
                echo ""
                echo "Import ${_DBName}_$TimeStamp.sql is OK !"
                echo ""
                echo "Rollback database is OK !"
            else
                echo ""
                echo "Import ${_DBName}_$TimeStamp.sql is Fail !"
                echo ""
                echo "Rollback database is Fail !"
            fi
        else
            echo ""
            echo "Create database $_DBName is Fail !"
            echo ""
            echo "Rollback database is Fail !"
        fi
    else
        echo ""
        echo "Dropping database $_DBName is Fail !"
        echo ""
        echo "Rollback database is Fail !"
    fi
else
    echo ""
    echo "Not find ${_DBName}_$TimeStamp.sql !"
    echo ""
    echo "Rollback database is Fail !"
fi
}

function BackupDB {
cd $ProjPath
if [[ $1 == "-f" ]]; then
    RunBackup
fi
local NeedMigrate=`git diff $CommitID | grep "diff --git a/db/migrations/"`
if [[ $NeedMigrate != "" && $DBType == "base" ]]; then
    RunBackup
fi
cd - 1>/dev/null 2>&1
}

function RollbackDB () {
local _CommitID=$1

cd $ProjPath
local NeedMigrate=`git diff $_CommitID | grep "diff --git a/db/migrations/"`
if [[ $NeedMigrate != "" && $DBType == "base" ]]; then
    RunRollback "$_CommitID"
fi
cd - 1>/dev/null 2>&1
}
