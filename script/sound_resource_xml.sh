#!/bin/sh

mysqladmin -uroot create shachi_tmp
mysql -uroot shachi_tmp < $1
mysql -uroot shachi_tmp -e "DROP TABLE annotator"
mysql -uroot shachi_tmp -e "DELETE FROM resource WHERE id NOT IN (SELECT resource_id FROM resource_metadata WHERE metadata_name = 'type' AND value_id = (SELECT id FROM metadata_value WHERE value_type = 'type' AND value = 'Sound'))"
mysql -uroot shachi_tmp -e "DELETE FROM resource_metadata WHERE resource_id NOT IN (SELECT id FROM resource)"
mysqldump -uroot --databases shachi_tmp --xml | sed -e 's/shachi_tmp/shachi/' | gzip > shachi_tmp.xml.gzip
mysqladmin -uroot -f drop shachi_tmp
