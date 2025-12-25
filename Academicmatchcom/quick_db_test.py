#!/usr/bin/env python3
"""
Quick Database Test Script for MindMatch
Simple utility for testing database operations
"""

from python_db_connection import MindMatchDatabase

def main():
    print("🔄 MindMatch PostgreSQL Quick Test")
    
    with MindMatchDatabase() as db:
        # Quick connection test
        print("✅ Connected to PostgreSQL database")
        
        # Show database stats
        stats = db.get_user_statistics()
        print(f"👥 Users: {stats['total_users']} (Students: {stats['students']}, Professors: {stats['professors']})")
        print(f"📋 Projects: {stats['total_projects']}")
        print(f"🤝 Team Memberships: {stats['team_memberships']}")
        
        # Show recent projects
        projects = db.get_recent_projects(3)
        print(f"\n📝 Recent Projects:")
        for project in projects:
            print(f"   • {project['title']} by {project['creator']} (Team: {project['team_size']})")
        
        print("\n🎉 Database is working perfectly!")

if __name__ == "__main__":
    main()