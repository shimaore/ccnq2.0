-- generic.sql -- SQL tables creation
-- Copyright (C) 2009  Stephane Alnet
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

--
-- Table structure versions
--
-- standard-create.sql
CREATE TABLE version (
    table_name CHAR(32) NOT NULL,
    table_version INT UNSIGNED DEFAULT 0 NOT NULL,
    CONSTRAINT t_name_idx UNIQUE (table_name)
);

-- These tables are updated dynamically (and never provisioned).

--
-- Table structure for table 'location' -- that is persistent UsrLoc
--
-- usrloc-create.sql
INSERT INTO version (table_name, table_version) values ('location','1005');
CREATE TABLE location (
    id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
    username CHAR(64) DEFAULT '' NOT NULL,
    domain CHAR(64) DEFAULT NULL,
    contact CHAR(255) DEFAULT '' NOT NULL,
    received CHAR(128) DEFAULT NULL,
    path CHAR(128) DEFAULT NULL,
    expires DATETIME DEFAULT '2020-05-28 21:32:15' NOT NULL,
    q FLOAT(10,2) DEFAULT 1.0 NOT NULL,
    callid CHAR(255) DEFAULT 'Default-Call-ID' NOT NULL,
    cseq INT(11) DEFAULT 13 NOT NULL,
    last_modified DATETIME DEFAULT '1900-01-01 00:00:01' NOT NULL,
    flags INT(11) DEFAULT 0 NOT NULL,
    cflags INT(11) DEFAULT 0 NOT NULL,
    user_agent CHAR(255) DEFAULT '' NOT NULL,
    socket CHAR(64) DEFAULT NULL,
    methods INT(11) DEFAULT NULL
);

CREATE INDEX account_contact_idx ON location (username, domain, contact);

-- These tables are provisioned.

--
-- Table structure for table 'subscriber' -- user database
--
-- auth_db-create.sql
INSERT INTO version (table_name, table_version) values ('subscriber','7');
CREATE TABLE subscriber (
    id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
    username CHAR(64) DEFAULT '' NOT NULL,
    domain CHAR(64) DEFAULT '' NOT NULL,
    password CHAR(25) DEFAULT '' NOT NULL,
    email_address CHAR(64) DEFAULT '' NOT NULL,
    ha1 CHAR(64) DEFAULT '' NOT NULL,
    ha1b CHAR(64) DEFAULT '' NOT NULL,
    rpid CHAR(64) DEFAULT NULL,
    CONSTRAINT account_idx UNIQUE (username, domain)
);

CREATE INDEX username_idx ON subscriber (username);

--
-- Table structure for table 'aliases' -- location-like table
--
-- alias_db-create.sql
INSERT INTO version (table_name, table_version) values ('aliases','2');
CREATE TABLE aliases (
    id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
    alias_username CHAR(64) DEFAULT '' NOT NULL,
    alias_domain CHAR(64) DEFAULT '' NOT NULL,
    username CHAR(64) DEFAULT '' NOT NULL,
    domain CHAR(64) DEFAULT '' NOT NULL,
    CONSTRAINT alias_idx UNIQUE (alias_username, alias_domain)
);

CREATE INDEX target_idx ON aliases (username, domain);

--
-- Table structure for table 'avpops'
--
-- avpops-create.sql
INSERT INTO version (table_name, table_version) values ('avpops','3');
CREATE TABLE avpops (
    id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
    uuid CHAR(64) DEFAULT '' NOT NULL,
    username CHAR(128) DEFAULT 0 NOT NULL,
    domain CHAR(64) DEFAULT '' NOT NULL,
    attribute CHAR(32) DEFAULT '' NOT NULL,
    type INT(11) DEFAULT 0 NOT NULL,
    value CHAR(128) DEFAULT '' NOT NULL,
    last_modified DATETIME DEFAULT '1900-01-01 00:00:01' NOT NULL
);

CREATE INDEX ua_idx ON avpops (uuid, attribute);
CREATE INDEX uda_idx ON avpops (username, domain, attribute);
CREATE INDEX value_idx ON avpops (value);

--
-- Table structure for table trusted
-- permissions-create.sql
INSERT INTO version (table_name, table_version) values ('trusted','5');
CREATE TABLE trusted (
    id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
    src_ip CHAR(50) NOT NULL,
    proto CHAR(4) NOT NULL,
    from_pattern CHAR(64) DEFAULT NULL,
    tag CHAR(32)
);

CREATE INDEX peer_idx ON trusted (src_ip);

INSERT INTO version (table_name, table_version) values ('address','4');
CREATE TABLE address (
    id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
    grp SMALLINT(5) UNSIGNED DEFAULT 0 NOT NULL,
    ip_addr CHAR(15) NOT NULL,
    mask TINYINT DEFAULT 32 NOT NULL,
    port SMALLINT(5) UNSIGNED DEFAULT 0 NOT NULL
);


--
-- Table structure for table 'domain' -- domains this proxy is responsible for
--
-- domain-create.sql
INSERT INTO version (table_name, table_version) values ('domain','2');
CREATE TABLE domain (
    id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
    domain CHAR(64) DEFAULT '' NOT NULL,
    last_modified DATETIME DEFAULT '1900-01-01 00:00:01' NOT NULL,
    CONSTRAINT domain_idx UNIQUE (domain)
);


-- END
