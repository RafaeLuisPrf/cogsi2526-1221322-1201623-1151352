users_group:
  group.present:
    - name: developers

devuser:
  user.present:
    - name: devuser
    - groups:
      - developers
    - require:
      - group: developers