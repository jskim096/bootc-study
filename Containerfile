FROM quay.io/centos-bootc/centos-bootc:stream9

# 1. 패키지 설치 (필요시)
RUN dnf -y install passwd sudo vim openssh-server authselect libpwquality at

# 2-1. 계정 및 wheel 그룹 생성, 비밀번호 설정
RUN useradd -m -G wheel bootc_admin && \
    useradd -m bootc_user && \
    echo 'bootc_admin:c!0udc1u6b0oC' | chpasswd && \
    echo 'bootc_user:c!0udc1u6b0oC' | chpasswd && \
    echo 'root:c!0udc1u6b0oC' | chpasswd

# 2-2. /etc/pam.d/su wheel 주석 제거
RUN sed -i 's/^#auth\s\+required\s\+pam_wheel.so use_uid/auth required pam_wheel.so use_uid/' /etc/pam.d/su

# 3. /usr/bin/su 및 SUID/SGID 관련 보안 설정
RUN chgrp wheel /usr/bin/su && \
    chmod 4750 /usr/bin/su && \
    chmod 755 /usr/sbin/unix_chkpwd && \
    chmod 755 /usr/bin/newgrp && \
    chmod 755 /usr/bin/at

# 4. sudo/wheel 설정 (bootc_admin만 su/sudo 허용)
RUN echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel && \
    chmod 440 /etc/sudoers.d/wheel

# 5. SSH root 로그인 제한
RUN sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# 6. 패스워드 정책 (pwquality.conf)
RUN sed -i '/^# minlen/c\minlen = 8' /etc/security/pwquality.conf && \
    sed -i '/^# lcredit/c\lcredit = -1' /etc/security/pwquality.conf && \
    sed -i '/^# ucredit/c\ucredit = -1' /etc/security/pwquality.conf && \
    sed -i '/^# dcredit/c\dcredit = -1' /etc/security/pwquality.conf && \
    sed -i '/^# ocredit/c\ocredit = -1' /etc/security/pwquality.conf

# 7. 계정 잠금 임계값 (faillock)
RUN authselect select sssd --force && \
    authselect enable-feature with-faillock && \
    sed -i '/# deny =/a deny = 5' /etc/security/faillock.conf && \
    sed -i '/# unlock_time =/a unlock_time = 1800' /etc/security/faillock.conf && \
    authselect apply-changes

# 8. 패스워드 최대 사용 기간 설정
RUN sed -i '/^PASS_MAX_DAYS/c\PASS_MAX_DAYS   90' /etc/login.defs

# 9. 파일 권한 설정 (passwd, shadow, hosts)
RUN chown root:root /etc/passwd /etc/shadow /etc/hosts && \
    chmod 644 /etc/passwd /etc/hosts && \
    chmod 400 /etc/shadow
