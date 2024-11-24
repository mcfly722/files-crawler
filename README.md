## Files Crawler
![Status: not ready yet](https://img.shields.io/badge/notReady-red.svg)
![version](https://img.shields.io/badge/version-1.1-red)
[![License: GPL3.0](https://img.shields.io/badge/License-GPL3.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.html)

## Problem
Some big companies have deployed Distributed File Systems, which has thousands of file servers.
All this files should be checked for viruses and threats by some products. For this, you have to collect information about this files and update it continuously.
This script helps you to collect this information and store it in a MySQL database.

Used <a href="https://en.wikipedia.org/wiki/Breadth-first_search">BFS (breadth-first search)</a> method, so it gives some advantages:
1) Scripts could be stopped at any time and restarted, and it continues to work for the stopped state without any state loss
2) Scripts can be run in parallel in several threads<br>
But:
3) If the parent folder has been deleted, all child objects would be marked as deleted only during their review (not immediately, as it is in DFS when you use the recursive function from parent to all childs)

### Requirements
#### 1. MySQL Server 8.0 (https://dev.mysql.com/downloads/)
#### 2. My SQL Connector 8.0.21 (https://dev.mysql.com/downloads/connector/net/)
Versions over 8.0.21 requires additional Google.Protobuf assembly.
#### 3. SimplySQL 2.0.4.75 (https://www.powershellgallery.com/packages/SimplySql/2.0.4.75)
```
Install-Module -Name SimplySql
```
#### 3. MySQL Workbench 8.0 CE (optional)

### Installation
#### 1. Apply database.sql to your SQL Instance to create 'crawler' database with all required objects.
#### 2. Specify MySQL connection server credentials in **dbConnectionString** file:
```
echo 'Server=localhost;Database=files;User ID=<user name>;Password=<password>' > dbConnectionString
```

