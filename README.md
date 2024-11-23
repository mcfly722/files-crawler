## Files Crawler
Collects information about local files and store it in MySQL database.

### Requirements
#### 1. MySQL Server 8.0 https://dev.mysql.com/downloads/
#### 2. My SQL Connector 8.0.21 (https://dev.mysql.com/downloads/connector/net/)
Versions over 8.0.21 requires additional Google.Protobuf assembly.
#### 3. MySQL Workbench 8.0 CE (optional)

### Installation
#### 1. Apply database.sql to your SQL Instance to create 'crawler' database with all required objects.
#### 2. Specify MySQL connection server credentials in **dbConnectionString** file:
```
echo 'Server=localhost;Database=files;User ID=<user name>;Password=<password>' > dbConnectionString
```
