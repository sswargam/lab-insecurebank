FROM tomcat:9-jdk8

COPY *.war /usr/local/tomcat/webapps/

EXPOSE 8080
CMD ["catalina.sh", "run"]
