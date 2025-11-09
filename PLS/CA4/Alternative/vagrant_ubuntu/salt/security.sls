install_pam_packages:
  pkg.installed:
    - pkgs:
      - libpam-pwquality
      - libpam-modules

configure_pam_password_policy:
  file.managed:
    - name: /etc/security/pwquality.conf
    - contents: |
        minlen = 12
        minclass = 3
        dictcheck = 1
        usercheck = 1
        retry = 5
        enforce_for_root
        maxrepeat = 3
        dcredit = -1
        ucredit = -1
        lcredit = -1
        ocredit = -1

configure_pam_common_password:
  file.managed:
    - name: /etc/pam.d/common-password
    - contents: |
        password        requisite                       pam_pwquality.so retry=3
        password        [success=2 default=ignore]      pam_unix.so obscure sha512 remember=5
        password        [success=1 default=ignore]      pam_deny.so
        password        required                        pam_permit.so

configure_pam_common_auth:
  file.managed:
    - name: /etc/pam.d/common-auth
    - contents: |
        auth    required                        pam_env.so
        auth    required                        pam_tally2.so deny=5 unlock_time=600 even_deny_root
        auth    [success=1 default=ignore]      pam_unix.so nullok
        auth    requisite                       pam_deny.so
        auth    required                        pam_permit.so