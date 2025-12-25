#!/usr/bin/env python3
"""
MindMatch PostgreSQL Database Connection Module
Python utilities for connecting to and managing the PostgreSQL database
"""

import os
import psycopg2
import psycopg2.extras
from typing import List, Dict, Any, Optional
import json
from datetime import datetime
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MindMatchDatabase:
    """PostgreSQL database connection and operations for MindMatch platform"""
    
    def __init__(self):
        """Initialize database connection using environment variables"""
        self.connection = None
        self.cursor = None
        self.connect()
    
    def connect(self):
        """Establish connection to PostgreSQL database"""
        try:
            # Try DATABASE_URL first (full connection string)
            if os.getenv('DATABASE_URL'):
                self.connection = psycopg2.connect(
                    os.getenv('DATABASE_URL'),
                    cursor_factory=psycopg2.extras.RealDictCursor
                )
            else:
                # Use individual connection parameters
                self.connection = psycopg2.connect(
                    host=os.getenv('PGHOST', 'localhost'),
                    port=os.getenv('PGPORT', '5432'),
                    database=os.getenv('PGDATABASE', 'postgres'),
                    user=os.getenv('PGUSER', 'postgres'),
                    password=os.getenv('PGPASSWORD', ''),
                    cursor_factory=psycopg2.extras.RealDictCursor
                )
            
            self.cursor = self.connection.cursor()
            logger.info("✅ Successfully connected to PostgreSQL database")
            
        except psycopg2.Error as e:
            logger.error(f"❌ Database connection failed: {e}")
            raise
    
    def execute_query(self, query: str, params: Optional[tuple] = None) -> List[Dict[str, Any]]:
        """Execute a SELECT query and return results"""
        try:
            self.cursor.execute(query, params)
            results = self.cursor.fetchall()
            return [dict(row) for row in results]
        except psycopg2.Error as e:
            logger.error(f"Query execution failed: {e}")
            raise
    
    def execute_update(self, query: str, params: Optional[tuple] = None) -> int:
        """Execute INSERT/UPDATE/DELETE query and return affected rows"""
        try:
            self.cursor.execute(query, params)
            self.connection.commit()
            return self.cursor.rowcount
        except psycopg2.Error as e:
            self.connection.rollback()
            logger.error(f"Update execution failed: {e}")
            raise
    
    def get_database_info(self) -> Dict[str, Any]:
        """Get comprehensive database information"""
        info = {}
        
        # PostgreSQL version
        version_result = self.execute_query("SELECT version();")
        info['postgres_version'] = version_result[0]['version']
        
        # Database size
        size_result = self.execute_query("""
            SELECT pg_size_pretty(pg_database_size(current_database())) as database_size;
        """)
        info['database_size'] = size_result[0]['database_size']
        
        # Table information
        tables_result = self.execute_query("""
            SELECT 
                schemaname,
                tablename,
                pg_size_pretty(pg_total_relation_size(quote_ident(schemaname)||'.'||quote_ident(tablename))) as size
            FROM pg_tables 
            WHERE schemaname = 'public'
            ORDER BY pg_total_relation_size(quote_ident(schemaname)||'.'||quote_ident(tablename)) DESC;
        """)
        info['tables'] = tables_result
        
        return info
    
    def get_user_statistics(self) -> Dict[str, Any]:
        """Get user and project statistics"""
        stats = {}
        
        # User counts
        user_count = self.execute_query("SELECT COUNT(*) as count FROM users;")
        stats['total_users'] = user_count[0]['count']
        
        # Student vs Professor breakdown
        students = self.execute_query("SELECT COUNT(*) as count FROM students;")
        professors = self.execute_query("SELECT COUNT(*) as count FROM professors;")
        stats['students'] = students[0]['count']
        stats['professors'] = professors[0]['count']
        
        # Project statistics
        projects = self.execute_query("SELECT COUNT(*) as count FROM projects;")
        stats['total_projects'] = projects[0]['count']
        
        # Team statistics
        teams = self.execute_query("SELECT COUNT(*) as count FROM team_members;")
        stats['team_memberships'] = teams[0]['count']
        
        # Recent activity
        recent_users = self.execute_query("""
            SELECT COUNT(*) as count FROM users 
            WHERE created_at >= NOW() - INTERVAL '7 days';
        """)
        stats['new_users_this_week'] = recent_users[0]['count']
        
        return stats
    
    def get_recent_projects(self, limit: int = 5) -> List[Dict[str, Any]]:
        """Get most recent projects with creator information (fixed column names)"""
        query = """
            SELECT 
                p.id,
                p.title,
                p.description,
                p.category,
                p.created_at,
                u.username as creator,
                u.email as creator_email,
                COUNT(tm.user_id) as team_size
            FROM projects p
            JOIN users u ON p.created_by = u.id
            LEFT JOIN team_members tm ON p.id = tm.project_id
            GROUP BY p.id, u.username, u.email
            ORDER BY p.created_at DESC
            LIMIT %s;
        """
        return self.execute_query(query, (limit,))
    
    def get_user_profile(self, user_id: int) -> Optional[Dict[str, Any]]:
        """Get complete user profile with skills and interests"""
        # Basic user info (fixed column names)
        user_query = """
            SELECT u.*, p.bio, p.github_url, p.linkedin_url, p.profile_image, p.department, p.major
            FROM users u
            LEFT JOIN profiles p ON u.id = p.user_id
            WHERE u.id = %s;
        """
        user_result = self.execute_query(user_query, (user_id,))
        if not user_result:
            return None
        
        user = user_result[0]
        
        # Get skills (fixed column names)
        skills_query = """
            SELECT s.name, us.level, us.years_experience, us.is_verified
            FROM user_skills us
            JOIN skills s ON us.skill_id = s.id
            WHERE us.user_id = %s;
        """
        user['skills'] = self.execute_query(skills_query, (user_id,))
        
        # Get interests
        interests_query = """
            SELECT i.name
            FROM user_interests ui
            JOIN interests i ON ui.interest_id = i.id
            WHERE ui.user_id = %s;
        """
        user['interests'] = self.execute_query(interests_query, (user_id,))
        
        # Check if student or professor
        student_check = self.execute_query(
            "SELECT * FROM students WHERE user_id = %s;", (user_id,)
        )
        professor_check = self.execute_query(
            "SELECT * FROM professors WHERE user_id = %s;", (user_id,)
        )
        
        user['user_type'] = 'student' if student_check else ('professor' if professor_check else 'user')
        if student_check:
            user['student_info'] = student_check[0]
        elif professor_check:
            user['professor_info'] = professor_check[0]
        
        return user
    
    def test_all_tables(self) -> Dict[str, Any]:
        """Test access to all major tables"""
        test_results = {}
        
        tables_to_test = [
            'users', 'projects', 'team_members', 'skills', 'interests',
            'user_skills', 'user_interests', 'students', 'professors',
            'conversations', 'messages', 'compliance', 'endorsements'
        ]
        
        for table in tables_to_test:
            try:
                result = self.execute_query(f"SELECT COUNT(*) as count FROM {table};")
                test_results[table] = {
                    'status': 'success',
                    'count': result[0]['count']
                }
            except Exception as e:
                test_results[table] = {
                    'status': 'error',
                    'error': str(e)
                }
        
        return test_results
    
    def close(self):
        """Close database connection"""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
        logger.info("Database connection closed")
    
    def __enter__(self):
        """Context manager entry"""
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        self.close()

# Utility functions for quick operations
def quick_connect() -> MindMatchDatabase:
    """Quick connection function"""
    return MindMatchDatabase()

def test_connection() -> bool:
    """Test database connection"""
    try:
        with MindMatchDatabase() as db:
            db.execute_query("SELECT 1;")
        return True
    except Exception as e:
        logger.error(f"Connection test failed: {e}")
        return False

if __name__ == "__main__":
    # Quick test when run directly
    print("🔄 Testing MindMatch PostgreSQL Connection...")
    
    try:
        with MindMatchDatabase() as db:
            print("✅ Connection successful!")
            
            # Get basic info
            info = db.get_database_info()
            print(f"📊 Database: {info['postgres_version']}")
            print(f"💾 Size: {info['database_size']}")
            
            # Get statistics
            stats = db.get_user_statistics()
            print(f"👥 Users: {stats['total_users']} (Students: {stats['students']}, Professors: {stats['professors']})")
            print(f"📋 Projects: {stats['total_projects']}")
            print(f"🤝 Team Memberships: {stats['team_memberships']}")
            
    except Exception as e:
        print(f"❌ Connection failed: {e}")