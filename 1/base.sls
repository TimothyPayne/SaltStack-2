network_conf:
  file.managed:
    - name: /etc/network/interfaces
    - source: salt://conf/ip1
net_reload:
  cmd.run:
    - name: ifdown eth0 eth1 && ifup eth0 eth1


hostname:
  cmd.run:
    - name: |
       echo controller > /etc/hostname
       hostname controller
  file.managed:
    - name: /etc/hosts
    - source: /conf/hosts


ntp:
  pkg:
    - installed
  service:
    - running
    - enable: true


mysql:
  pkg:
    - installed
    - pkgs:
      - python-mysqldb
      - mysql-server
mysql_cfg:
  file.managed:
    - name: /etc/mysql/my.cnf
    - source: salt://conf/my.cnf
mysql_reload:
  cmd.run:
    - name: service mysql restart


minion_mysql:
  file.managed:
    - name: /etc/salt/minion
    - source: salt://conf/minion
  cmd.run:
    - name: service salt-minion restart


rabbitmq:
  pkg:
    - installed
    - name: rabitmq-server
  cmd.run:
    - name: rabbitmqctl change_password guest 1






