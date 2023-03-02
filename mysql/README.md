**Развернем 3 ВМ для кластера PXC в yandex cloud с помощью веб-интерфейса**
И продолжим установку и настройку mysql в ручном режиме, чтобы отследить все возникающие ошибки и трудности.
**подготовим репозиторий**
[https://www.percona.com/doc/percona-repo-config/percona-release.html#deb-based-gnu-linux-distributions](https://www.percona.com/doc/percona-repo-config/percona-release.html#deb-based-gnu-linux-distributions)

**на pxc1**
```
ssh pxc@51.250.14.124
```
```
sudo apt update && sudo apt install -y wget gnupg2 lsb-release
wget https://repo.percona.com/apt/percona-release_latest.generic_all.deb
sudo dpkg -i percona-release_latest.generic_all.deb
```
**установим кластер**
https://www.percona.com/doc/percona-xtradb-cluster/8.0/install/apt.html#apt
```
sudo percona-release enable-only pxc-80 release
sudo percona-release enable tools release
sudo apt update
sudo apt install percona-xtradb-cluster -y
-- пароль Otus321$ --- 
```
**Повторим на остальных серверах** 
ssh pxc@51.250.74.213 - pxc2 и 
ssh pxc@51.250.93.154 - pxc3
```
sudo apt update && sudo apt install -y wget gnupg2 lsb-release && wget https://repo.percona.com/apt/percona-release_latest.generic_all.deb && sudo dpkg -i percona-release_latest.generic_all.deb && sudo percona-release enable-only pxc-80 release && sudo percona-release enable tools release && sudo apt update && sudo apt install percona-xtradb-cluster -y 
```
**Cконфигурируем кластер**
-- https://www.percona.com/doc/percona-xtradb-cluster/8.0/configure.html#configure
Первым шагом необходимо на каждой ноде остановить mysql
```
sudo service mysql stop
```
В конфигурации 
```
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```
зададим ip !!! внутренней сети !!! и имя ноды
```
wsrep_cluster_address=gcomm://10.129.0.30,10.129.0.28,10.129.0.34

wsrep_node_name=pxc1
```
Бутстрапим 1 ноду
---https://www.percona.com/doc/percona-xtradb-cluster/8.0/bootstrap.html#bootstrap
```
sudo systemctl start mysql@bootstrap.service
````
Оставим возможность доступа к базе данных из под root.
```
sudo su
cd $HOME
nano .my.cnf
[client]
password="Otus321$"
```
Подключаемся локально к mysql и выводим:
```
mysql
> show status like 'wsrep%';
```
....
| wsrep_cluster_state_uuid         | fdfa1d6b-b5f9-11ed-8ec1-2ee8bd42f1e6                                                                                                           |
| wsrep_cluster_status             | Primary                                                                                                                                        |
| wsrep_connected                  | ON                                                                                                                                             |
| wsrep_local_bf_aborts            | 0                                                                                                                                              |
| wsrep_local_index                | 0                                                                                                                                              |
| wsrep_provider_capabilities      | :MULTI_MASTER:CERTIFICATION:PARALLEL_APPLYING:TRX_REPLAY:ISOLATION:PAUSE:CAUSAL_READS:INCREMENTAL_WRITESET:UNORDERED:PREORDERED:STREAMING:NBO: |
| wsrep_provider_name              | Galera                                                                                                                                         |
| wsrep_provider_vendor            | Codership Oy <info@codership.com> (modified by Percona <https://percona.com/>)                                                                 |
| wsrep_provider_version           | 4.12(e167906)                                                                                                                                  |
| wsrep_ready                      | ON                                                                                                                                             |
| wsrep_thread_count               | 9                                                                                                                                              |
+----------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------+
79 rows in set (0.02 sec)

**Добавим другие ноды**
-- https://www.percona.com/doc/percona-xtradb-cluster/8.0/add-node.html#add-node
На pxc2 проверим что сервис mysql остановлен
```
sudo service mysql stop
```

И внесём изменения в конфигурацию:
```
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```
```
wsrep_cluster_name=pxc-cluster
wsrep_cluster_address=gcomm://10.129.0.30,10.129.0.28,10.129.0.34
wsrep_node_name=pxc2
```
**Такие же действия повторим на  pxc3**
```
sudo service mysql stop
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```
```
wsrep_cluster_address=gcomm://10.129.0.30,10.129.0.28,10.129.0.34
wsrep_node_name=pxc3
```
Стартуем сервис mysql и проверям вывод в mysql
```
sudo systemctl start mysql
> show status like 'wsrep%';
```

Получаем ошибку:
```
sudo cat /var/log/mysql/error.log
2021-03-02T13:07:53.671538Z 0 [ERROR] [MY-000000] [Galera] handshake with remote endpoint ssl://10.128.15.227:4567 failed: asio.ssl:67567754: 'invalid padding' ( 67567754: 'error:0407008A:rsa routines:RSA_padding_check_PKCS1_type_1:invalid padding')
This error is often caused by SSL issues. For more information, please see:
--  https://per.co.na/pxc/encrypt_cluster_traffic
```
Не будем решать проблему путём отключения шифрования.
```
pxc_encrypt_cluster_traffic=OFF
```
Для решения проблемы выполним на pxc2 и pxc3:
```
sudo su
rm /var/lib/mysql/server-key.pem && rm /var/lib/mysql/ca.pem && rm /var/lib/mysql/server-cert.pem
```
На pxc1 волним копирование на pxc2 и pxc3:
```
scp /var/lib/mysql/server-key.pem pxc@51.250.74.213:/var/lib/mysql/server-key.pem
scp /var/lib/mysql/ca.pem  pxc@51.250.74.213:/var/lib/mysql/ca.pem
scp /var/lib/mysql/server-cert.pem  pxc@51.250.74.213:/var/lib/mysql/server-cert.pem
```
На pxc2 и pxc3 выполним:
```
chown mysql:mysql /var/lib/mysql/server-key.pem && chown mysql:mysql /var/lib/mysql/ca.pem && chown mysql:mysql /var/lib/mysql/server-cert.pem
```
И запустим mysql:
```
systemctl start mysql

> show status like 'wsrep%';
```
| wsrep_cluster_conf_id            | 3                                                                                                                                              |
| wsrep_cluster_size               | 3                                                                                                                                              |
| wsrep_cluster_state_uuid         | fdfa1d6b-b5f9-11ed-8ec1-2ee8bd42f1e6                                                                                                           |
| wsrep_cluster_status             | Primary                                                                                                                                        |
| wsrep_connected                  | ON                                                                                                                                             |
| wsrep_local_bf_aborts            | 0                                                                                                                                              |
| wsrep_local_index                | 2                                                                                   
| wsrep_provider_vendor            | Codership Oy <info@codership.com> (modified by Percona <https://percona.com/>)                                                                 |
| wsrep_provider_version           | 4.12(e167906)                                                                                                                                  |
| wsrep_ready                      | ON                                                                                                                                             |
| wsrep_thread_count               | 9                                                                                                                                              |
+----------------------------------+------------------------------------------------------------------------------------------------------------------------------------------------+
79 rows in set (0.00 sec)

**Также можно применить еще 2 варианта - общую папку для ключей**
https://www.percona.com/blog/2020/05/18/percona-xtradb-cluster-8-0-behavior-change-for-pxc-encrypt-cluster-traffic/

**Проверим, что все работает**
https://www.percona.com/doc/percona-xtradb-cluster/8.0/verify.html#verify
```
create database otus;
use otus;
create table t (i int);
-- having an error
insert into t values (10), (20); 
```
_почему ошибка?_
```
CREATE TABLE accounts (id SERIAL,balance DECIMAL);
insert into accounts(balance) values ('10.0'), ('20.0'); 
```
Обратим внимание на id
```
select * from accounts; 
```
**На pxc2 pxc3**
```
mysql -p
use otus;
select * from accounts;
insert into accounts(balance) values ('10.0'), ('20.0'); 
select * from accounts;
```
** Действия, если упали все ноды**
2020-08-25T13:30:40.725502Z 0 [Note] [MY-000000] [WSREP] Starting replication
2020-08-25T13:30:40.725565Z 0 [Note] [MY-000000] [Galera] Connecting with bootstrap option: 1
2020-08-25T13:30:40.725640Z 0 [Note] [MY-000000] [Galera] Setting GCS initial position to a5066e8e-e5e5-11ea-942d-8a1ba08de78c:10
2020-08-25T13:30:40.725765Z 0 [ERROR] [MY-000000] [Galera] It may not be safe to bootstrap the cluster
from this node. 
!!! It was not the last one to leave the cluster !!!
and may not contain all the updates. 
To force cluster bootstrap with this node, edit the grastate.dat file manually and set safe_to_bootstrap to 1 .

**Настройки**
show variables like '%wsrep%'\G
-- wsrep_provider_options



**Установка proxySQL load balance**
https://www.percona.com/doc/percona-xtradb-cluster/8.0/howtos/proxysql.html#load-balancing-with-proxysql
pxc ProxySql
Создаём и настраиваем дополнительную машину
```
sudo apt update
sudo apt-cache search percona
sudo percona-release enable-only pxc-80 release
sudo percona-release enable tools release
sudo apt update
sudo apt install percona-xtradb-cluster-client -y
sudo apt install proxysql2 -y
```
**Заходим в собственную оболочку ProxySQL**
```
mysql -u admin -padmin -h 127.0.0.1 -P 6032
> SHOW DATABASES;
mysql> SHOW DATABASES;
```
+-----+---------------+-------------------------------------+
| seq | name          | file                                |
+-----+---------------+-------------------------------------+
| 0   | main          |                                     |
| 2   | disk          | /var/lib/proxysql/proxysql.db       |
| 3   | stats         |                                     |
| 4   | monitor       |                                     |
| 5   | stats_history | /var/lib/proxysql/proxysql_stats.db |
+-----+---------------+-------------------------------------+
5 rows in set (0.00 sec)
> SHOW TABLES;
Не забываем указать ip
```
gcomm://10.129.0.30,10.129.0.28,10.129.0.34
-- Adding cluster nodes to ProxySQL
> INSERT INTO mysql_servers(hostgroup_id, hostname, port) VALUES (1,'10.129.0.30',3306);
> INSERT INTO mysql_servers(hostgroup_id, hostname, port) VALUES (1,'10.129.0.28',3306);
> INSERT INTO mysql_servers(hostgroup_id, hostname, port) VALUES (1,'10.129.0.34',3306);
> SELECT * FROM mysql_servers;
```

ProxySQL has 3 areas where the configuration can reside:
    MEMORY (your current working place)
    RUNTIME (the production settings)
    DISK (durable configuration, saved inside an SQLITE database)
When you change a parameter, you change it in MEMORY area. That is done by design to allow you to test the changes before pushing to production (RUNTIME), or save them to disk.

-- https://github.com/sysown/proxysql/blob/master/doc/admin_tables.md
-- https://github.com/sysown/proxysql/blob/master/doc/global_variables.md
-- https://github.com/sysown/proxysql/blob/master/doc/configuration_howto.md

**Посмотрим статус мониторинга**
```
SELECT * FROM monitor.mysql_server_connect_log ORDER BY time_start_us DESC LIMIT 6;
```
В противном случае несмотря на наличие серверов конфигурации не заработает должным образом.
```
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
SELECT hostgroup_id,hostname,port,status FROM runtime_mysql_servers;
```
Отсутствует группа по умолчанию
```
INSERT INTO mysql_replication_hostgroups (writer_hostgroup,reader_hostgroup,comment) VALUES (0,1,'cluster1');
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```
Проверим группы репликации
```
SELECT * FROM mysql_servers;
```
**Добавим юзера на** 
На pxc1 / 2 / 3 - достаточно на 1, так как конфигурация мульти-мастер
В новых версиях можно использовать caching_sha2_password
```
CREATE USER 'proxysql'@'%' IDENTIFIED WITH mysql_native_password by 'Otus321$';
CREATE USER 'proxysql'@'%' IDENTIFIED WITH caching_sha2_password by 'Otus321$';
SELECT * FROM mysql.user\G
```
*************************** 1. row ***************************
                    Host: %
                    User: proxysql
             Select_priv: N
             Insert_priv: N
             Update_priv: N
             Delete_priv: N
             Create_priv: N
               Drop_priv: N
             Reload_priv: N
           Shutdown_priv: N
            Process_priv: N
               File_priv: N
              Grant_priv: N
         References_priv: N
              Index_priv: N
              Alter_priv: N
            Show_db_priv: N
              Super_priv: N
   Create_tmp_table_priv: N
        Lock_tables_priv: N
            Execute_priv: N
         Repl_slave_priv: N
        Repl_client_priv: N
        Create_view_priv: N
          Show_view_priv: N
     Create_routine_priv: N
      Alter_routine_priv: N
        Create_user_priv: N
              Event_priv: N
            Trigger_priv: N
  Create_tablespace_priv: N
                ssl_type: 
              ssl_cipher: 0x
             x509_issuer: 0x
            x509_subject: 0x
           max_questions: 0
             max_updates: 0
         max_connections: 0
    max_user_connections: 0
                  plugin: mysql_native_password
   authentication_string: *B0C45F304FAE1091CF5AFD07BCD414C905E98C8B
        password_expired: N
   password_last_changed: 2023-02-26 18:21:10
       password_lifetime: NULL
          account_locked: N
        Create_role_priv: N
          Drop_role_priv: N
  Password_reuse_history: NULL
     Password_reuse_time: NULL
Password_require_current: NULL
         User_attributes: NULL

**Зафиксируем его в настройках on pxcps**

ProxySQL currently doesn’t encrypt passwords.
```
UPDATE global_variables SET variable_value='proxysql' WHERE variable_name='mysql-monitor_username';
UPDATE global_variables SET variable_value='Otus321$' WHERE variable_name='mysql-monitor_password';
```
**Загрузим конфигурацию VARIABLES в оперативную память**
To enable monitoring of these nodes, load them at runtime:
```
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
SELECT * FROM global_variables WHERE variable_name LIKE 'mysql-monitor_%';

mysql> SELECT * FROM global_variables WHERE variable_name LIKE 'mysql-monitor_%';
```
+----------------------------------------------------------------------+----------------+
| variable_name                                                        | variable_value |
+----------------------------------------------------------------------+----------------+
| mysql-monitor_enabled                                                | true           |
| mysql-monitor_connect_timeout                                        | 600            |
| mysql-monitor_ping_max_failures                                      | 3              |
| mysql-monitor_ping_timeout                                           | 1000           |
| mysql-monitor_read_only_max_timeout_count                            | 3              |
| mysql-monitor_replication_lag_group_by_host                          | false          |
| mysql-monitor_replication_lag_interval                               | 10000          |
| mysql-monitor_replication_lag_timeout                                | 1000           |
| mysql-monitor_replication_lag_count                                  | 1              |
| mysql-monitor_groupreplication_healthcheck_interval                  | 5000           |
| mysql-monitor_groupreplication_healthcheck_timeout                   | 800            |
| mysql-monitor_groupreplication_healthcheck_max_timeout_count         | 3              |
| mysql-monitor_groupreplication_max_transactions_behind_count         | 3              |
| mysql-monitor_groupreplication_max_transactions_behind_for_read_only | 1              |
| mysql-monitor_galera_healthcheck_interval                            | 5000           |
| mysql-monitor_galera_healthcheck_timeout                             | 800            |
| mysql-monitor_galera_healthcheck_max_timeout_count                   | 3              |
| mysql-monitor_replication_lag_use_percona_heartbeat                  |                |
| mysql-monitor_query_interval                                         | 60000          |
| mysql-monitor_query_timeout                                          | 100            |
| mysql-monitor_slave_lag_when_null                                    | 60             |
| mysql-monitor_threads_min                                            | 8              |
| mysql-monitor_threads_max                                            | 128            |
| mysql-monitor_threads_queue_maxsize                                  | 128            |
| mysql-monitor_local_dns_cache_ttl                                    | 300000         |
| mysql-monitor_local_dns_cache_refresh_interval                       | 60000          |
| mysql-monitor_local_dns_resolver_queue_maxsize                       | 128            |
| mysql-monitor_wait_timeout                                           | true           |
| mysql-monitor_writer_is_also_reader                                  | true           |
| mysql-monitor_username                                               | proxysql       |
| mysql-monitor_password                                               | Otus321$       |
| mysql-monitor_history                                                | 600000         |
| mysql-monitor_connect_interval                                       | 60000          |
| mysql-monitor_ping_interval                                          | 10000          |
| mysql-monitor_read_only_interval                                     | 1500           |
| mysql-monitor_read_only_timeout                                      | 500            |
+----------------------------------------------------------------------+----------------+
36 rows in set (0.00 sec)

```
SELECT * FROM monitor.mysql_server_connect_log ORDER BY time_start_us DESC LIMIT 6;
```
```
mysql> SELECT * FROM monitor.mysql_server_connect_log ORDER BY time_start_us DESC LIMIT 6;
```
+-------------+------+------------------+-------------------------+-------------------------------------------------------------------------------------+
| hostname    | port | time_start_us    | connect_success_time_us | connect_error                                                                       |
+-------------+------+------------------+-------------------------+-------------------------------------------------------------------------------------+
| 10.129.0.34 | 3306 | 1677436084853384 | 1381                    | NULL                                                                                |
| 10.129.0.28 | 3306 | 1677436084302915 | 1445                    | NULL                                                                                |
| 10.129.0.30 | 3306 | 1677436083752372 | 1346                    | NULL                                                                                |
| 10.129.0.28 | 3306 | 1677436073661610 | 0                       | Access denied for user 'monitor'@'pxcps.ru-central1.internal' (using password: YES) |
| 10.129.0.30 | 3306 | 1677436073078534 | 0                       | Access denied for user 'monitor'@'pxcps.ru-central1.internal' (using password: YES) |
| 10.129.0.34 | 3306 | 1677436072495526 | 0                       | Access denied for user 'monitor'@'pxcps.ru-central1.internal' (using password: YES) |
+-------------+------+------------------+-------------------------+-------------------------------------------------------------------------------------+
6 rows in set (0.00 sec)

**Creating ProxySQL Client User**
```
INSERT INTO mysql_users (username,password) VALUES ('sbuser','Otus321$');
LOAD MYSQL USERS TO RUNTIME;
```
**Чтобы не потерять текущую конфигурацию USERS, запишем ее на диск**
```
SAVE MYSQL USERS TO DISK;
```
