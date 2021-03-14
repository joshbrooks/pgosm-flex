#!/bin/bash
# Run with:  
#   ./run_pgosm_flex.sh \
#       north-america/us \
#       district-of-columbia \
#       4000 \
#       run-all
#
# $1 - Region - e.g. north-america/us
# $2 - Subregion - e.g. district-of-columbia 
# $3 - Cache (mb) - e.g. 4000
# $4 - Layers to load - must match flex-config/$4.lua and flex-config/$4.sql

BASE_PATH=/app/
SQITCH_PATH=/app/db/
OUT_PATH=/app/output/
FLEX_PATH=/app/flex-config

LOG_FILE=$OUT_PATH$2.log

echo "Monitor $LOG_FILE for progress..."
echo "If paths setup as outlined in README.md, use:"
echo "    tail -f ~/pgosm-data/$2.log"

echo "" >> $LOG_FILE
echo "---------------------------------" >> $LOG_FILE
echo "Start PgOSM-Flex processing" >> $LOG_FILE
echo "Region:  $1" >> $LOG_FILE
echo "Sub-Region:  $2" >> $LOG_FILE
echo "Cache: $3" >> $LOG_FILE
echo "PgOSM Flex Style: $4" >> $LOG_FILE


# Naming scheme must match Geofabrik's for MD5 sums to validatate
PBF_FILE=$OUT_PATH$2-latest.osm.pbf
MD5_FILE=$OUT_PATH$2-latest.osm.pbf.md5


if [ -z $PGOSM_DATE ]; then
  PGOSM_DATE=$(date '+%Y-%m-%d')
fi

if [ $PGOSM_DATE == $(date '+%Y-%m-%d') ]; then
  PGOSM_DATE_TODAY=true
else
  PGOSM_DATE_TODAY=false
fi

echo "PGOSM_DATE: $PGOSM_DATE (Today? $PGOSM_DATE_TODAY)" >> $LOG_FILE

# Filenames with the PgOSM Date
PBF_DATE_FILE=$OUT_PATH$2-$PGOSM_DATE.osm.pbf
MD5_DATE_FILE=$OUT_PATH$2-$PGOSM_DATE.osm.pbf.md5


ALWAYS_DOWNLOAD=${PGOSM_ALWAYS_DOWNLOAD:-0}

if [ $ALWAYS_DOWNLOAD == "1" ] && [ $PGOSM_DATE_TODAY == true ]; then
  echo 'Removing PBF and md5 files if exists...' >> $LOG_FILE
  BE_NICE='NOTE: Be nice to Geofabrik''s download server!'
  echo "$BE_NICE" >> $LOG_FILE
  echo "$BE_NICE"
  rm $PBF_DATE_FILE
  rm $MD5_DATE_FILE
fi

# Download file only if the file (with date) does not exist && historic date not selected.
# Historic date obviously requires having that date's files available.
# This is not a time machine
if [ -f $PBF_DATE_FILE ]; then
    echo "$PBF_DATE_FILE exists. Copying to $PBF_FILE"  >> $LOG_FILE
    cp $PBF_DATE_FILE $PBF_FILE
elif [ $PGOSM_DATE_TODAY == false ]; then
  ERR_MSG='ERROR - Historic date selected but file does not exist.  Ensure the file $PBF_DATE_FILE exists'
  echo $ERR_MSG
  echo $ERR_MSG >> $LOG_FILE
  exit 1
else 
    echo "$PBF_DATE_FILE does not exist.  Downloading... $PBF_FILE"  >> $LOG_FILE
    wget https://download.geofabrik.de/$1/$2-latest.osm.pbf -O $PBF_FILE --quiet &>> $LOG_FILE
fi


if [ -f $MD5_DATE_FILE ]; then
  echo "$MD5_DATE_FILE exists. Copying to $MD5_FILE"  >> $LOG_FILE
  cp $MD5_DATE_FILE $MD5_FILE
elif [ $PGOSM_DATE_TODAY == false ]; then
  ERR_MSG='ERROR - Historic date selected but MD5 file does not exist. Ensure the file $MD5_DATE_FILE exists'
  echo $ERR_MSG
  echo $ERR_MSG >> $LOG_FILE
  exit 1
else
  echo "$MD5_DATE_FILE does not exist.  Downloading... $MD5_FILE" >> $LOG_FILE
  wget https://download.geofabrik.de/$1/$2-latest.osm.pbf.md5 -O $MD5_FILE --quiet &>> $LOG_FILE
fi


# Runtime config to override default data schema name
if [ -z $PGOSM_DATA_SCHEMA_NAME ]; then
  echo "PGOSM_DATA_SCHEMA_NAME NOT SET"
  DATA_SCHEMA_NAME="osm"
