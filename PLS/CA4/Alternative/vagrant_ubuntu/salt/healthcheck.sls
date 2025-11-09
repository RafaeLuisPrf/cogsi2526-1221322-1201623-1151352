{% if grains['host'] == 'host1' %}
check_spring_app:
  cmd.run:
    - name: curl -f http://localhost:8080 || exit 1
    - require:
      - service: spring_app_service
{% endif %}

{% if grains['host'] == 'host2' %}
check_h2_database:
  cmd.run:
    - name: nc -z localhost 9092 || exit 1
    - require:
      - service: h2_service
{% endif %}