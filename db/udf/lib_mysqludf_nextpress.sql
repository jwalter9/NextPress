-- 
--  NextPress UDF install script
--  Copyright (C) 2017 Lowadobe Web Services, LLC 
--  web: http://nextpress.org/
--  email: lowadobe@gmail.com
--

DROP FUNCTION IF EXISTS convert_img;
DROP FUNCTION IF EXISTS emailer;
DROP FUNCTION IF EXISTS is_email;
DROP FUNCTION IF EXISTS file_copy;
DROP FUNCTION IF EXISTS tpl_list;

CREATE FUNCTION convert_img RETURNS INT SONAME 'lib_mysqludf_nextpress.so';
CREATE FUNCTION emailer RETURNS INT SONAME 'lib_mysqludf_nextpress.so';
CREATE FUNCTION is_email RETURNS INT SONAME 'lib_mysqludf_nextpress.so';
CREATE FUNCTION file_copy RETURNS INT SONAME 'lib_mysqludf_nextpress.so';
CREATE FUNCTION tpl_list RETURNS STRING SONAME 'lib_mysqludf_nextpress.so';

