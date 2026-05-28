#!/bin/bash
yum update -y
amazon-linux-extras install postgresql14 -y
yum install -y postgresql-server postgresql-contrib
postgresql-setup initdb
systemctl start postgresql
systemctl enable postgresql

# Allow password authentication
sed -i 's/ident/md5/g' /var/lib/pgsql/data/pg_hba.conf
systemctl restart postgresql

# Create a default database and user
sudo -u postgres psql -c "CREATE USER techcorp WITH PASSWORD 'techcorp123';"
sudo -u postgres psql -c "CREATE DATABASE techcorpdb OWNER techcorp;"