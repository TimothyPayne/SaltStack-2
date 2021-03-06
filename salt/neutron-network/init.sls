sysctl_network:
  file.managed:  
    - name: /etc/sysctl.conf
    - source: salt://neutron-network/file/sysctl.conf

sysctl_apply:
  cmd.run:
    - name: sysctl -p
    - require:
      - file: sysctl_network

neutron_network:
  pkg.installed:
    - refresh: False
    - pkgs:
{% for pkg in salt['pillar.get']('neutron_network:pkgs', []) %}
      - {{ pkg }}
{% endfor %}

{% for file in salt['pillar.get']('neutron_network:files', [])%}
{{ file['name'] }}_network:
  file.managed:
    - name: {{file['name']}}
    - source: {{file['source']}}
    - user: neutron
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: neutron_network
{% endfor %}

fix_error:
  cmd.run:
    - name: |
        echo "dnsmasq_config_file = /etc/neutron/dnsmasq-neutron.conf" >> /etc/neutron/dhcp_agent.ini
        echo "dhcp-option-force=26,1454" > /etc/neutron/dnsmasq-neutron.conf
        killall dnsmasq
    - unless: cat /etc/neutron/dnsmasq-neutron.conf

dnsmasq_status:
  cmd.run:
    - name: echo port=5353 >> /etc/dnsmasq.conf

{% for service in salt['pillar.get']('neutron_network:services', [])%}
{{service}}:
  service.running:
    - watch:
      - file: /etc/neutron/neutron.conf_network
      - file: /etc/neutron/l3_agent.ini_network
      - file: /etc/neutron/dhcp_agent.ini_network
      - file: /etc/neutron/metadata_agent.ini_network
      - file: /etc/neutron/plugins/ml2/ml2_conf.ini_network
{% endfor %}

create_int:
  cmd.run:
    - name: ovs-vsctl add-br br-int   
    - unless: ovs-vsctl list-br | grep br-int
    - require:
      - service: openvswitch-switch
 
create_ex:
  cmd.run:
    - name: |
        ovs-vsctl add-br br-ex
        ovs-vsctl add-port br-ex {{pillar['neutron_network']['br-ex']}}
    - unless: ovs-vsctl list-br | grep br-ex 
    - require:
      - service: openvswitch-switch

edit_network:
  file.managed:
    - name: /etc/network/interfaces
    - source: salt://neutron-network/file/interfaces
    - template: jinja
    - require:
      - cmd: create_ex

restart_network:
  cmd.run:
    - name: |
        ifdown eth1 && ifup eth1
        ifdown br-ex && ifup br-ex
    - require:
      - file: edit_network

profile_1:
  file.managed:
    - name: /root/.profile
    - source: salt://keystone/file/profile
    - template: jinja

admin_openrc_network:
  file.managed:
    - name: /root/admin-openrc.sh
    - source: salt://keystone/file/admin-openrc.sh
    - template: jinja

