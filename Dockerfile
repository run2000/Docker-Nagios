ARG  UBUNTU_VERSION=20.04

FROM ubuntu:$UBUNTU_VERSION

# Arguments for the LABELs and the branches defined later

ARG NAGIOS_VER=4.4.10
ARG NAGIOS_PLUGINS_VER=2.4.3
ARG NRPE_VER=4.1.0
ARG NCPA_VER=2.4.0
ARG NSCA_VER=2.10.2
ARG NRDP_VER=2.0.5

LABEL name="Nagios" \
    nagiosVersion=$NAGIOS_VER \
    nagiosPluginsVersion=$NAGIOS_PLUGINS_VER \
    nrpeVersion=$NRPE_VER \
    nscaVersion=$NSCA_VER \
    ncpaVersion=$NCPA_VER \
    nrdpVersion=$NRDP_VER \
    homepage="https://www.nagios.com/" \
    maintainer="NicholasC <run2000@gmail.com>"

# Variables both build and runtime

ARG NAGIOS_HOME=/opt/nagios
ARG NAGIOSGRAPH_HOME=/opt/nagiosgraph
ARG NRDP_HOME=/opt/nrdp
ARG NRDP_TOKEN
ARG NRDP_ENABLED=1
ARG NAGIOS_USER=nagios
ARG NAGIOS_GROUP=nagios
ARG NAGIOS_CMDUSER=nagios
ARG NAGIOS_CMDGROUP=nagios
ARG NAGIOS_FQDN=nagios.example.com
ARG NAGIOSADMIN_USER=nagiosadmin
ARG NAGIOSADMIN_PASS=nagios
ARG APACHE_RUN_USER=nagios
ARG APACHE_RUN_GROUP=nagios
ARG APACHE_LOCK_DIR=/var/run
ARG APACHE_LOG_DIR=/var/log/apache2
ARG NAGIOS_TIMEZONE=UTC

# For Postfix build-time configuration
ARG DEBIAN_FRONTEND=noninteractive

# Build variables
ARG NG_NAGIOS_CONFIG_FILE=${NAGIOS_HOME}/etc/nagios.cfg
ARG NG_CGI_DIR=${NAGIOS_HOME}/sbin
ARG NG_WWW_DIR=${NAGIOS_HOME}/share/nagiosgraph
ARG NG_CGI_URL=/cgi-bin

# Tags and branches for Git checkout
ARG NAGIOS_BRANCH="nagios-${NAGIOS_VER}"
ARG NAGIOS_PLUGINS_BRANCH="release-${NAGIOS_PLUGINS_VER}"
ARG NRPE_BRANCH="nrpe-${NRPE_VER}"
ARG NCPA_BRANCH="v${NCPA_VER}"
ARG NSCA_TAG="nsca-${NSCA_VER}"
ARG NRDP_TAG=${NRDP_VER}


RUN echo postfix postfix/main_mailer_type string "'Internet Site'" | debconf-set-selections  && \
    echo postfix postfix/mynetworks string "127.0.0.0/8" | debconf-set-selections            && \
    echo postfix postfix/mailname string ${NAGIOS_FQDN} | debconf-set-selections             && \
    apt-get update && apt-get install -y    \
        apache2                             \
        apache2-utils                       \
        autoconf                            \
        automake                            \
        bc                                  \
        bsd-mailx                           \
        build-essential                     \
        dnsutils                            \
        fping                               \
        gettext                             \
        git                                 \
        gperf                               \
        iputils-ping                        \
        jq                                  \
        libapache2-mod-php                  \
        libcache-memcached-perl             \
        libcgi-pm-perl                      \
        libdbd-mysql-perl                   \
        libdbi-dev                          \
        libdbi-perl                         \
        libcrypt-des-perl                   \
        libcrypt-rijndael-perl              \
        libdigest-hmac-perl                 \
        libfreeradius-dev                   \
        libgdchart-gd2-xpm-dev              \
        libgd-gd2-perl                      \
        libjson-perl                        \
        libldap2-dev                        \
        libmonitoring-plugin-perl           \
        libmysqlclient-dev                  \
        libnagios-object-perl               \
        libnet-snmp-perl                    \
        libnet-tftp-perl                    \
        libnet-xmpp-perl                    \
        libpq-dev                           \
        libradsec-dev                       \
        libredis-perl                       \
        librrds-perl                        \
        libssl-dev                          \
        libswitch-perl                      \
        libwww-perl                         \
        m4                                  \
        netcat                              \
        parallel                            \
        php-cli                             \
        php-gd                              \
        php-xml                             \
        postfix                             \
        python3-pip                         \
        python3-nagiosplugin                \
        rsyslog                             \
        runit                               \
        smbclient                           \
        snmp                                \
        snmpd                               \
        snmp-mibs-downloader                \
        unzip                               \
        python                              \
                                                && \
    apt-get clean && find /var/lib/apt/lists/ -maxdepth 1 -type f -delete

