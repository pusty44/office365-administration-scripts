# OFFICE365 administrator tools from schools using librus.pl

to run script use command:
```sh
$ node gen.js username password script domain
```
  - username - MS AD login
  - password - MS AD password
  - script - script name form ./scripts (without .ps1)
  - domain - your microsoft domain e.g. example.com

# Scripts

  - add_users - parse csv from import folder and create new user accounts, new groups and enroll users to groups
  - purge_calendar - Delete all meetings from calendar

# CSV for import markdown:
#### BOLD ARE REQUIRED FIELDS

### Student.csv
**SIS ID**,School SIS ID,Username,**First Name**,**Last Name**,**Password**,State ID,Secondary Email,Student Number,Middle Name,Grade,Status,Mailing Address,Mailing City,Mailing State,Mailing Zip,Mailing Latitude,Mailing Longitude,Mailing Country,Residence Address,Residence City,Residence State,Residence Zip,Residence Latitude,Residence Longitude,Residence Country,Gender,Birthdate,ELL Status,FederalRace,Graduation Year

### Teacher.csv
**SIS ID**,School SIS ID,Username,**First Name**,**Last Name**,**Password**,State ID,Teacher Number,Status,Middle Name,Secondary Email,Title,Qualification

### StudentEnrollment.csv
**Section SIS ID,SIS ID**

### TeacherRoster.csv
**Section SIS ID,SIS ID**

### Sections.csv
**SIS ID**,School SIS ID,**Section Name**,Section Number,Term SIS ID,Term Name,Term StartDate,Term EndDate,Course SIS ID,Course Name,Course Number,Course Description,Course Subject,Periods,Status

### Todos

 - Test script in production enviroment
 - clean code
 - check if users exists, then unroll from all groups and add new groups
 - check if group exists and purge canals

License
----

MIT
