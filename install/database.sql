-- drop TCMDUMP
DROP INDEX element2_idx;
DROP INDEX filename2_idx;
DROP table TCMDUMP;
-- create TCMDUMP
create table TCMDUMP (
    id number,
    element varchar(18),
    seqnum number,
    cdrnum number,
    filename varchar(42),
    fileseq number,
    filedt timestamp,
    loaded timestamp,
    created timestamp default sysdate
); 
CREATE INDEX element2_idx ON TCMDUMP(element);
CREATE INDEX filename2_idx ON TCMDUMP(filename);

-- drop TCMFILE
DROP INDEX element_idx;
DROP INDEX filename_idx;
DROP INDEX filedt_idx;
DROP INDEX created_idx;
DROP sequence TCMFILE_seq;
DROP table TCMFILE;
-- create TCMFILE
create table TCMFILE (
    id number PRIMARY KEY,
    element varchar(18) NOT NULL,
    seqnum number NOT NULL,
    cdrnum number NOT NULL,
    filename varchar(42) NOT NULL,
    fileseq number NOT NULL,
    filedt timestamp NOT NULL,
    loaded timestamp NOT NULL,
    created timestamp default sysdate,
    UNIQUE(element, seqnum, cdrnum, filename),
    UNIQUE(filename, fileseq, filedt)
); 
CREATE INDEX element_idx ON TCMFILE(element);
CREATE INDEX filename_idx ON TCMFILE(filename);
CREATE INDEX filedt_idx ON TCMFILE(filedt);
CREATE INDEX created_idx ON TCMFILE(created);
CREATE sequence TCMFILE_seq;

-- drop TCMSTAT
DROP table TCMSTAT;
-- create TCMSTAT
create table TCMSTAT (
    fid number,
    element varchar(18),
    seqnum number,
    state varchar(16) NOT NULL,
    created timestamp default sysdate,
    UNIQUE(fid, element, seqnum, state)
);

-- drop TCMMARK
DROP INDEX tag_idx;
DROP table TCMMARK;
-- create TCMMARK
create table TCMMARK (
    tag varchar(18) NOT NULL,
    env varchar(6),
    created timestamp default sysdate
);
CREATE INDEX tag_idx ON TCMMARK(tag,env);


-- drop TCMELEMENT
DROP VIEW TCMELEMENT;
-- create TCMELEMENT
CREATE VIEW TCMELEMENT AS 
    SELECT DISTINCT(element) e FROM TCMDUMP WHERE element IS NOT NULL
UNION 
    SELECT DISTINCT(element) e FROM TCMFILE WHERE element IS NOT NULL;