# Create Nagios users and groups

RUN ( egrep -i "^${NAGIOS_GROUP}"    /etc/group || groupadd $NAGIOS_GROUP    )                         && \
    ( egrep -i "^${NAGIOS_CMDGROUP}" /etc/group || groupadd $NAGIOS_CMDGROUP )
RUN ( id -u $NAGIOS_USER    || useradd --system -d $NAGIOS_HOME -g $NAGIOS_GROUP    $NAGIOS_USER    )  && \
    ( id -u $NAGIOS_CMDUSER || useradd --system -d $NAGIOS_HOME -g $NAGIOS_CMDGROUP $NAGIOS_CMDUSER )

# Pull and build Nagios Core

RUN cd /tmp                                                                          && \
    git clone https://github.com/NagiosEnterprises/nagioscore.git -b $NAGIOS_BRANCH  && \
    cd nagioscore                                                                    && \
    ./configure                                  \
        --prefix=${NAGIOS_HOME}                  \
        --exec-prefix=${NAGIOS_HOME}             \
        --enable-event-broker                    \
        --with-command-user=${NAGIOS_CMDUSER}    \
        --with-command-group=${NAGIOS_CMDGROUP}  \
        --with-nagios-user=${NAGIOS_USER}        \
        --with-nagios-group=${NAGIOS_GROUP}      \
                                                                                     && \
    make all                                                                         && \
    make install                                                                     && \
    make install-config                                                              && \
    make install-commandmode                                                         && \
    make install-webconf                                                             && \
    make clean                                                                       && \
    cd /tmp && rm -Rf nagioscore

# Pull and build Nagios Plugins

RUN cd /tmp                                                                                   && \
    git clone https://github.com/nagios-plugins/nagios-plugins.git -b $NAGIOS_PLUGINS_BRANCH  && \
    cd nagios-plugins                                                                         && \
    ./tools/setup                                                                             && \
    ./configure                                                 \
        --prefix=${NAGIOS_HOME}                                 \
        --with-ipv6                                             \
        --with-ping6-command="/bin/ping6 -n -U -W %d -c %d %s"  \
                                                                                              && \
    make                                                                                      && \
    make install                                                                              && \
    make clean                                                                                && \
    mkdir -p /usr/lib/nagios/plugins                                                          && \
    ln -sf ${NAGIOS_HOME}/libexec/utils.pm /usr/lib/nagios/plugins                            && \
    cd /tmp && rm -Rf nagios-plugins

# Pull and install NCPA client

RUN wget -O ${NAGIOS_HOME}/libexec/check_ncpa.py https://raw.githubusercontent.com/NagiosEnterprises/ncpa/${NCPA_BRANCH}/client/check_ncpa.py  && \
    chmod +x ${NAGIOS_HOME}/libexec/check_ncpa.py

# Pull and build NRPE

RUN cd /tmp                                                                  && \
    git clone https://github.com/NagiosEnterprises/nrpe.git -b $NRPE_BRANCH  && \
    cd nrpe                                                                  && \
    ./configure                                        \
                                                                             && \
    make check_nrpe                                                          && \
    cp src/check_nrpe ${NAGIOS_HOME}/libexec/                                && \
    make clean                                                               && \
    cd /tmp && rm -Rf nrpe

# Pull and build NSCA

RUN cd /tmp                                                 && \
    git clone https://github.com/NagiosEnterprises/nsca.git && \
    cd nsca                                                 && \
    git checkout $NSCA_TAG                                  && \
    cp /usr/share/misc/config.* .                           && \
    ./configure                                                \
        --prefix=${NAGIOS_HOME}                                \
        --with-nsca-user=${NAGIOS_USER}                        \
        --with-nsca-grp=${NAGIOS_GROUP}                     && \
    make all                                                && \
    cp src/nsca ${NAGIOS_HOME}/bin/                         && \
    cp src/send_nsca ${NAGIOS_HOME}/bin/                    && \
    cp sample-config/nsca.cfg ${NAGIOS_HOME}/etc/           && \
    cp sample-config/send_nsca.cfg ${NAGIOS_HOME}/etc/      && \
    sed -i 's/^#server_address.*/server_address=0.0.0.0/'  ${NAGIOS_HOME}/etc/nsca.cfg && \
    cd /tmp && rm -Rf nsca

# Download and configure NRDP

