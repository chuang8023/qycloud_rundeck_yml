#!/bin/bash
BackUpDate=`date +%Y-%m-%d-%H-%M`
BackUpDir=/home/anyuankeji/databases/mongo_backup
MongoUser="qycloud"
MongoPass="4gFKawwtUBd93QmJ"
MongoHost="dds-bp1beb87fe210e942.mongodb.rds.aliyuncs.com"
MongoPort="3717"
MongoDbname="qycloud"
mongodump -u$MongoUser -p=$MongoPass -h$MongoHost:$MongoPort --excludeCollection system.profile  -d$MongoDbname -o $BackUpDir/$BackUpDate
echo "$BackUpDate qycloud mongo backup ok !" >> /tmp/qyloud_mongo-bak.log
find $BackUpDir/* -type d -mtime +7 -exec rm -rf {} \;