#!/bin/bash

Param1=$1
Param2=$2
Param3=$3

cd `dirname $0`
. config/rundeck.cf
. lib/migrate.sh
. lib/modifyDBurl.sh
. lib/code.sh
. lib/rbuild.sh
. lib/resque.sh
. lib/gitLog.sh
. lib/minAssets.sh
. lib/cache.sh
. lib/database.sh

function RealPath () {
_Path=$1
_Tag=`ls -la $_Path | head -n 1 | cut -b 1`
if [[ $_Tag == "l" ]]; then
    _Path=`ls -la $_Path | awk -F" -> " '{print $2}'`
    RealPath $_Path
else
    echo "$_Path"
fi
unset _Path
unset _Tag
}

function Main {
ProjName=$Param2

if [[ $ProjName == "" ]]; then
    echo ""
    echo "The project name cannot be empty !"
    exit 1
fi

if [[ $INFOType == "File" ]]; then
    ConfigPath="$(cd `dirname $0`;pwd)/config"
    DataPath="$(cd `dirname $0`;pwd)/data"
    while read LINE
    do
        _ChkName=`echo $LINE | grep -v "#" | awk -F"|" '{print $1}' | awk 'gsub(/^ *| *$/,"")'`
        if [[ $_ChkName == $ProjName ]]; then
            ProjPath=`echo $LINE | awk -F"|" '{print $3}' | awk 'gsub(/^ *| *$/,"")'`
            ProjType=`echo $LINE | awk -F"|" '{print $2}' | awk 'gsub(/^ *| *$/,"")'`
            DBType=`echo $LINE | awk -F"|" '{print $4}' | awk 'gsub(/^ *| *$/,"")'`
        fi
    done < $ConfigPath/projinfo
    unset _ChkName
fi

if [[ $ProjPath == "" ]]; then
    echo ""
    echo "Cannot find project named $ProjName !"
    exit 1
fi

case $ProjType in
"production") ;;
"development") ;;
*)
    echo ""
    echo "Project type is wrong !"
    exit 1
esac

if [[ -d $ProjPath/config/$ProjType ]]; then
    cd $ProjPath
    BranchName=`git branch | grep "*" | awk '{print $2}'`
    cd - > /dev/null
    if [[ $BranchName == "" ]]; then
        echo ""
        echo "$ProjPath not find git !"
        exit 1
    fi
    ProjConfPath="$ProjPath/config/$ProjType"
else
    echo ""
    echo "Not find project or project type is wrong !"
    exit 1
fi

ProjRealPath=`RealPath "$ProjPath"`
TimeStamp=`date +%y%m%d%H%M%S`
}

case $Param1 in
"update")
    DBUrl=$Param3
    Main
    EchoGitLog
    modifyDBurl
    PullCode
    BackupDB
    MigrateAll
    Rbuild
    Resque
    ;;
"showGitLog")
    Main
    ShowGitLog
    ;;
"rollback")
    CommitID=$Param3
    Main
    RollbackCode
    RollbackDB
    MigrateAll
    Rbuild
    Resque
    ;;
"rresque")
    Main
    Resque
    ;;
"showMigrate")
    Main
    ShowMigrate
    ;;
"migrate")
    MigrationID=$Param3
    Main
    MigrateOne
    ;;
"closeMinAssets")
    Main
    MinAssets close
    ;;
"openMinAssets")
    Main
    MinAssets open
    ;;
"rbuild")
    Main
    Rbuild -f
    ;;
"rebuild_org_tree")
    Ent=$Param3
    Main
    Cache rebuild_org_tree
    ;;
"rebuild_to_redis")
    Ent=$Param3
    Main
    Cache rebuild_to_redis
    ;;
"backupDB")
    Main
    BackupDB -f
    ;;
esac