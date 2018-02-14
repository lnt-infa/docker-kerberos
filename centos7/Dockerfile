FROM centos:7.2.1511
MAINTAINER Louis-Noël Trapadoux <ltrapadoux@informatica.com>

# EPEL
#RUN rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm


#################################################################################
# Systemd stuff
#################################################################################
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*;\
    rm -f /etc/systemd/system/*.wants/*;\
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;\
    rm -f /lib/systemd/system/anaconda.target.wants/*;
#################################################################################
# Fix dbus starting
RUN mkdir -p /etc/selinux/targeted/contexts/
RUN echo '<busconfig><selinux></selinux></busconfig>' > /etc/selinux/targeted/contexts/dbus_contexts



# kerberos
RUN yum install -y krb5-server krb5-libs krb5-auth-dialog krb5-workstation initscripts

EXPOSE 88 749

ADD ./config.sh /config.sh

VOLUME [ "/sys/fs/cgroup" ]

CMD /config.sh && exec /usr/sbin/init
#CMD /usr/sbin/init
