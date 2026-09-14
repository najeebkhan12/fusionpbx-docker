FROM debian:13
LABEL maintainer="najeebkh <khannajeeb362@gmail.com>"
#==================================================================
#MODIFY YOUR DB CONFIG in src/fusionpbx-install.sh/debian/resource/config.sh
#==================================================================

##########################
#include preinstall.sh
#########################
# Set non-interactive mode for apt-get
RUN export DEBIAN_FRONTEND=noninteractive

#upgrade the packages
RUN apt-get update && apt-get upgrade -y

#install packages
# install required packages (git not needed when using local copy)
RUN apt-get install -y lsb-release git

WORKDIR /usr/src
RUN git clone https://github.com/fusionpbx/fusionpbx-install.sh.git

#change the working directory
# make sure installer scripts are executable and run the installer
RUN chmod -R +x /usr/src/fusionpbx-install.sh 

COPY ./config.sh  /usr/src/fusionpbx-install.sh/debian/resources/config.sh
# Source common environment files before running any scripts that rely on them
# Set working directory where resources/scripts will be located
WORKDIR /usr/src/fusionpbx-install.sh/debian

############################
#equal to install.sh
############################


# Strip cdrom sources if present. Debian 13 uses DEB822 files under
# /etc/apt/sources.list.d/ and may not have /etc/apt/sources.list at all.
RUN find /etc/apt -type f \( -name 'sources.list' -o -name '*.list' -o -name '*.sources' \) \
        -exec sed -i '/cdrom:/d' {} + && \
    apt-get update && \
    apt-get upgrade -y

# Install system dependencies in a single RUN for efficiency
RUN apt-get install -y \
        wget \
        lsb-release \
        systemd \
        systemd-sysv \
        ca-certificates \
        dialog \
        nano \
        nginx \
        build-essential \
        snmpd

# Configure SNMP community and restart service
RUN echo "rocommunity public" > /etc/snmp/snmpd.conf && \
    service snmpd restart

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/iptables.sh

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/sngrep.sh

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/fusionpbx.sh

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/php.sh || true

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/nginx.sh ||true

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/postgresql.sh

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/applications.sh

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/switch.sh

# Fail2ban's FusionPBX jails watch classic syslog files. Debian 13 Docker
# images only have journald, so those files do not exist yet and fail2ban
# refuses to start ("Have not found any log file for ssh jail").
# Debian also enables an [sshd] jail via jail.d; disable it — FusionPBX
# ships its own [ssh] jail in jail.local.
RUN mkdir -p /var/log/nginx /etc/fail2ban/jail.d && \
    touch /var/log/auth.log /var/log/syslog /var/log/nginx/access.log && \
    printf '%s\n' '[sshd]' 'enabled = false' > /etc/fail2ban/jail.d/zz-docker-sshd.local && \
    . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/fail2ban.sh

RUN . ./resources/config.sh && \
    . ./resources/colors.sh && \
    . ./resources/environment.sh && \
    ./resources/finish.sh

    # Re-run postgresql.sh and finish.sh to ensure proper setup    
# fix db configuration issues
WORKDIR /usr/src/fusionpbx-install.sh/debian/resources
RUN ./postgresql.sh  && \    
    ./finish.sh

RUN rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/sbin/init"]
