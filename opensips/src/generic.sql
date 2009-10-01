--
-- Table structure versions
--
CREATE TABLE version (
   table_name varchar(64) NOT NULL PRIMARY KEY,
   table_version smallint(5) DEFAULT '0' NOT NULL
);

INSERT INTO version VALUES ( 'subscriber', '7');
INSERT INTO version VALUES ( 'missed_calls', '3');
INSERT INTO version VALUES ( 'location', '1004');
INSERT INTO version VALUES ( 'aliases', '1004');
INSERT INTO version VALUES ( 'grp', '2');
INSERT INTO version VALUES ( 're_grp', '1');
INSERT INTO version VALUES ( 'acc', '4');
INSERT INTO version VALUES ( 'silo', '5');
INSERT INTO version VALUES ( 'domain', '1');
INSERT INTO version VALUES ( 'uri', '1');
INSERT INTO version VALUES ( 'trusted', '4');
INSERT INTO version VALUES ( 'usr_preferences', '2');
INSERT INTO version VALUES ( 'speed_dial', '2');
INSERT INTO version VALUES ( 'dbaliases', '1');
INSERT INTO version VALUES ( 'gw', '4');
INSERT INTO version VALUES ( 'gw_grp', '1');
INSERT INTO version VALUES ( 'lcr', '2');
INSERT INTO version VALUES ( 'address', '4');

-- These tables are updated dynamically (and never provisioned).

--
-- Table structure for table 'location' -- that is persistent UsrLoc
--
CREATE TABLE location (
  id            int(10) unsigned NOT NULL PRIMARY KEY auto_increment, 
  username      varchar(64) NOT NULL default '',
  domain        varchar(128) NOT NULL default '',
  contact       varchar(255) NOT NULL default '',
  received      varchar(255) default NULL,
  path          varchar(255) default NULL,
  expires       datetime NOT NULL default '2020-05-28 21:32:15',
  q             float(10,2) NOT NULL default '1.0',
  callid        varchar(255) NOT NULL default 'Default-Call-ID',
  cseq          int(11) NOT NULL default '42',
  last_modified datetime NOT NULL default '1900-01-01 00:00',
  flags         int(11) NOT NULL default '0',
  cflags        int(11) NOT NULL default '0',
  user_agent    varchar(255) NOT NULL default '',
  socket        varchar(128) default NULL,
  methods       int(11) default NULL
);

CREATE UNIQUE INDEX key_loc ON location(username, domain);
CREATE INDEX udc_loc ON location(username, domain, contact);

-- These tables are provisioned.

--
-- Table structure for table 'subscriber' -- user database
--
CREATE TABLE subscriber (
  id            int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
  username      varchar(64) NOT NULL default '',
  domain        varchar(128) NOT NULL default '',
  password      varchar(25) NOT NULL default '',
  first_name    varchar(25) NOT NULL default '',
  last_name     varchar(45) NOT NULL default '',
  email_address varchar(50) NOT NULL default '',
  datetime_created datetime NOT NULL default '1900-01-01 00:00:00',
  ha1           varchar(128) NOT NULL default '',
  ha1b          varchar(128) NOT NULL default '',
  timezone      varchar(128) default NULL,
  account       varchar(128) default NULL,
  rpid          varchar(128) default NULL
);

CREATE UNIQUE INDEX user_id ON subscriber(username, domain);

--
-- Table structure for table 'aliases' -- location-like table
--
CREATE TABLE aliases (
  id            int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
  username      varchar(64) NOT NULL default '',
  domain        varchar(128) NOT NULL default '',
  contact       varchar(255) NOT NULL default '',
  received      varchar(255) default NULL,
  path          varchar(255) default NULL,
  expires       datetime NOT NULL default '2020-05-28 21:32:15',
  q             float(10,2) NOT NULL default '1.0',
  callid        varchar(255) NOT NULL default 'Default-Call-ID',
  cseq          int(11) NOT NULL default '42',
  last_modified datetime NOT NULL default '1900-01-01 00:00',
  flags         int(11) NOT NULL default '0',
  cflags        int(11) NOT NULL default '0',
  user_agent    varchar(255) NOT NULL default '',
  socket        varchar(128) default NULL,
  methods       int(11) default NULL
);

CREATE UNIQUE INDEX key_als ON location(username, domain);
CREATE INDEX udc_als ON aliases(username, domain, contact);

--
-- Table structure for table 'avpops'
--
CREATE TABLE avpops (
  id            int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
  uuid          varchar(64) NOT NULL default '',
  username      varchar(128) NOT NULL default '0',
  domain        varchar(128) NOT NULL default '',
  attribute     varchar(32) NOT NULL default '',
  value         varchar(128) NOT NULL default '',
  type          integer NOT NULL default '0',
  last_modified datetime NOT NULL default '1900-01-01 00:00:00'
);
CREATE UNIQUE INDEX key_avp1 ON avpops(attribute,username,domain);
CREATE UNIQUE INDEX key_avp2 ON avpops(attribute,uuid,domain);

--
-- Table structure for table trusted
--
CREATE TABLE trusted (
  id            int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
  src_ip        varchar(39) NOT NULL,
  proto         varchar(4) NOT NULL,
  from_pattern  varchar(64) DEFAULT NULL,
  tag           varchar(32) DEFAULT NULL
);

CREATE INDEX trusted_Key1 ON trusted(src_ip);

--
-- Table structure for table 'domain' -- domains this proxy is responsible for
-- 

CREATE TABLE domain (
  id            int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
  domain        varchar(128) NOT NULL default '',
  last_modified datetime NOT NULL default '1900-01-01 00:00:00'
);

--
-- Table structure for table 'address'
--
CREATE TABLE address (
  id            int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
  grp           smallint(5) unsigned NOT NULL default '0',
  ip_addr       varchar(15) NOT NULL,
  mask          varchar(2) NOT NULL default 32,
  port          smallint(5) unsigned NOT NULL default '0'
);


-- END
