MYSQLSERVER=$(az mysql flexible-server list --query [*].fullyQualifiedDomainName --output tsv)
MYSQLUSER=$(az mysql flexible-server list --query [*].administratorLogin --output tsv)
read -p "Insert the database name:" DBname
read -p "Insert the MySQL password:" MYSQLPASS 
mysql --host=$MYSQLSERVER \
      --user=$MYSQLUSER --password=$MYSQLPASS \
      -e 'use '${DBname}'; SET FOREIGN_KEY_CHECKS = 0; TRUNCATE posts; SET FOREIGN_KEY_CHECKS = 1;' mysql
