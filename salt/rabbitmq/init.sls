rabbitmq:
  pkg.installed:
    - name: rabbitmq-server
    - refresh: False
  service.running:
    - name: rabbitmq-server
    - require:
      - pkg: rabbitmq-server

  rabbitmq_user.present:
    - name: guest
    - password: {{ pillar['rabbitmq']['rabbit_pass'] }}
    - force: True
    - require:
      - service: rabbitmq-server
