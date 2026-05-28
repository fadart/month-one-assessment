#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
echo "<html>
  <head><title>TechCorp Web Server</title></head>
  <body>
    <h1>TechCorp Web Application</h1>
    <p>Server Instance ID: <strong>${INSTANCE_ID}</strong></p>
    <p>Status: Running</p>
  </body>
</html>" > /var/www/html/index.html