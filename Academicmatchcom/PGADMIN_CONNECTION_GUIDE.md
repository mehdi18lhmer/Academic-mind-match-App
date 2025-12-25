# pgAdmin Database Connection Guide

This guide will help you connect your MindMatch PostgreSQL database to pgAdmin for database management and administration.

## Database Connection Information

Your MindMatch application uses a PostgreSQL database hosted on Neon. Here are the connection details:

### Connection Details
- **Host**: Available in `PGHOST` environment variable
- **Port**: Available in `PGPORT` environment variable (usually 5432)
- **Database**: Available in `PGDATABASE` environment variable
- **Username**: Available in `PGUSER` environment variable
- **Password**: Available in `PGPASSWORD` environment variable
- **SSL Mode**: Required (Neon requires SSL connections)

## Step-by-Step Connection Guide

### Step 1: Install pgAdmin
1. Download pgAdmin from: https://www.pgadmin.org/download/
2. Install pgAdmin on your local machine
3. Launch pgAdmin

### Step 2: Get Database Connection Details
The connection details are stored in environment variables. You can view them using:

```bash
# View all database connection info
echo "Host: $PGHOST"
echo "Port: $PGPORT" 
echo "Database: $PGDATABASE"
echo "Username: $PGUSER"
echo "Password: $PGPASSWORD"
```

Or check the full DATABASE_URL:
```bash
echo $DATABASE_URL
```

### Step 3: Create New Server Connection in pgAdmin

1. **Open pgAdmin** and right-click on "Servers" in the left panel
2. **Select "Register" > "Server..."**
3. **Fill in the General tab:**
   - Name: `MindMatch Database` (or any name you prefer)

4. **Fill in the Connection tab:**
   - Host name/address: `[Value from PGHOST]`
   - Port: `[Value from PGPORT]` (usually 5432)
   - Maintenance database: `[Value from PGDATABASE]`
   - Username: `[Value from PGUSER]`
   - Password: `[Value from PGPASSWORD]`
   - Save password: ✓ (check this box)

5. **Fill in the SSL tab:**
   - SSL mode: `Require`
   - (Neon requires SSL connections)

6. **Click "Save"**

### Step 4: Alternative Connection Methods

#### Method 1: Using DATABASE_URL directly
If you have the full DATABASE_URL, you can parse it:
```
postgresql://[username]:[password]@[host]:[port]/[database]?sslmode=require
```

#### Method 2: Using Neon Dashboard
1. Go to your Neon dashboard: https://console.neon.tech/
2. Navigate to your project
3. Go to "Connection Details"
4. Copy the connection parameters directly

### Step 5: Verify Connection

Once connected, you should see:
- **Database**: Your MindMatch database
- **Schemas**: `public` schema with all tables
- **Tables**: Including users, projects, skills, interests, etc.

## Database Schema Overview

Your MindMatch database includes these main tables:

### Core Tables
- `users` - User accounts with inheritance support
- `students` - Student-specific information
- `professors` - Professor-specific information  
- `profiles` - Extended user profile data
- `projects` - Project information
- `skills` - Available skills
- `interests` - Available interests

### Relationship Tables
- `user_skills` - User skill assignments
- `user_interests` - User interest assignments
- `team_members` - Project team memberships
- `matches` - User-project compatibility matches
- `endorsements` - Skill endorsements between users

### Communication Tables
- `conversations` - Chat conversations
- `messages` - Individual messages
- `notifications` - User notifications

### Analytics Tables
- `compliance` - Project compliance tracking
- `audit_logs` - System audit trail

## Useful pgAdmin Features

### 1. Query Tool
- Right-click on database → "Query Tool"
- Run SQL queries directly
- View query results and execution plans

### 2. Table Management
- View table structure and data
- Edit data directly in the interface
- Create/modify indexes and constraints

### 3. Database Monitoring
- Monitor active connections
- View database statistics
- Analyze query performance

### 4. Backup and Restore
- Create database backups
- Restore from backup files
- Schedule automated backups

## Common Queries for MindMatch

Here are some useful queries you can run in pgAdmin:

```sql
-- View all users with their profiles
SELECT u.username, u.email, p.first_name, p.last_name, p.department
FROM users u
LEFT JOIN profiles p ON u.id = p.user_id;

-- View project statistics
SELECT 
    COUNT(*) as total_projects,
    COUNT(CASE WHEN status = 'open' THEN 1 END) as open_projects,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_projects
FROM projects;

-- View popular skills
SELECT s.name, s.category, COUNT(us.user_id) as user_count
FROM skills s
LEFT JOIN user_skills us ON s.id = us.skill_id
GROUP BY s.id, s.name, s.category
ORDER BY user_count DESC;

-- View department statistics
SELECT 
    p.department,
    COUNT(*) as member_count,
    AVG(CASE WHEN st.gpa IS NOT NULL THEN CAST(st.gpa AS DECIMAL) END) as avg_gpa
FROM profiles p
LEFT JOIN students st ON p.user_id = st.user_id
WHERE p.department IS NOT NULL
GROUP BY p.department
ORDER BY member_count DESC;
```

## Security Notes

1. **Never share connection credentials** publicly
2. **Use read-only users** for reporting when possible
3. **Regularly rotate passwords** for security
4. **Monitor database access** through audit logs
5. **Use SSL connections** always (required for Neon)

## Troubleshooting

### Connection Issues
- Verify SSL mode is set to "Require"
- Check firewall settings
- Ensure credentials are correct
- Verify Neon project is active

### Performance Issues
- Use EXPLAIN ANALYZE for slow queries
- Check database indexes
- Monitor connection pool usage
- Review query execution plans

### Data Issues
- Use database constraints for data integrity
- Regular backup verification
- Monitor disk space usage
- Check for connection leaks

## Support

For additional help:
- Neon Documentation: https://neon.tech/docs
- pgAdmin Documentation: https://www.pgadmin.org/docs/
- PostgreSQL Documentation: https://www.postgresql.org/docs/