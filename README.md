# Database Project

## Overview
This project sets up a PostgreSQL database using Docker and implements various database functionalities for analytical and operational purposes. The database is initialized with the Northwind dataset, and two main projects are included:

1. **Project 01 - Materialized View for Sales Aggregation**
2. **Project 02 - Employee Snapshot for Historical Tracking**

## Technologies Used
- **PostgreSQL** (latest version via Docker)
- **PgAdmin4** for database management
- **PL/pgSQL** for stored procedures, triggers, and functions
- **Docker Compose** for environment setup

## Setup Instructions

### Prerequisites
Ensure you have Docker and Docker Compose installed on your machine.

### Steps to Run
1. Clone this repository.
2. Navigate to the project directory.
3. Run the following command to start the services:
   ```sh
   docker-compose up -d
   ```
4. Access PgAdmin4 at `http://localhost:5050/` with:
   - **Email:** `pgadmin4@pgadmin.org`
   - **Password:** `admin`
5. Connect to the PostgreSQL database using the following credentials:
   - **Host:** `db`
   - **Database:** `northwind`
   - **User:** `postgres`
   - **Password:** `postgres`
   - **Port:** `55432`

## Project 01: Sales Aggregation
This project creates a materialized view for aggregated sales data and sets up triggers to refresh it automatically.

### Key Components:
- **Materialized View (`bi_analytics_aggregate_sales`)**: Aggregates sales data monthly.
- **Function (`func_refresh_sales_accumulated_monthly_mv`)**: Refreshes the materialized view.
- **Triggers:** Automatically refreshes the view on insert, update, or delete operations in `orders` or `order_details`.

### Testing:
You can test the triggers by inserting new orders and order details, then querying the `bi_analytics_aggregate_sales` view.

## Project 02: Employee Snapshot
This project tracks historical changes in the `employees` table, maintaining a snapshot with validity periods.

### Key Components:
- **Snapshot Table (`snapshot_employees`)**: Stores employee records with `valid_from` and `valid_to` timestamps.
- **Function (`func_snapshot`)**: Handles inserts, updates, and deletions.
- **Trigger (`trg_emp_table_modification`)**: Automatically updates the snapshot table when changes occur in `employees`.
- **Stored Procedure (`update_employee_title`)**: Updates an employee's title.

### Testing:
- Insert, update, and delete employees in `employees`, then query `snapshot_employees`.
- Call the stored procedure:
  ```sql
  CALL update_employee_title(1, 'Intern');
  ```

## Directory Structure
```
project-root/
├── docker-compose.yml
├── northwind.sql  # Database initialization script
├── files/  # Additional resources
└── README.md  # This file
```

## Stopping and Cleaning Up
To stop the services, run:
```sh
docker-compose down
```

To remove containers, volumes, and networks, run:
```sh
docker-compose down --volumes --remove-orphans
```

## License
This project is licensed under the MIT License.

