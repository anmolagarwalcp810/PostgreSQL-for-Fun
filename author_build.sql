DROP TABLE IF EXISTS authordetails, paperdetails, authorpaperlist, citationlist;

CREATE TABLE authordetails (
	authorid int NOT NULL PRIMARY KEY,
	authorname text,
	city text,
	gender text,
	age int
);

CREATE TABLE paperdetails (
	paperid int NOT NULL PRIMARY KEY,
	papername text,
	conferencename text,
	score int
);

CREATE TABLE authorpaperlist (
	authorid INT NOT NULL,
	paperid INT NOT NULL,
	PRIMARY KEY (authorid,paperid)
);

CREATE TABLE citationlist (
	paperid1 INT NOT NULL,
	paperid2 INT NOT NULL,
	PRIMARY KEY (paperid1, paperid2)
);

\copy authordetails from '/home/anmol/IITD/Semester_6/COL362/A2/authordetails.csv' delimiter ',' csv header;
\copy paperdetails from '/home/anmol/IITD/Semester_6/COL362/A2/paperdetails.csv' delimiter ',' csv header;
\copy authorpaperlist from '/home/anmol/IITD/Semester_6/COL362/A2/authorpaperlist.csv' delimiter ',' csv header;
\copy citationlist from '/home/anmol/IITD/Semester_6/COL362/A2/citationlist.csv' delimiter ',' csv header;

