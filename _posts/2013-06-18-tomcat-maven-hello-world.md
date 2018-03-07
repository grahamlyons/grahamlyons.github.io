title: Hello World WAR Using Tomcat and Maven on Ubuntu
date: 2013-06-18
url_code: hello-world-war-using-tomcat-and-maven-on-ubuntu

Maven is the de facto build tool of Java projects and Tomcat is a very widely used and well-established servlet container. Together they provide an excellent basis for Java projects on the web. To that end I decided to document, from a fresh install of Ubuntu 12.04, the steps required to package and deploy a simple Java webapp, packaged as a WAR, on Tomcat using Maven. At the time of writing the versions used were Tomcat 7 and Maven 3.

## Installing the Required Packages

First we need to install the tools we're going to be using, namely Tomcat, Maven and the JDK so that we can compile Java classes. Running this command will get us what we want:

    sudo apt-get install maven tomcat7 openjdk-6-jdk -y

## Generate the Project Structure

Maven has an ```archetype``` plugin which can generate the structure of the project for us; we're after a 'maven-archetype-webapp', which will give us the basic structure and files for a Java web project:

    mvn archetype:generate -DgroupId=org.example\
     -DartifactId=hello\
     -DarchetypeArtifactId=maven-archetype-webapp\
     -DinteractiveMode=false

Run the command above and a directory named 'hello' will be created (taken from the ```artifactId```) containing the appropriate directory structure and the basic files we need. Change into this directory - you can run ```tree``` to see what was created (install it with ```sudo apt-get install tree -y```):

    [user@host hello]# tree
    .
    |-- pom.xml
    `-- src
        `-- main
            |-- resources
            `-- webapp
                |-- WEB-INF
                |   `-- web.xml
                `-- index.jsp

    5 directories, 3 files

## Add a Servlet

Create directory structure for Java classes and create the servlet file:

    [user@host hello]# mkdir -p src/main/java/org/example/
    [user@host hello]# touch src/main/java/org/example/HelloServlet.java

Remove the ```index.jsp``` file because we're going to use a Servlet instead:

    [user@host hello]# rm -f src/main/webapp/index.jsp

Add the following content to ```HelloServlet.java```:

    // Reflecting the directory structure where the file lives
    package org.example;

    import javax.servlet.http.HttpServlet;
    import javax.servlet.ServletException;
    import javax.servlet.http.HttpServletRequest;
    import javax.servlet.http.HttpServletResponse;

    import java.io.IOException;
    import java.io.PrintWriter;

    public class HelloServlet extends HttpServlet {

        protected void doGet(HttpServletRequest request,
                             HttpServletResponse response) throws ServletException, IOException
        {
            // Very simple - just return some plain text
            PrintWriter writer = response.getWriter();
            writer.print("Hello World");
        }
    }

The code above defines a class which extends the ```HttpServlet``` abstract class and defines a method to run when the server receives a ```GET``` request - the method ```doGet```. All this method does is print some text in the response.

Add the following content to the ```web.xml``` file, under ```src/main/webapp/WEB-INF/```:

    <?xml version="1.0" encoding="UTF-8"?>
    <web-app xmlns="http://java.sun.com/xml/ns/javaee"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://java.sun.com/xml/ns/javaee/web-app_3_0.xsd"
      version="3.0"> 

        <display-name>Hello World Web Application</display-name>

        <servlet>
            <servlet-name>HelloServlet</servlet-name>
            <servlet-class>org.example.HelloServlet</servlet-class>
        </servlet>

        <servlet-mapping>
            <servlet-name>HelloServlet</servlet-name>
            <url-pattern>/</url-pattern>
        </servlet-mapping>

    </web-app>

The XML config above tells the servlet container - Tomcat, in this case - that requests to the URL ```/``` will be handled by an instance of our servlet class.

## Building and Deploying the Application

We need to tell Maven that our application depends on the classes in the Java servlet API. The servlet api JAR is included in the Tomcat installation so it doesn't need to be bundled in the WAR file, however it is required for compiling the classes. The following dependency needs to be added to the pom.xml - there should already be a ```dependencies``` tag so add the new ```dependency``` tag inside that:

    <dependencies>
        ...
        <dependency>
            <groupId>javax.servlet</groupId>
            <artifactId>javax.servlet-api</artifactId>
            <version>3.0.1</version>
            <scope>provided</scope>
        </dependency>
    </dependencies>

The ```scope``` tells Maven that it is already provided so doesn't need to be included.

In the ```hello``` directory in the workspace run the following commands:

 - This compiles the Java classes and puts them into a WAR file.

    ```mvn package```

 - This copies the newly created WAR file to the Tomcat webapps folder where it'll be picked up.

    ```sudo cp target/hello.war /var/lib/tomcat7/webapps/```

In the default install of Tomcat 7 on Ubuntu this is all that's required to get the servlet container to pick up the WAR and register it as an application. To force the service to restart and pick up any new webapps just run: ```sudo service tomcat7 restart```. While the service is starting up you can follow the log to check for problems:

    tail -f /var/lib/tomcat7/logs/catalina.out

### Getting a Response

Once the server has picked up the WAR without any errors the application can be accessed by hitting the local IP address on the appropriate port and including the webapp (the name of the WAR file) in the URL:

    [user@host ~]# curl -D - http://127.0.0.1:8080/hello/
    HTTP/1.1 200 OK
    Server: Apache-Coyote/1.1
    Content-Length: 11
    Date: Tue, 18 Jun 2013 07:12:13 GMT

    Hello World

The port that Tomcat listens on is configured in the ```server.xml``` under the installation directory (/etc/tomcat7/server.xml in this case) and in the default installation in Ubuntu it's port 8080.

### Limitations

This servlet doesn't know about the URL at all so we can hit anything under '```/```' and it'll respond in exactly the same way:

    [user@host ~]# curl -D - http://127.0.0.1:8080/hello/what/the/hell/is/this?
    HTTP/1.1 200 OK
    Server: Apache-Coyote/1.1
    Content-Length: 11
    Date: Tue, 18 Jun 2013 07:16:35 GMT

    Hello World
