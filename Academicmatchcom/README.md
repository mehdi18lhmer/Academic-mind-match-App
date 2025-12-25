# MindMatch - University Collaboration Platform

A comprehensive academic collaboration platform for Al Akhawayn University that facilitates cross-disciplinary research, team formation, and project management through intelligent matching algorithms.

## 🎯 Features

- **Smart User Matching**: AI-powered algorithm matching students and professors based on skills, interests, and academic goals
- **Project Management**: Create, join, and manage academic projects with team collaboration tools
- **Academic Profiles**: Comprehensive user profiles with CV integration, skills tracking, and endorsements
- **Real-time Communication**: WebSocket-based messaging system for project teams
- **Analytics Dashboard**: Department statistics, collaboration networks, and performance metrics
- **Library Integration**: Academic resource access with real-time article search
- **Compliance Monitoring**: IRB tracking and academic integrity oversight

## 🏗️ Architecture

### Frontend
- **React 18** with TypeScript
- **Vite** for fast development and building
- **TailwindCSS** with custom nature-inspired design system
- **shadcn/ui** components for consistent UI
- **TanStack Query** for server state management
- **Wouter** for lightweight routing

### Backend
- **Node.js** with Express.js
- **TypeScript** with ES modules
- **PostgreSQL** with Neon serverless hosting
- **Drizzle ORM** for type-safe database operations
- **JWT** authentication with bcrypt password hashing
- **WebSocket** support for real-time features

### Database
- **PostgreSQL** with inheritance patterns (professors vs students)
- **Advanced queries** with aggregations and subqueries
- **Views** for complex analytics and reporting
- **Indexed** for optimal performance

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ 
- npm or yarn
- Git (optional)

### Installation

1. **Clone or download the project**
   ```bash
   git clone <repository-url>
   cd mindmatch
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment setup**
   ```bash
   cp .env.example .env.local
   # Edit .env.local with your database credentials
   ```

4. **Test database connection**
   ```bash
   node test-db.js
   ```

5. **Start development server**
   ```bash
   npm run dev
   ```

6. **Open your browser**
   ```
   http://localhost:5000
   ```

## 🛠️ Development

### VS Code Setup
This project includes comprehensive VS Code configuration:

- **Debugging**: Press F5 to start debugging
- **Tasks**: Ctrl+Shift+P → "Tasks: Run Task"
- **Extensions**: Recommended extensions will be suggested
- **Settings**: Optimized for TypeScript and React development

### Available Scripts

```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run preview      # Preview production build
npm run type-check   # TypeScript type checking
npm run format       # Format code with Prettier
npm run db:push      # Push database schema changes
npm test             # Run tests
```

### Database Management

**Local Development:**
- Use pgAdmin to connect to the database
- Connection details in .env.local
- Run queries from `database/queries.sql`

**Schema Updates:**
```bash
npm run db:push      # Push schema changes
```

## 📊 Database Schema

### Core Tables
- `users` - Base user accounts with inheritance
- `students` - Student-specific data and academic info
- `professors` - Faculty data with research areas
- `projects` - Academic projects and collaborations
- `team_members` - Project team assignments
- `skills` / `interests` - Skill and interest taxonomies

### Key Views
- `professors_with_stats` - Professors with student counts and metrics
- `students_with_advisors` - Students with advisor relationships
- `department_statistics` - Aggregated department analytics

## 🔧 Configuration

### Environment Variables
```env
DATABASE_URL=postgresql://...     # PostgreSQL connection string
PORT=5000                         # Server port
NODE_ENV=development              # Environment mode
JWT_SECRET=your-secret-key        # JWT signing key
```

### Database Connection
```typescript
// Automatic connection handling
import { db } from './server/db';
const users = await db.select().from(usersTable);
```

## 🎨 UI Components

Built with shadcn/ui and custom components:
- `NatureCard` - Custom card component with nature-inspired design
- Responsive navigation with role-based access
- Real-time data updates every 5 seconds
- Mobile-first responsive design

## 📱 API Endpoints

### Authentication
- `POST /api/register` - User registration
- `POST /api/login` - User login
- `GET /api/user/profile` - Get user profile

### Users & Analytics
- `GET /api/users/professors` - Get professors with statistics
- `GET /api/users/students` - Get students with advisor info
- `GET /api/analytics/department` - Department analytics

### Projects & Teams
- `GET /api/projects` - List all projects
- `POST /api/projects` - Create new project
- `POST /api/projects/:id/team` - Join project team

## 🔒 Security

- JWT-based authentication
- bcrypt password hashing
- Input validation with Zod schemas
- SQL injection prevention with prepared statements
- CORS configuration for API access
- Environment variable protection

## 📈 Analytics & Reporting

- Real-time dashboard metrics
- Department performance statistics
- Collaboration network analysis
- Student-professor relationship tracking
- Project success rate monitoring

## 🚀 Deployment

### Production Build
```bash
npm run build        # Build optimized bundle
npm run preview      # Test production build
```

### Environment Setup
- Set production environment variables
- Configure database connection
- Set up SSL certificates
- Configure reverse proxy (nginx)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and type checking
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support and questions:
- Check the troubleshooting section in `vscode_setup_guide.md`
- Review database connection in `test-db.js`
- Consult the API documentation
- Contact the development team

---

Built with ❤️ for Al Akhawayn University academic collaboration.