else
  DATA_SCHEMA_NAME=$PGOSM_DATA_SCHEMA_NAME
  echo "DATA_SCHEMA_NAME set to $DATA_SCHEMA_NAME"
fi


# Runtime config to only export the data schema.
if [ -z $PGOSM_DATA_SCHEMA_ONLY ]; then
  echo "DATA_SCHEMA_ONLY NOT SET"
  DATA_SCHEMA_ONLY=false
else
  DATA_SCHEMA_ONLY=$PGOSM_DATA_SCHEMA_ONLY
  echo "DATA_SCHEMA_ONLY set to $DATA_SCHEMA_ONLY"
fi


if cd $OUT_PATH && md5sum -c $MD5_FILE; then
    echo 'MD5 checksum validated' >> $LOG_FILE
else
    ERR_MSG = 'ERROR - MD5 sum did not match.  Try re-running with PGOSM_ALWAYS_DOWNLOAD=1'
    echo "$ERR_MSG" >> $LOG_FILE
    echo "$ERR_MSG"
    exit 1
fi

SLEEP_SEC=5

function wait_postgres_is_up {
  # Initial Sleep
  echo 'Pause to ensure Postgres instance is up and ready' >> $LOG_FILE
  sleep 10

  # Does two check cycles w/ break in between to avoid false positive
  echo 'Now checking...'
  until pg_isready; do
    sleep $SLEEP_SEC
  done

  echo 'Postgres detected once, pausing before double check' >> $LOG_FILE
  sleep $SLEEP_SEC

  until pg_isready; do
    sleep $SLEEP_SEC
  done

  echo 'Postgres service should be reliably available now' >> $LOG_FILE
}


wait_postgres_is_up


echo "Database passed two checks - should be ready!" >> $LOG_FILE

echo "Create empty pgosm database with extensions..." >> $LOG_FILE
psql -U postgres -c "DROP DATABASE IF EXISTS pgosm;" >> $LOG_FILE
psql -U postgres -c "CREATE DATABASE pgosm;" >> $LOG_FILE
psql -U postgres -d pgosm -c "CREATE EXTENSION postgis;" >> $LOG_FILE
psql -U postgres -d pgosm -c "CREATE SCHEMA osm;" >> $LOG_FILE

echo "Deploy schema via Sqitch..." >> $LOG_FILE
cd $SQITCH_PATH
su -c "sqitch deploy db:pg:pgosm" postgres >> $LOG_FILE
echo "Loading US Roads helper data" >> $LOG_FILE
psql -U postgres -d pgosm -f data/roads-us.sql >> $LOG_FILE


REGION="$1--$2"
echo "Setting PGOSM_REGION to $REGION" >> $LOG_FILE
export PGOSM_REGION=$REGION

osm2pgsql --version >> $LOG_FILE

echo "Running osm2pgsql..." >> $LOG_FILE
cd $FLEX_PATH
osm2pgsql -U postgres --create --slim --drop \
  --cache $3 \
  --output=flex --style=./$4.lua \
  -d pgosm  $PBF_FILE &>> $LOG_FILE

echo "Running PgOSM-Flex post-processing SQL script: $4.sql" >> $LOG_FILE
psql -U postgres -d pgosm -f $4.sql >> $LOG_FILE


if [ $PGOSM_DATE_TODAY == true ]; then
  echo "Archiving today's PBF and MD5 files..." >> $LOG_FILE
  mv $PBF_FILE $PBF_DATE_FILE
  mv $MD5_FILE $MD5_DATE_FILE
else
  echo "Removing copy of PBF and MD5 files..." >> $LOG_FILE
  rm $PBF_FILE
  rm $MD5_FILE
fi

if [ $DATA_SCHEMA_NAME != "osm" ]; then
    echo "Changing schema name from osm to $DATA_SCHEMA_NAME" >> $LOG_FILE
    psql -U postgres -d pgosm \
      -c "ALTER SCHEMA osm RENAME TO $DATA_SCHEMA_NAME;"
fi

cd $BASE_PATH

OUT_NAME="pgosm-flex-$2-$4.sql"
OUT_PATH="/app/output/$OUT_NAME"

if $DATA_SCHEMA_ONLY; then
  echo "Running pg_dump, only data schema..." >> $LOG_FILE
  pg_dump -U postgres -d pgosm \
     --schema=$DATA_SCHEMA_NAME > $OUT_PATH
else
  echo "Running pg_dump including pgosm schema..." >> $LOG_FILE
  pg_dump -U postgres -d pgosm \
     --schema=$DATA_SCHEMA_NAME --schema=pgosm > $OUT_PATH
fi

echo "PgOSM processing complete. Final output file: $OUT_PATH" >> $LOG_FILE
echo "PgOSM processing complete. Final output file: $OUT_PATH"
echo "If you followed the README.md it is at: ~/pgosm-data/$OUT_NAME"

exit 0