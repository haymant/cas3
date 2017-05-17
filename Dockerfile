# VERSION               0.0.1

FROM      ubuntu:14.04
MAINTAINER Zhao Li "cas@lizhao.net"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y wget nano unzip ldap-utils
# Download Azul Java, verify the hash, and install \
RUN set -x; \
    java_version=8.0.112; \
    zulu_version=8.19.0.1; \
    java_hash=3f95d82bf8ece272497ae2d3c5b56c3b; \

    cd / \
    && wget http://cdn.azul.com/zulu/bin/zulu$zulu_version-jdk$java_version-linux_x64.tar.gz \
    && echo "$java_hash  zulu$zulu_version-jdk$java_version-linux_x64.tar.gz" | md5sum -c - \
    && tar -zxvf zulu$zulu_version-jdk$java_version-linux_x64.tar.gz -C /opt \
    && rm zulu$zulu_version-jdk$java_version-linux_x64.tar.gz \
    && ln -s /opt/zulu$zulu_version-jdk$java_version-linux_x64/jre/ /opt/jre-home;

ENV JAVA_HOME /opt/jre-home
ENV PATH $PATH:$JAVA_HOME/bin:.

RUN wget http://www-eu.apache.org/dist/tomcat/tomcat-7/v7.0.77/bin/apache-tomcat-7.0.77.tar.gz \
    && tar -zxvf apache-tomcat-7.0.77.tar.gz -C /opt && rm apache-tomcat-7.0.77.tar.gz \
    && rm -fr /opt/apache-tomcat-7.0.77/webapps/* && rm -fr /var/cache/apt/*
    
ADD cas-server-webapp-3.5.2.war /opt/apache-tomcat-7.0.77/webapps/cas-server-webapp-3.5.2.war 
ADD cas-server-support-ldap-3.5.2.jar /opt/apache-tomcat-7.0.77/webapps/cas-server-support-ldap-3.5.2.jar
ADD server.xml /opt/apache-tomcat-7.0.77/conf/server.xml
COPY certs/* /opt/apache-tomcat-7.0.77/certs/

RUN unzip /opt/apache-tomcat-7.0.77/webapps/cas-server-webapp-3.5.2.war -d /opt/apache-tomcat-7.0.77/webapps/cas \
    && rm /opt/apache-tomcat-7.0.77/webapps/cas-server-webapp-3.5.2.war 
RUN unzip -o /opt/apache-tomcat-7.0.77/webapps/cas-server-support-ldap-3.5.2.jar -d /opt/apache-tomcat-7.0.77/webapps/cas/WEB-INF/classes \
    && rm /opt/apache-tomcat-7.0.77/webapps/cas-server-support-ldap-3.5.2.jar

#war overlay install
#RUN mkdir -p /opt/work/cas-local/src/main/webapp/WEB-INF
#ADD pom.xml /opt/work/cas-local/pom.xml
#ADD cas.properties /opt/work/cas-local/src/main/webapp/WEB-INF/cas.properties
#RUN cd /opt/work/cas-local && mvn clean package \
#    && unzip target/cas.war -d /opt/apache-tomcat-7.0.77/webapps/cas

RUN wget http://www-us.apache.org/dist/directory/apacheds/dist/2.0.0-M23/apacheds-2.0.0-M23-amd64.deb \
    && dpkg -i apacheds-2.0.0-M23-amd64.deb && rm apacheds-2.0.0-M23-amd64.deb \
    && chmod -R a+rwx /var/lib/apacheds-2.0.0-M23 \
    && chmod -R a+rwx /opt && echo "wrapper.java.maxmemory=390" >> /opt/apacheds-2.0.0-M23/conf/wrapper.conf

RUN sed -e 's/RUN_AS_USER="apacheds"//g' -i /opt/apacheds-2.0.0-M23/bin/apacheds
RUN sed -e 's/RUN_AS_GROUP="apacheds"//g' -i /opt/apacheds-2.0.0-M23/bin/apacheds

ADD deployerConfigContext.xml /opt/apache-tomcat-7.0.77/webapps/cas/WEB-INF/deployerConfigContext.xml
ADD setenv.sh /opt/apache-tomcat-7.0.77/bin/setenv.sh
COPY lib/* /opt/apache-tomcat-7.0.77/webapps/cas/WEB-INF/lib/

EXPOSE 8443
WORKDIR /opt/apache-tomcat-7.0.77/bin/

CMD /opt/apacheds-2.0.0-M23/bin/apacheds start default && /opt/apache-tomcat-7.0.77/bin/catalina.sh run