RUN cd /tmp && \
  git clone https://github.com/NagiosEnterprises/nrdp.git -b ${NRDP_TAG} && \
  chown -R ${NAGIOS_USER}:${NAGIOS_GROUP} nrdp && \
  cp nrdp/nrdp.conf /etc/apache2/sites-available/nrdp.conf && \
  sed -i "s|/usr/local/nrdp|${NRDP_HOME}|g" /etc/apache2/sites-available/nrdp.conf && \
  mkdir -p ${NRDP_HOME} && \
  cp -a /tmp/nrdp/server ${NRDP_HOME} && \
  sed -i "s|/usr/local/nrdp|${NRDP_HOME}|g" ${NRDP_HOME}/server/config.inc.php && \
  sed -i "s|/usr/local/nagios|${NAGIOS_HOME}|g" ${NRDP_HOME}/server/config.inc.php  && \
  sed -i "s|\\[\"nagios_command_group\"\\]\\s*=.*|[\"nagios_command_group\"] = \"${NAGIOS_CMDGROUP}\";|g" ${NRDP_HOME}/server/config.inc.php && \
  sed -i "s|/usr/local/nrdp|${NRDP_HOME}|g" ${NRDP_HOME}/server/includes/utils.inc.php && \
  sed -i "s|/usr/local/nagiosxi/html|${NAGIOS_HOME}/share|g" ${NRDP_HOME}/server/plugins/nagioscorepassivecheck/nagioscorepassivecheck.inc.php && \
  sed -i "s|/usr/local/nagiosxi|${NAGIOS_HOME}|g" ${NRDP_HOME}/server/plugins/nagioscorepassivecheck/nagioscorepassivecheck.inc.php && \
  sed -i "s|/usr/local/nagios|${NAGIOS_HOME}|g" ${NRDP_HOME}/server/plugins/nagioscorepassivecheck/nagioscorepassivecheck.inc.php && \
  cd /tmp && rm -Rf nrdp

# NRDP is enabled with the nrdp.conf file in Apache
# If a token is present as a build arg, configure it

RUN if [ "${NRDP_ENABLED}" = "1" ] ; then ln -sf /etc/apache2/sites-available/nrdp.conf /etc/apache2/sites-enabled/nrdp.conf ; fi ; \
    if ! [ "${NRDP_TOKEN}" = "" ] ; then sed -i "s|//\s*\"mysecrettoken\".*|\"${NRDP_TOKEN}\",|g" ${NRDP_HOME}/server/config.inc.php ; fi

# Pull and build Nagiosgraph

RUN cd /tmp                                                          && \
    git clone https://git.code.sf.net/p/nagiosgraph/git nagiosgraph  && \
    cd nagiosgraph                                                   && \
    ./install.pl --install                                      \
        --prefix ${NAGIOSGRAPH_HOME}                            \
        --nagios-user ${NAGIOS_USER}                            \
        --www-user ${NAGIOS_USER}                               \
        --nagios-perfdata-file ${NAGIOS_HOME}/var/perfdata.log  \
        --nagios-cgi-url /cgi-bin                               \
                                                                     && \
    cp share/nagiosgraph.ssi ${NAGIOS_HOME}/share/ssi/common-header.ssi && \
    cd /tmp && rm -Rf nagiosgraph

# Basic configureation of Apache2

RUN sed -i.bak 's/.*\=www\-data//g' /etc/apache2/envvars
RUN export DOC_ROOT="DocumentRoot $(echo $NAGIOS_HOME/share)"                         && \
    sed -i "s,DocumentRoot.*,$DOC_ROOT," /etc/apache2/sites-enabled/000-default.conf  && \
    sed -i "s,</VirtualHost>,<IfDefine ENABLE_USR_LIB_CGI_BIN>\nScriptAlias /cgi-bin/ ${NAGIOS_HOME}/sbin/\n</IfDefine>\n</VirtualHost>," /etc/apache2/sites-enabled/000-default.conf  && \
    ln -s /etc/apache2/mods-available/cgi.load /etc/apache2/mods-enabled/cgi.load

# Configuration of SNMP and MIB files

RUN mkdir -p -m 0755 /usr/share/snmp/mibs                     && \
    mkdir -p         ${NAGIOS_HOME}/etc/conf.d                && \
    mkdir -p         ${NAGIOS_HOME}/etc/monitor               && \
    mkdir -p         ${NAGIOS_HOME}/mibs                      && \
    mkdir -p -m 700  ${NAGIOS_HOME}/.ssh                      && \
    chown ${NAGIOS_USER}:${NAGIOS_GROUP} ${NAGIOS_HOME}/.ssh  && \
    chown ${NAGIOS_USER}:${NAGIOS_GROUP} ${NAGIOS_HOME}/mibs  && \
    touch /usr/share/snmp/mibs/.foo                           && \
    ln -s /usr/share/snmp/mibs ${NAGIOS_HOME}/libexec/mibs    && \
    ln -s ${NAGIOS_HOME}/bin/nagios /usr/local/bin/nagios     && \
    download-mibs && echo "mibs +ALL" > /etc/snmp/snmp.conf   && \
    echo "mibdirs +${NAGIOS_HOME}/mibs" >> /etc/snmp/snmp.conf

