# Healthcheck PostgreSQL to Email

A shell-based utility to monitor PostgreSQL database health, generate an HTML report, and send it via email.

## Features

* Collects PostgreSQL health metrics.
* Generates an HTML report.
* Sends the report via email.

## Prerequisites

* Unix-like OS (Linux/macOS)
* Bash shell
* PostgreSQL client utilities (`psql`)
* `sendmail` or equivalent mail transfer agent

## Setup

1. **Clone the Repository**

   ```bash
   git clone https://github.com/Athoillah21/Healthcheck_PostgreSQL_to_Email.git
   cd Healthcheck_PostgreSQL_to_Email
   ```
   
2. **Set Email Parameters**

   Edit `hc_mail.sh` to specify:

   * `EMAIL_TO`: Recipient email address
   * `EMAIL_SUBJECT`: Email subject
   * `EMAIL_BODY`: Email body content

## Usage

1. **Generate HTML Report**

   ```bash
   ./generate_html.sh -h ${server_host} -p ${db_port} -d ${db_name} -U ${db_user}
   ```

   This script connects to the PostgreSQL database, retrieves health metrics, and generates an HTML report saved in the `report/` directory.

2. **Generate HTML Report then Send via Email**

   ```bash
   ./hc_mail.sh -h ${server_host} -p ${db_port} -d ${db_name} -U ${db_user}
   ```

   This script connects to the PostgreSQL database, retrieves health metrics, and generates an HTML report saved in the `report/` directory. Then this script sends the generated HTML report to the specified email address.

## Automation

To automate the health check and email dispatch, add the following to your crontab:

```bash
0 8 * * * /path/to/Healthcheck_PostgreSQL_to_Email/generate_html.sh && /path/to/Healthcheck_PostgreSQL_to_Email/hc_mail.sh
```

This example runs the scripts daily at 8 AM.

## License

This project is licensed under the MIT License.

## Author

Created by [Athoillah21](https://github.com/Athoillah21).
