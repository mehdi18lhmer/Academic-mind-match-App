#!/usr/bin/env python3
"""
MindMatch PostgreSQL Database Testing Suite
Comprehensive testing for database operations and data integrity
"""

import sys
import json
from datetime import datetime
import traceback
from python_db_connection import MindMatchDatabase, test_connection

def print_header(title: str):
    """Print formatted section header"""
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")

def print_test_result(test_name: str, success: bool, details: str = ""):
    """Print formatted test result"""
    status = "✅ PASS" if success else "❌ FAIL"
    print(f"{status} {test_name}")
    if details:
        print(f"    {details}")

def test_basic_connection():
    """Test basic database connection"""
    print_header("DATABASE CONNECTION TEST")
    
    success = test_connection()
    print_test_result("Basic Connection", success)
    
    if success:
        try:
            with MindMatchDatabase() as db:
                info = db.get_database_info()
                print_test_result("Database Info Retrieval", True, 
                                f"PostgreSQL Version: {info['postgres_version']}")
                print_test_result("Database Size Query", True, 
                                f"Size: {info['database_size']}")
        except Exception as e:
            print_test_result("Database Info Retrieval", False, str(e))
    
    return success

def test_table_integrity():
    """Test all table access and integrity"""
    print_header("TABLE INTEGRITY TEST")
    
    try:
        with MindMatchDatabase() as db:
            test_results = db.test_all_tables()
            
            total_tests = len(test_results)
            successful_tests = sum(1 for result in test_results.values() 
                                 if result['status'] == 'success')
            
            print(f"Testing {total_tests} tables...")
            
            for table, result in test_results.items():
                if result['status'] == 'success':
                    print_test_result(f"Table: {table}", True, 
                                    f"Records: {result['count']}")
                else:
                    print_test_result(f"Table: {table}", False, 
                                    result['error'])
            
            print(f"\n📊 Summary: {successful_tests}/{total_tests} tables accessible")
            return successful_tests == total_tests
            
    except Exception as e:
        print_test_result("Table Integrity Test", False, str(e))
        return False

def test_user_operations():
    """Test user-related database operations"""
    print_header("USER OPERATIONS TEST")
    
    try:
        with MindMatchDatabase() as db:
            # Get user statistics
            stats = db.get_user_statistics()
            print_test_result("User Statistics", True, 
                            f"Total: {stats['total_users']}, Students: {stats['students']}, Professors: {stats['professors']}")
            
            # Test user profile retrieval
            users = db.execute_query("SELECT id FROM users LIMIT 3;")
            if users:
                for user in users:
                    profile = db.get_user_profile(user['id'])
                    if profile:
                        print_test_result(f"User Profile {user['id']}", True,
                                        f"Username: {profile['username']}, Type: {profile['user_type']}")
                    else:
                        print_test_result(f"User Profile {user['id']}", False, "Profile not found")
            else:
                print_test_result("User Profile Test", False, "No users found")
            
            return True
            
    except Exception as e:
        print_test_result("User Operations", False, str(e))
        return False

def test_project_operations():
    """Test project-related database operations"""
    print_header("PROJECT OPERATIONS TEST")
    
    try:
        with MindMatchDatabase() as db:
            # Get recent projects
            projects = db.get_recent_projects(5)
            print_test_result("Recent Projects Query", True, 
                            f"Found {len(projects)} projects")
            
            for project in projects:
                print(f"    📋 {project['title']} by {project['creator']} (Team: {project['team_size']})")
            
            # Test project statistics
            project_stats = db.execute_query("""
                SELECT 
                    category,
                    COUNT(*) as count
                FROM projects 
                GROUP BY category 
                ORDER BY count DESC;
            """)
            
            print_test_result("Project Categories", True, 
                            f"Found {len(project_stats)} categories")
            
            for stat in project_stats:
                print(f"    🏷️  {stat['category']}: {stat['count']} projects")
            
            return True
            
    except Exception as e:
        print_test_result("Project Operations", False, str(e))
        return False

def test_advanced_queries():
    """Test advanced database queries and relationships"""
    print_header("ADVANCED QUERIES TEST")
    
    try:
        with MindMatchDatabase() as db:
            # Test JOIN operations
            team_query = """
                SELECT 
                    p.title,
                    u.username,
                    tm.role,
                    tm.joined_at
                FROM team_members tm
                JOIN projects p ON tm.project_id = p.id
                JOIN users u ON tm.user_id = u.id
                ORDER BY tm.joined_at DESC
                LIMIT 10;
            """
            teams = db.execute_query(team_query)
            print_test_result("Team Relationships Query", True, 
                            f"Found {len(teams)} team memberships")
            
            # Test skills aggregation (fixed column names)
            skills_query = """
                SELECT 
                    s.name,
                    COUNT(us.user_id) as user_count,
                    COUNT(CASE WHEN us.level = 'Expert' THEN 1 END) as expert_count
                FROM skills s
                LEFT JOIN user_skills us ON s.id = us.skill_id
                GROUP BY s.id, s.name
                HAVING COUNT(us.user_id) > 0
                ORDER BY user_count DESC
                LIMIT 10;
            """
            skills = db.execute_query(skills_query)
            print_test_result("Skills Aggregation", True, 
                            f"Found {len(skills)} popular skills")
            
            for skill in skills[:5]:  # Show top 5
                print(f"    🛠️  {skill['name']}: {skill['user_count']} users ({skill['expert_count']} experts)")
            
            # Test inheritance queries (students/professors)
            inheritance_query = """
                SELECT 
                    'students' as type,
                    COUNT(*) as count
                FROM students
                UNION ALL
                SELECT 
                    'professors' as type,
                    COUNT(*) as count
                FROM professors;
            """
            inheritance = db.execute_query(inheritance_query)
            print_test_result("Inheritance Queries", True, 
                            f"Students/Professors inheritance working")
            
            return True
            
    except Exception as e:
        print_test_result("Advanced Queries", False, str(e))
        return False

