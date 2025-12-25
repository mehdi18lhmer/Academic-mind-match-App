-- MindMatch Database Views
-- These views provide convenient access to complex data relationships

-- 1. User Profile Summary View
CREATE OR REPLACE VIEW user_profile_summary AS
SELECT 
    u.id,
    u.username,
    u.email,
    u.user_type,
    p.first_name,
    p.last_name,
    p.department,
    p.year,
    p.major,
    p.bio,
    p.phone,
    p.linkedin_url,
    p.github_url,
    u.created_at,
    u.is_active
FROM users u
LEFT JOIN profiles p ON u.id = p.user_id;

-- 2. Student Details View
CREATE OR REPLACE VIEW student_details AS
SELECT 
    u.id,
    u.username,
    u.email,
    p.first_name,
    p.last_name,
    p.department,
    s.student_id,
    s.year,
    s.major,
    s.gpa,
    s.enrollment_date,
    s.graduation_date,
    COUNT(DISTINCT tm.project_id) as projects_joined,
    COUNT(DISTINCT us.skill_id) as skills_count,
    COUNT(DISTINCT ui.interest_id) as interests_count
FROM users u
INNER JOIN students s ON u.id = s.user_id
LEFT JOIN profiles p ON u.id = p.user_id
LEFT JOIN team_members tm ON u.id = tm.user_id
LEFT JOIN user_skills us ON u.id = us.user_id
LEFT JOIN user_interests ui ON u.id = ui.user_id
WHERE u.user_type = 'student'
GROUP BY u.id, u.username, u.email, p.first_name, p.last_name, p.department, 
         s.student_id, s.year, s.major, s.gpa, s.enrollment_date, s.graduation_date;

-- 3. Professor Details View
CREATE OR REPLACE VIEW professor_details AS
SELECT 
    u.id,
    u.username,
    u.email,
    p.first_name,
    p.last_name,
    prof.employee_id,
    prof.department,
    prof.title,
    prof.office_location,
    prof.phone_extension,
    prof.research_areas,
    prof.hire_date,
    prof.tenure,
    COUNT(DISTINCT pr.id) as projects_created,
    COUNT(DISTINCT tm.user_id) as students_mentored
FROM users u
INNER JOIN professors prof ON u.id = prof.user_id
LEFT JOIN profiles p ON u.id = p.user_id
LEFT JOIN projects pr ON u.id = pr.created_by
LEFT JOIN team_members tm ON pr.id = tm.project_id
WHERE u.user_type = 'professor'
GROUP BY u.id, u.username, u.email, p.first_name, p.last_name, prof.employee_id,
         prof.department, prof.title, prof.office_location, prof.phone_extension,
         prof.research_areas, prof.hire_date, prof.tenure;

-- 4. Project Summary View
CREATE OR REPLACE VIEW project_summary AS
SELECT 
    p.id,
    p.title,
    p.description,
    p.category,
    p.status,
    p.max_members,
    p.start_date,
    p.end_date,
    p.requirements,
    p.created_at,
    u.username as creator_username,
    prof.first_name as creator_first_name,
    prof.last_name as creator_last_name,
    COUNT(DISTINCT tm.user_id) as current_members,
    COUNT(DISTINCT m.id) as total_messages,
    COUNT(DISTINCT c.id) as conversations_count
FROM projects p
LEFT JOIN users u ON p.created_by = u.id
LEFT JOIN profiles prof ON u.id = prof.user_id
LEFT JOIN team_members tm ON p.id = tm.project_id
LEFT JOIN conversations c ON p.id = c.project_id
LEFT JOIN messages m ON c.id = m.conversation_id
GROUP BY p.id, p.title, p.description, p.category, p.status, p.max_members,
         p.start_date, p.end_date, p.requirements, p.created_at, u.username,
         prof.first_name, prof.last_name;

-- 5. Team Members View
CREATE OR REPLACE VIEW team_members_view AS
SELECT 
    tm.id as membership_id,
    tm.project_id,
    p.title as project_title,
    tm.user_id,
    u.username,
    prof.first_name,
    prof.last_name,
    prof.department,
    tm.role,
    tm.joined_at,
    u.user_type
