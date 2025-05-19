#!/bin/bash

# Default values for variables (optional)
DB_HOST=""
DB_PORT=""
DB_USER=""
DB_NAME=""

# Function to display usage
usage() {
    echo "Usage: $0 -h <host> -p <port> -U <user> -d <database>"
    exit 1
}

# Parse command-line arguments using getopts
while getopts "h:p:U:d:" opt; do
    case $opt in
        h) DB_HOST="$OPTARG" ;;
        p) DB_PORT="$OPTARG" ;;
        U) DB_USER="$OPTARG" ;;
        d) DB_NAME="$OPTARG" ;;
        *) usage ;;
    esac
done

# Ensure all required arguments are provided
if [[ -z "$DB_HOST" || -z "$DB_PORT" || -z "$DB_USER" || -z "$DB_NAME" ]]; then
    usage
fi

# Get the current date for the filename
CURRENT_DATE=$(date +%Y-%m-%d)

# Define output file for the report
OUTPUT_FILE="/home/ubuntu/healthcheck_html/report/db_healthcheck_report_${DB_NAME}_${CURRENT_DATE}.html"

# Start writing the report with PostgreSQL color theme and minimalistic styles
echo '<!DOCTYPE html>
<html>
<head>
    <title>PostgreSQL Health Check Report</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f0f8ff;
            color: #003366;
            margin: 0;
            padding: 20px;
        }
        h1, h2 {
            color: #00509e;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 20px 0;
            background-color: #ffffff;
            box-shadow: 0px 4px 6px rgba(0, 0, 0, 0.1);
        }
        table th, table td {
            border: 1px solid #ddd;
            text-align: left;
            padding: 10px;
        }
        table th {
            background-color: #007acc;
            color: white;
        }
        table tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        table tr:hover {
            background-color: #d9edf7;
        }
        footer {
            text-align: center;
            margin-top: 20px;
            color: #666;
        }
    </style>
</head>
<body>
    <h1>PostgreSQL Health Check Report for Database '"${DB_NAME}"' at '"${DB_HOST}"'</h1>
    <hr>
    <p>Report generated on: '"$(date)"'</p>' > $OUTPUT_FILE

# Run each query and append its output to the report
echo "<h2>Database Uptime</h2>" >> $OUTPUT_FILE
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT date_trunc('second', current_timestamp - pg_postmaster_start_time()) AS db_uptime;" \
    -H >> $OUTPUT_FILE

echo "<h2>Is Database in Recovery?</h2>" >> $OUTPUT_FILE
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT * FROM pg_is_in_recovery();" \
    -H >> $OUTPUT_FILE

echo "<h2>Client Connections</h2>" >> $OUTPUT_FILE
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT client_addr, usename, datname, state, count(*) FROM pg_stat_activity GROUP BY 1, 2, 3, 4 ORDER BY 5 DESC;" \
    -H >> $OUTPUT_FILE

echo "<h2>Total Connections</h2>" >> $OUTPUT_FILE
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT count(*) FROM pg_stat_activity;" \
    -H >> $OUTPUT_FILE

echo "<h2>Max Connections</h2>" >> $OUTPUT_FILE
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SHOW max_connections;" \
    -H >> $OUTPUT_FILE

echo "<h2>Replication Status</h2>" >> $OUTPUT_FILE
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT * FROM pg_stat_replication;" \
    -H >> $OUTPUT_FILE

echo "<h2>Dead Tuples and Auto-Vacuum</h2>" >> $OUTPUT_FILE
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT schemaname, relname, last_autoanalyze, n_live_tup, n_dead_tup, last_vacuum, last_autovacuum FROM pg_stat_user_tables ORDER BY n_dead_tup DESC LIMIT 10;" \
    -H >> $OUTPUT_FILE

echo "<h2>Blocked and Locking Processes</h2>" >> $OUTPUT_FILE
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
    SELECT blocked_locks.pid     AS blocked_pid,
           blocked_activity.usename  AS blocked_user,
           blocking_locks.pid     AS blocking_pid,
           blocking_activity.usename AS blocking_user,
           blocked_activity.query    AS blocked_statement,
           blocking_activity.query   AS current_statement_in_blocking_process,
           blocked_activity.application_name AS blocked_application,
           blocking_activity.application_name AS blocking_application
    FROM  pg_catalog.pg_locks         blocked_locks
          JOIN pg_catalog.pg_stat_activity blocked_activity  ON blocked_activity.pid = blocked_locks.pid
          JOIN pg_catalog.pg_locks         blocking_locks
              ON blocking_locks.locktype = blocked_locks.locktype
              AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
              AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
              AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
              AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
              AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
              AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
              AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
              AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
              AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
              AND blocking_locks.pid != blocked_locks.pid
          JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
    WHERE NOT blocked_locks.GRANTED;" \
    -H >> $OUTPUT_FILE

echo "<h2>Port Configuration</h2>" >> $OUTPUT_FILE
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SHOW port;" \
    -H >> $OUTPUT_FILE

echo "<h2>System Details</h2>" >> $OUTPUT_FILE
echo "<pre>$(date)</pre>" >> $OUTPUT_FILE
echo "<pre>$(hostname -f)</pre>" >> $OUTPUT_FILE

echo '<footer>
    <p>Generated by PostgreSQL Healthcheck Report Script - Telkomsigma</p>
</footer>
</body>
</html>' >> $OUTPUT_FILE

echo "Healthcheck Database '"${DB_NAME}"' at '"${DB_HOST}"' generate"
