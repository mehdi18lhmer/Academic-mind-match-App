# PostgreSQL Database Connection Information

## Available Environment Variables

Your MindMatch application has access to these PostgreSQL environment variables:

- **PGDATABASE** - Database name
- **PGHOST** - Database host/server
- **PGPORT** - Database port (usually 5432)
- **PGUSER** - Database username
- **PGPASSWORD** - Database password
- **DATABASE_URL** - Complete connection string

## Connection Methods

### Method 1: Using Individual Variables
```typescript
// In your db.ts file
export const pool = new Pool({
  host: process.env.PGHOST,
  port: parseInt(process.env.PGPORT || '5432'),
  database: process.env.PGDATABASE,
  user: process.env.PGUSER,
  password: process.env.PGPASSWORD,
  ssl: false
});
```

### Method 2: Using DATABASE_URL (Current Method)
```typescript
// Current configuration in db.ts
export const pool = new Pool({ 
  connectionString: process.env.DATABASE_URL,
  ssl: false
});
```

### Method 3: Python Connection Using Individual Variables
```python
# In python_db_connection.py
import psycopg2

connection = psycopg2.connect(
    host=os.getenv('PGHOST'),
    port=os.getenv('PGPORT', '5432'),
    database=os.getenv('PGDATABASE'),
    user=os.getenv('PGUSER'),
    password=os.getenv('PGPASSWORD')
)
```

## VS Code SQLTools Configuration

### Using Individual Variables
```json
{
  "sqltools.connections": [
    {
      "name": "MindMatch PostgreSQL",
      "driver": "PostgreSQL",
      "server": "${env:PGHOST}",
      "port": "${env:PGPORT}",
      "database": "${env:PGDATABASE}",
      "username": "${env:PGUSER}",
      "password": "${env:PGPASSWORD}",
      "previewLimit": 50
    }
  ]
}
```

## pgAdmin Connection

You can use these variables to connect with pgAdmin:
- **Host**: Value of PGHOST
- **Port**: Value of PGPORT  
- **Database**: Value of PGDATABASE
- **Username**: Value of PGUSER
- **Password**: Value of PGPASSWORD

## Command Line Access

### Using psql with individual variables:
```bash
psql -h $PGHOST -p $PGPORT -d $PGDATABASE -U $PGUSER
```

### Using psql with DATABASE_URL:
```bash
psql $DATABASE_URL
```

## Environment File (.env) Example

If you want to create a local .env file:
```bash
PGHOST=your_host
PGPORT=5432
PGDATABASE=your_database_name
PGUSER=your_username
PGPASSWORD=your_password
DATABASE_URL=postgresql://username:password@host:port/database
```

## Current Status

Your MindMatch application is currently using the DATABASE_URL method, which works perfectly. Both methods will connect to the same PostgreSQL database - choose whichever you prefer for your development workflow.

## For VS Code Database Extension

To connect VS Code to your database using these variables:

1. Install SQLTools extension
2. Install SQLTools PostgreSQL driver
3. Create new connection using the individual variables shown above
4. Test connection to verify access

This gives you direct database access from within VS Code for queries, table browsing, and database management.