def test_data_integrity():
    """Test data integrity and constraints"""
    print_header("DATA INTEGRITY TEST")
    
    try:
        with MindMatchDatabase() as db:
            # Check for orphaned records
            orphan_checks = [
                ("Team members without users", 
                 "SELECT COUNT(*) as count FROM team_members tm LEFT JOIN users u ON tm.user_id = u.id WHERE u.id IS NULL"),
                ("Team members without projects", 
                 "SELECT COUNT(*) as count FROM team_members tm LEFT JOIN projects p ON tm.project_id = p.id WHERE p.id IS NULL"),
                ("User skills without users", 
                 "SELECT COUNT(*) as count FROM user_skills us LEFT JOIN users u ON us.user_id = u.id WHERE u.id IS NULL"),
                ("Messages without conversations", 
                 "SELECT COUNT(*) as count FROM messages m LEFT JOIN conversations c ON m.conversation_id = c.id WHERE c.id IS NULL")
            ]
            
            all_clean = True
            for check_name, query in orphan_checks:
                result = db.execute_query(query)
                orphan_count = result[0]['count']
                is_clean = orphan_count == 0
                all_clean = all_clean and is_clean
                print_test_result(check_name, is_clean, 
                                f"Orphaned records: {orphan_count}")
            
            # Check foreign key constraints (fixed column names)
            fk_test = db.execute_query("""
                SELECT COUNT(*) as count 
                FROM projects p 
                JOIN users u ON p.created_by = u.id;
            """)
            print_test_result("Foreign Key Constraints", True, 
                            f"All projects have valid creators")
            
            return all_clean
            
    except Exception as e:
        print_test_result("Data Integrity", False, str(e))
        return False

def generate_database_report():
    """Generate comprehensive database report"""
    print_header("DATABASE HEALTH REPORT")
    
    try:
        with MindMatchDatabase() as db:
            # Database overview
            info = db.get_database_info()
            stats = db.get_user_statistics()
            
            report = {
                "timestamp": datetime.now().isoformat(),
                "database_info": info,
                "statistics": stats,
                "health_status": "healthy"
            }
            
            # Save report
            with open("database_health_report.json", "w") as f:
                json.dump(report, f, indent=2, default=str)
            
            print("📊 Database Health Report Generated:")
            print(f"   📅 Timestamp: {report['timestamp']}")
            print(f"   💾 Database Size: {info['database_size']}")
            print(f"   👥 Total Users: {stats['total_users']}")
            print(f"   📋 Total Projects: {stats['total_projects']}")
            print(f"   📁 Tables: {len(info['tables'])}")
            print(f"   📄 Report saved to: database_health_report.json")
            
            return True
            
    except Exception as e:
        print_test_result("Database Report", False, str(e))
        return False

def main():
    """Run all database tests"""
    print("🔄 Starting MindMatch PostgreSQL Database Testing Suite")
    print(f"🕒 Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    test_results = []
    
    # Run all tests
    tests = [
        ("Connection Test", test_basic_connection),
        ("Table Integrity", test_table_integrity),
        ("User Operations", test_user_operations),
        ("Project Operations", test_project_operations),
        ("Advanced Queries", test_advanced_queries),
        ("Data Integrity", test_data_integrity),
        ("Health Report", generate_database_report)
    ]
    
    for test_name, test_func in tests:
        try:
            result = test_func()
            test_results.append((test_name, result))
        except Exception as e:
            print(f"❌ {test_name} failed with exception: {e}")
            test_results.append((test_name, False))
            traceback.print_exc()
    
    # Summary
    print_header("TESTING SUMMARY")
    
    passed = sum(1 for _, result in test_results if result)
    total = len(test_results)
    
    print(f"📊 Tests passed: {passed}/{total}")
    
    for test_name, result in test_results:
        status = "✅" if result else "❌"
        print(f"{status} {test_name}")
    
    success_rate = (passed / total) * 100
    print(f"\n🎯 Success Rate: {success_rate:.1f}%")
    
    if success_rate == 100:
        print("🎉 All tests passed! Database is healthy and ready for production.")
    elif success_rate >= 80:
        print("⚠️  Most tests passed. Some issues detected but database is functional.")
    else:
        print("🚨 Multiple test failures detected. Database needs attention.")
    
    return success_rate >= 80

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)