FROM team_members tm
JOIN projects p ON tm.project_id = p.id
JOIN users u ON tm.user_id = u.id
LEFT JOIN profiles prof ON u.id = prof.user_id;

-- 6. Skills Analysis View
CREATE OR REPLACE VIEW skills_analysis AS
SELECT 
    s.id,
    s.name as skill_name,
    s.category,
    s.description,
    COUNT(us.user_id) as total_users,
    COUNT(CASE WHEN us.level = 'beginner' THEN 1 END) as beginners,
    COUNT(CASE WHEN us.level = 'intermediate' THEN 1 END) as intermediate,
    COUNT(CASE WHEN us.level = 'advanced' THEN 1 END) as advanced,
    COUNT(CASE WHEN us.level = 'expert' THEN 1 END) as experts,
    COUNT(CASE WHEN u.user_type = 'student' THEN 1 END) as students_count,
    COUNT(CASE WHEN u.user_type = 'professor' THEN 1 END) as professors_count
FROM skills s
LEFT JOIN user_skills us ON s.id = us.skill_id
LEFT JOIN users u ON us.user_id = u.id
GROUP BY s.id, s.name, s.category, s.description
ORDER BY total_users DESC;

-- 7. Interests Analysis View
CREATE OR REPLACE VIEW interests_analysis AS
SELECT 
    i.id,
    i.name as interest_name,
    i.category,
    i.description,
    COUNT(ui.user_id) as total_users,
    COUNT(CASE WHEN ui.priority = 1 THEN 1 END) as high_priority,
    COUNT(CASE WHEN ui.priority = 2 THEN 1 END) as medium_priority,
    COUNT(CASE WHEN ui.priority = 3 THEN 1 END) as low_priority,
    COUNT(CASE WHEN u.user_type = 'student' THEN 1 END) as students_count,
    COUNT(CASE WHEN u.user_type = 'professor' THEN 1 END) as professors_count
FROM interests i
LEFT JOIN user_interests ui ON i.id = ui.interest_id
LEFT JOIN users u ON ui.user_id = u.id
GROUP BY i.id, i.name, i.category, i.description
ORDER BY total_users DESC;

-- 8. Department Statistics View
CREATE OR REPLACE VIEW department_statistics AS
SELECT 
    p.department,
    COUNT(CASE WHEN u.user_type = 'student' THEN 1 END) as students_count,
    COUNT(CASE WHEN u.user_type = 'professor' THEN 1 END) as professors_count,
    COUNT(DISTINCT pr.id) as total_projects,
    COUNT(CASE WHEN pr.status = 'open' THEN 1 END) as open_projects,
    COUNT(CASE WHEN pr.status = 'in_progress' THEN 1 END) as active_projects,
    COUNT(CASE WHEN pr.status = 'completed' THEN 1 END) as completed_projects,
    AVG(CASE WHEN s.gpa IS NOT NULL THEN CAST(s.gpa AS DECIMAL) END) as avg_student_gpa,
    COUNT(DISTINCT tm.user_id) as total_collaborations
FROM profiles p
JOIN users u ON p.user_id = u.id
LEFT JOIN students s ON u.id = s.user_id
LEFT JOIN projects pr ON u.id = pr.created_by
LEFT JOIN team_members tm ON u.id = tm.user_id
WHERE p.department IS NOT NULL
GROUP BY p.department
ORDER BY students_count DESC;

-- 9. Active Projects Dashboard View
CREATE OR REPLACE VIEW active_projects_dashboard AS
SELECT 
    p.id,
    p.title,
    p.category,
    p.status,
    p.start_date,
    p.end_date,
    p.max_members,
    COUNT(DISTINCT tm.user_id) as current_members,
    (p.max_members - COUNT(DISTINCT tm.user_id)) as spots_available,
    u.username as creator,
    prof.department as creator_department,
    CASE 
        WHEN p.end_date < CURRENT_DATE THEN 'Overdue'
        WHEN p.end_date <= CURRENT_DATE + INTERVAL '7 days' THEN 'Due Soon'
        ELSE 'On Track'
    END as status_indicator,
    COUNT(DISTINCT m.id) as recent_messages
