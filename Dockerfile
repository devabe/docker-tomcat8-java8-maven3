FROM inovatrend/java8

MAINTAINER Abe <contact@tafatek.com>

ENV TOMCAT_MAJOR_VERSION 8
ENV TOMCAT_MINOR_VERSION 8.5.53
ENV CATALINA_HOME /opt/tomcat
ENV JAVA_OPTS "-Xms1024m -Xmx4096m -XX:PermSize=128m -Xss10m"
ENV MAVEN_MAJOR_VERSION 3
ENV MAVEN_VERSION 3.6.2
ENV MAVEN_HOME /opt/maven

RUN apt-get update && \
    apt-get install -yq --no-install-recommends pwgen ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
    
# Install tomcat
RUN \
    wget -q https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_MINOR_VERSION}/bin/apache-tomcat-${TOMCAT_MINOR_VERSION}.tar.gz && \
    tar zxf apache-tomcat-*.tar.gz && \
    rm apache-tomcat-*.tar.gz && \
    mv apache-tomcat* ${CATALINA_HOME}

# Add script for creating tomcat admin user and starting tomcat
ADD create_tomcat_admin_user.sh /create_tomcat_admin_user.sh
ADD run.sh /run.sh
RUN chmod +x /*.sh

# Add script for starting tomcat as runit service
RUN mkdir /etc/service/tomcat
ADD tomcat.sh /etc/service/tomcat/run
RUN chmod +x /etc/service/tomcat/run

# Add tomcat context.xml file which allows symlinks (allowLinking = true)
ADD context.xml ${CATALINA_HOME}/conf/

# Remove unneeded apps
RUN rm -rf ${CATALINA_HOME}/webapps/examples ${CATALINA_HOME}/webapps/docs 

# Enabling the insecure key permanently, to be able to login to container using ssh, or docker-ssh
RUN /usr/sbin/enable_insecure_key

# Add navgraph directory
RUN mkdir /usr/navgraph

# get maven ${MAVEN_VERSION}
RUN wget --no-verbose -O /tmp/apache-maven-${MAVEN_VERSION}.tar.gz http://archive.apache.org/dist/maven/maven-${MAVEN_MAJOR_VERSION}/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
# install maven
RUN tar xzf /tmp/apache-maven-${MAVEN_VERSION}.tar.gz -C /opt/
RUN ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven
RUN ln -s /opt/maven/bin/mvn /usr/local/bin
RUN rm -f /tmp/apache-maven-${MAVEN_VERSION}.tar.gz
RUN mkdir /.m2

RUN mvn -version

# remove download archive files
RUN apt-get clean

ENV PATH $PATH:$CATALINA_HOME/bin

EXPOSE 8080

