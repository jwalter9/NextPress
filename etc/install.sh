#!/bin/bash
# 
#  NextPress Installer
#  Copyright (C) 2017 Lowadobe Web Services, LLC 
#  web: http://nextpress.org/
#  email: lowadobe@gmail.com
#

cd ../db/udf
echo "Compiling the NextPress MySQL UDF library"
make

if test $? -ne 0; then
	echo "ERROR: You need libmysqlclient and libesmtp installed "
	echo "to be able to compile this UDF, on Debian/Ubuntu just run:"
	echo "apt-get install libmysqlclient-dev libesmtp-dev"
	exit 1
else
	echo "MySQL UDF compiled successfully"
fi

echo "Installing the NextPress MySQL UDF library"
make install
/etc/init.d/mysql restart

if test $? -ne 0; then
	echo "ERROR: Could not copy lib_mysqludf_nextpress.so to plugin directory"
	exit 1
else
	echo "MySQL UDF installed successfully"
fi

echo
echo -n "Please provide your MySQL root password: "
read RPWD

mysql -u root --password="$RPWD" mysql < lib_mysqludf_nextpress.sql

if test $? -ne 0; then
	echo "ERROR: unable to install the UDF"
	exit 1
else
	echo "MySQL UDF installed successfully"
fi

cd ..
mysql -u root --password="$RPWD" mysql < nextSetup.sql
if test $? -ne 0; then
	echo "ERROR: unable to set up databases/users (nextSetup.sql)"
	exit 1
else
	echo "NextPress databases/users successfully set up"
fi

mysql -u root --password="$RPWD" nextData < nextData.sql
if test $? -ne 0; then
	echo "ERROR: unable to install data model (nextData.sql)"
	exit 1
else
	echo "NextPress data model successfully installed"
fi

mysql -u root --password="$RPWD" nextData < nextRestricted.sql
if test $? -ne 0; then
	echo "ERROR: unable to install restricted functions (nextRestricted.sql)"
	exit 1
else
	echo "NextPress restricted functions successfully installed"
fi

mysql -u root --password="$RPWD" nextPublic < nextPublic.sql
if test $? -ne 0; then
	echo "ERROR: unable to install public procedures (nextPublic.sql)"
	exit 1
else
	echo "NextPress public procedures successfully installed"
fi

mysql -u root --password="$RPWD" nextAdmin < nextAdmin.sql
if test $? -ne 0; then
	echo "ERROR: unable to install admin procedures (nextAdmin.sql)"
	exit 1
else
	echo "NextPress admin procedures successfully installed"
fi

echo
echo -n " Site Admin email: "
read EML

echo
echo -n " Site Admin password: "
read PAS

mysql -u root --password="$RPWD" -e "UPDATE nextData.users SET email='$EML',password=SHA2('$PAS', 512) WHERE displayName='Administrator';"
if test $? -ne 0; then
	echo "ERROR: unable to update admin email and password - nextData.users"
	exit 1
else
	echo "NextPress Administrator data successfully updated"
fi

mkdir /var/nextpress
cd ../www
cp -R public /var/nextpress/
if test $? -ne 0; then
	echo "ERROR: unable to copy www/public to /var/www"
else
	echo "NextPress web root successfully installed"
fi

cp -R templates /var/nextpress/
if test $? -ne 0; then
	echo "ERROR: unable to copy www/templates to /var/www"
else
	echo "NextPress web templates successfully installed"
fi

chown -R mysql /var/nextpress/public/media
chmod -R a+rX /var/nextpress

cd ../etc
cp next.cnf /etc/mysql/conf.d/
if test $? -ne 0; then
	echo "ERROR: unable to copy etc/next.cnf to /etc/mysql/conf.d"
else
	echo "NextPress web access successfully installed"
fi

cp nextsudo /etc/sudoers.d/
if test $? -ne 0; then
	echo "ERROR: unable to copy etc/nextsudo to /etc/sudoers.d"
else
	echo "NextPress apache reload permission successfully installed"
fi
chmod 0440 /etc/sudoers.d/nextsudo

echo
cp nextPublic.conf /etc/apache2/sites-available/
if test $? -ne 0; then
	echo "ERROR: unable to copy etc/nextPublic.conf to /etc/apache2/sites-available"
else
	echo "NextPress Public Site Config should be reviewed/edited before activation:"
	echo "  /etc/apache2/sites-available/nextPublic.conf"
fi

cp nextAdmin.conf /etc/apache2/sites-available/
if test $? -ne 0; then
	echo "ERROR: unable to copy etc/nextAdmin.conf to /etc/apache2/sites-available"
else
	echo "NextPress Admin Site Config should be reviewed/edited before activation:"
	echo "  /etc/apache2/sites-available/nextAdmin.conf"
fi


if test -f "/etc/apparmor.d/local/usr.sbin.mysqld"; then
    echo "Adding apparmor permissions"
    cat nextapparmor >> /etc/apparmor.d/local/usr.sbin.mysqld
    /sbin/apparmor_parser -r /etc/apparmor.d/usr.sbin.mysqld
else
    echo "If SELinux is installed (and not turned off),"
    echo "make sure to use audit2allow to create a profile,"
    echo "then install the new policy for mysqld."
fi

