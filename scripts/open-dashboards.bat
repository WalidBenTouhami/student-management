@echo off
echo Ouverture des pipelines et dashboards du projet DevOps...

start http://api.student.local/student/swagger-ui.html
start http://grafana.student.local
start http://192.168.56.10:8080
start http://192.168.56.10:9000
start http://192.168.56.10:30090

echo Les pages ont ete ouvertes dans votre navigateur par defaut !
timeout /t 5
