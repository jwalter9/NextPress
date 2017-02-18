-- 
--  NextPress UDF install script
--  Copyright (C) 2016 Lowadobe Web Services, LLC 
--  web: http://nextpress.online/
--  email: lowadobe@gmail.com
--

DROP FUNCTION IF EXISTS convert_img;
DROP FUNCTION IF EXISTS emailer;
DROP FUNCTION IF EXISTS is_email;
DROP FUNCTION IF EXISTS file_write;
DROP FUNCTION IF EXISTS file_copy;
DROP FUNCTION IF EXISTS file_delete;
DROP FUNCTION IF EXISTS reload_apache;

CREATE FUNCTION convert_img RETURNS INT SONAME 'lib_mysqludf_nextpress.so';
CREATE FUNCTION emailer RETURNS INT SONAME 'lib_mysqludf_nextpress.so';
CREATE FUNCTION is_email RETURNS INT SONAME 'lib_mysqludf_nextpress.so';
CREATE FUNCTION file_write RETURNS INT SONAME 'lib_mysqludf_nextpress.so';
CREATE FUNCTION file_copy RETURNS INT SONAME 'lib_mysqludf_nextpress.so';
CREATE FUNCTION file_delete RETURNS INT SONAME 'lib_mysqludf_nextpress.so';
CREATE FUNCTION reload_apache RETURNS INT SONAME 'lib_mysqludf_nextpress.so';