# Nagios configuration adjustments

RUN sed -i 's,/bin/mail,/usr/bin/mail,' ${NAGIOS_HOME}/etc/objects/commands.cfg  && \
    sed -i 's,/usr/usr,/usr,'           ${NAGIOS_HOME}/etc/objects/commands.cfg

# Mail configuration

RUN cp /etc/services /var/spool/postfix/etc/  && \
    echo "smtp_address_preference = ipv4" >> /etc/postfix/main.cf

RUN sed -i 's/ askcc//' /etc/mail.rc

# Remove the current rsyslog config. This gets replaced by the overlay.

RUN rm -rf /etc/rsyslog.d /etc/rsyslog.conf

RUN rm -rf /etc/sv/getty-5

ADD overlay /

# Set up build-time timezone for Nagios

RUN echo "use_timezone=${NAGIOS_TIMEZONE}" >> ${NAGIOS_HOME}/etc/nagios.cfg

# Copy example config in-case the user has started with empty var or etc

RUN mkdir -p /orig/var                     && \
    mkdir -p /orig/etc                     && \
    cp -Rp ${NAGIOS_HOME}/var/* /orig/var/ && \
    cp -Rp ${NAGIOS_HOME}/etc/* /orig/etc/ 

# Enable Apache modules

RUN a2enmod session         && \
    a2enmod session_cookie  && \
    a2enmod session_crypto  && \
    a2enmod auth_form       && \
    a2enmod request

# Make our startup files executable

RUN chmod +x /usr/local/bin/start_nagios        && \
    chmod +x /etc/sv/apache/run                 && \
    chmod +x /etc/sv/nagios/run                 && \
    chmod +x /etc/sv/postfix/run                 && \
    chmod +x /etc/sv/rsyslog/run                 && \
    chmod +x /opt/nagiosgraph/etc/fix-nagiosgraph-multiple-selection.sh

# Patch Nagiosgraph

RUN cd /opt/nagiosgraph/etc && \
    sh fix-nagiosgraph-multiple-selection.sh

RUN rm /opt/nagiosgraph/etc/fix-nagiosgraph-multiple-selection.sh


# Copy Nagiosgraph config in-case the user has started with empty etc

RUN mkdir -p /orig/nagiosgraph-etc           && \
    cp -Rp ${NAGIOSGRAPH_HOME}/etc/* /orig/nagiosgraph-etc/ && \
    mkdir -p /orig/nrdp-server               && \
    cp -Rp ${NRDP_HOME}/server/* /orig/nrdp-server/

# enable all runit services
RUN ln -s /etc/sv/* /etc/service

#Set ServerName and timezone for Apache with build-time configuration

RUN echo "ServerName ${NAGIOS_FQDN}" > /etc/apache2/conf-available/servername.conf    && \
    echo "PassEnv TZ" > /etc/apache2/conf-available/timezone.conf            && \
    ln -s /etc/apache2/conf-available/servername.conf /etc/apache2/conf-enabled/servername.conf    && \
    ln -s /etc/apache2/conf-available/timezone.conf /etc/apache2/conf-enabled/timezone.conf

# Copy the ARG variables into the runtime environment
ENV NAGIOS_HOME=$NAGIOS_HOME \
    NAGIOS_USER=$NAGIOS_USER \
    NAGIOS_GROUP=$NAGIOS_GROUP \
    NAGIOS_FQDN=$NAGIOS_FQDN \
    NAGIOSADMIN_USER=$NAGIOSADMIN_USER \
    NAGIOSADMIN_PASS=$NAGIOSADMIN_PASS \
    APACHE_RUN_USER=$APACHE_RUN_USER \
    APACHE_RUN_GROUP=$APACHE_RUN_GROUP \
    APACHE_LOCK_DIR=$APACHE_LOCK_DIR \
    APACHE_LOG_DIR=$APACHE_LOG_DIR \
    NAGIOS_TIMEZONE=$NAGIOS_TIMEZONE

# These are passed into the Postfix startup script
#ENV MAIL_RELAY_HOST
#ENV MAIL_INET_PROTOCOLS

EXPOSE 80

HEALTHCHECK --interval=120s --timeout=5s CMD /usr/local/bin/nagios -v ${NAGIOS_HOME}/etc/nagios.cfg

VOLUME "${NAGIOS_HOME}/var" "${NAGIOS_HOME}/etc" "/var/log/apache2" "${NAGIOS_HOME}/custom-plugins" "${NAGIOSGRAPH_HOME}/var" "${NAGIOSGRAPH_HOME}/etc" "${NAGIOS_HOME}/mibs" "${NRDP_HOME}/server"

CMD [ "/usr/local/bin/start_nagios" ]
