# Move data from LIBRUS to OFFICE365
Script helps school administrator to copy all classes and users to office365 environment

# USAGE
1. edit config.js with valid login, password and domain to Microsoft Azure AD.
2. change runscript to one in scripts folder (without .ps1)

to run script use command:
```sh
$ npm run start
```

# Scripts

  - add_users - parse csv from export folder, create new user accounts and enroll users to groups
  - purge_calendar - Delete all meetings from calendar
  - addClasses - parse csv from export folder and create new groups

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
 - check if users exists, then unroll from all groups and add new groups
 - check if group exists and purge canals

License
----

MIT
