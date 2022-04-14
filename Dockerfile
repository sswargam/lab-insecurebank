FROM tomcat:9-jdk8

ADD target/insecure-bank.war /usr/local/tomcat/webapps/

EXPOSE 8080
CMD ["catalina.sh", "run"]