FROM projects p
LEFT JOIN users u ON p.created_by = u.id
LEFT JOIN profiles prof ON u.id = prof.user_id
LEFT JOIN team_members tm ON p.id = tm.project_id
LEFT JOIN conversations c ON p.id = c.project_id
LEFT JOIN messages m ON c.id = m.conversation_id AND m.created_at >= CURRENT_DATE - INTERVAL '7 days'
WHERE p.status IN ('open', 'in_progress')
GROUP BY p.id, p.title, p.category, p.status, p.start_date, p.end_date, 
         p.max_members, u.username, prof.department
ORDER BY p.created_at DESC;

-- 10. User Collaboration Network View
CREATE OR REPLACE VIEW user_collaboration_network AS
SELECT DISTINCT
    tm1.user_id as user1_id,
    u1.username as user1_username,
    p1.first_name as user1_first_name,
    p1.last_name as user1_last_name,
    tm2.user_id as user2_id,
    u2.username as user2_username,
    p2.first_name as user2_first_name,
    p2.last_name as user2_last_name,
    pr.id as project_id,
    pr.title as project_title,
    pr.category as project_category,
    tm1.role as user1_role,
    tm2.role as user2_role
FROM team_members tm1
JOIN team_members tm2 ON tm1.project_id = tm2.project_id AND tm1.user_id < tm2.user_id
JOIN projects pr ON tm1.project_id = pr.id
JOIN users u1 ON tm1.user_id = u1.id
JOIN users u2 ON tm2.user_id = u2.id
LEFT JOIN profiles p1 ON u1.id = p1.user_id
LEFT JOIN profiles p2 ON u2.id = p2.user_id
ORDER BY pr.title, u1.username;

-- 11. Messaging Activity View
CREATE OR REPLACE VIEW messaging_activity AS
SELECT 
    c.id as conversation_id,
    c.name as conversation_name,
    c.project_id,
    p.title as project_title,
    COUNT(m.id) as total_messages,
    COUNT(DISTINCT m.user_id) as active_participants,
    MAX(m.created_at) as last_message_date,
    MIN(m.created_at) as first_message_date,
    COUNT(CASE WHEN m.created_at >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as recent_messages
FROM conversations c
LEFT JOIN projects p ON c.project_id = p.id
LEFT JOIN messages m ON c.id = m.conversation_id
GROUP BY c.id, c.name, c.project_id, p.title
ORDER BY last_message_date DESC;

-- 12. User Performance Metrics View
CREATE OR REPLACE VIEW user_performance_metrics AS
SELECT 
    u.id,
    u.username,
    p.first_name,
    p.last_name,
    p.department,
    u.user_type,
    COUNT(DISTINCT tm.project_id) as projects_participated,
    COUNT(CASE WHEN tm.role = 'leader' THEN 1 END) as projects_led,
    COUNT(DISTINCT us.skill_id) as skills_count,
    COUNT(DISTINCT ui.interest_id) as interests_count,
    COUNT(DISTINCT e.id) as endorsements_received,
    COUNT(DISTINCT m.id) as messages_sent,
    COUNT(CASE WHEN pr.status = 'completed' THEN 1 END) as completed_projects,
    CASE 
        WHEN COUNT(DISTINCT tm.project_id) = 0 THEN 'Inactive'
        WHEN COUNT(DISTINCT tm.project_id) BETWEEN 1 AND 2 THEN 'Low Activity'
        WHEN COUNT(DISTINCT tm.project_id) BETWEEN 3 AND 5 THEN 'Moderate Activity'
        ELSE 'High Activity'
    END as activity_level
FROM users u
LEFT JOIN profiles p ON u.id = p.user_id
LEFT JOIN team_members tm ON u.id = tm.user_id
LEFT JOIN user_skills us ON u.id = us.user_id
LEFT JOIN user_interests ui ON u.id = ui.user_id
LEFT JOIN endorsements e ON u.id = e.user_id
LEFT JOIN messages m ON u.id = m.user_id
LEFT JOIN projects pr ON tm.project_id = pr.id
GROUP BY u.id, u.username, p.first_name, p.last_name, p.department, u.user_type
ORDER BY projects_participated DESC;