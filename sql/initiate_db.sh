#!/usr/bin/env bash

echo -e '[mysqld]\n'\
'user                   =mysql\n'\
'datadir                =/var/lib/mysql\n'\
'symbolic-links         =1\n'\
'loose-local-infile     =1\n'\
'default-storage-engine =MYISAM\n'\
'[mysqld_safe]\n'\
'log-error              =/var/log/mariadb/mariadb.log\n'\
'pid-file               =/var/run/mariadb/mariadb.pid\n'\
'socket                 =/var/lib/mysql/mysql.sock\n'\
 > /etc/my.cnf


# setup mysql database and root account
mysql_install_db --user=mysql
mysqld_safe --local-infile=1 & sleep 2
mysqladmin -u root password ${SQL_PASSWORD}

# setup minimum browser tables
mysql -uroot -p${SQL_PASSWORD} -e "create database hgFixed"
mysql -uroot -p${SQL_PASSWORD} -e "create database hgcentral"
mysql -uroot -p${SQL_PASSWORD} -e "create database customTrash"
curl -so /var/lib/mysql/hgcentral.sql http://hgdownload.cse.ucsc.edu/admin/hgcentral.sql
mysql -uroot -p${SQL_PASSWORD} hgcentral < /var/lib/mysql/hgcentral.sql
chown -R mysql:mysql /var/lib/mysql
#chmod -R 755 /ucsc/mysql #necessary?

# allow root to do anything from anywhere
mysql -uroot -p${SQL_PASSWORD} -e "GRANT ALL PRIVILEGES on *.* TO root@'172.17.0.%.%' IDENTIFIED BY '"${SQL_PASSWORD}"' WITH GRANT OPTION;" mysql
mysql -uroot -p${SQL_PASSWORD} -e "GRANT SELECT on hgFixed.* TO readonly@'172.17.0.%.%' IDENTIFIED BY 'access';" mysql
#mysql -uroot -p${SQL_PASSWORD} -e "GRANT SELECT on hgFixed.* TO readonly@'localhost' IDENTIFIED BY 'access';" mysql
# allow webserver to modify hgcentral and customTrash
mysql -uroot -p${SQL_PASSWORD} -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER on hgcentral.* TO readwrite@'172.17.0.%.%' IDENTIFIED BY 'update';" mysql
#mysql -uroot -p${SQL_PASSWORD} -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER on hgcentral.* TO readwrite@'localhost' IDENTIFIED BY 'update';" mysql
mysql -uroot -p${SQL_PASSWORD} -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER,INDEX on customTrash.* TO readwrite@'%.172.17.0.%.%' IDENTIFIED by 'update';" mysql
#mysql -uroot -p${SQL_PASSWORD} -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER,INDEX on customTrash.* TO readwrite@'localhost' IDENTIFIED by 'update';" mysql
mysql -uroot -p${SQL_PASSWORD} -e "FLUSH PRIVILEGES;"


# clear from hgcentral: defaultDb, clade, genomeClade, dbDb, dbDbArch, liftOverChain, hubPublic, targetDb
# make sure host info is correct for custom tracks
