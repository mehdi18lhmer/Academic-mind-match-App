# VS Code Extensions for MindMatch Development

## Essential Extensions for Full-Stack Development

### Core Development
1. **TypeScript Importer** (`pmneo.tsimporter`)
   - Auto-imports TypeScript modules
   - Essential for large codebases

2. **ES7+ React/Redux/React-Native snippets** (`dsznajder.es7-react-js-snippets`)
   - React component snippets
   - Faster development with shortcuts

3. **Auto Rename Tag** (`formulahendry.auto-rename-tag`)
   - Automatically renames paired HTML/JSX tags
   - Prevents mismatched tags

4. **Bracket Pair Colorizer 2** (`coenraads.bracket-pair-colorizer-2`)
   - Colors matching brackets
   - Easier code navigation

### TypeScript & JavaScript
5. **TypeScript Hero** (`rbbit.typescript-hero`)
   - Advanced TypeScript support
   - Import management and organization

6. **JavaScript (ES6) code snippets** (`xabikos.javascriptsnippets`)
   - Modern JavaScript snippets
   - Speed up coding

### Database & SQL
7. **PostgreSQL** (`ms-ossdata.vscode-postgresql`)
   - PostgreSQL syntax highlighting
   - Query execution support

8. **SQLTools** (`mtxr.sqltools`)
   - Database management interface
   - Query runner and formatter

9. **SQLTools PostgreSQL/Cockroach Driver** (`mtxr.sqltools-driver-pg`)
   - PostgreSQL connection for SQLTools
   - Direct database access

### Frontend Development
10. **Tailwind CSS IntelliSense** (`bradlc.vscode-tailwindcss`)
    - Autocomplete for Tailwind classes
    - Essential for your Poppins theme

11. **CSS Peek** (`pranaygp.vscode-css-peek`)
    - Jump to CSS definitions
    - Helpful for styling debugging

12. **HTML CSS Support** (`ecmel.vscode-html-css`)
    - CSS class completion in HTML
    - Better CSS integration

### React Development
13. **React Native Tools** (`msjsdiag.vscode-react-native`)
    - React development tools
    - Component debugging

14. **vscode-styled-components** (`styled-components.vscode-styled-components`)
    - Styled components syntax highlighting
    - If using styled components

### Git & Version Control
15. **GitLens** (`eamodio.gitlens`)
    - Enhanced Git capabilities
    - Code history and blame annotations

16. **Git History** (`donjayamanne.githistory`)
    - Visual git log and file history
    - Easier version tracking

### Python Development
17. **Python** (`ms-python.python`)
    - Full Python language support
    - Essential for your database scripts

18. **Python Docstring Generator** (`njpwerner.autodocstring`)
    - Auto-generates docstrings
    - Better documentation

### Productivity & Quality
19. **Prettier - Code formatter** (`esbenp.prettier-vscode`)
    - Code formatting
    - Consistent code style

20. **ESLint** (`dbaeumer.vscode-eslint`)
    - JavaScript/TypeScript linting
    - Code quality enforcement

21. **Path Intellisense** (`christian-kohler.path-intellisense`)
    - File path autocompletion
    - Faster file navigation

22. **Auto Import - ES6, TS, JSX, TSX** (`steoates.autoimport`)
    - Automatic import suggestions
    - Reduces manual imports

### Theme & UI
23. **Material Icon Theme** (`pkief.material-icon-theme`)
    - Better file icons
    - Improved visual navigation

24. **One Dark Pro** (`zhuangtongfa.material-theme`)
    - Popular dark theme
    - Matches your Poppins green aesthetic

### API & Testing
25. **REST Client** (`humao.rest-client`)
    - Test API endpoints directly
    - No need for external tools

26. **Thunder Client** (`rangav.vscode-thunder-client`)
    - Lightweight REST API client
    - Alternative to Postman

### Advanced Tools
27. **Error Lens** (`usernamehw.errorlens`)
    - Inline error highlighting
    - Immediate error feedback

28. **Todo Tree** (`gruntfuggly.todo-tree`)
    - Tracks TODO comments
    - Better task management

29. **Live Server** (`ritwickdey.liveserver`)
    - Local development server
    - For static file testing

30. **Code Spell Checker** (`streetsidesoftware.code-spell-checker`)
    - Spell checking in code
    - Prevents typos

## MindMatch-Specific Configuration

### VS Code Settings (settings.json)
```json
{
  "typescript.preferences.importModuleSpecifier": "relative",
  "typescript.suggest.autoImports": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true,
  "tailwindCSS.includeLanguages": {
    "typescript": "javascript",
    "typescriptreact": "javascript"
  },
  "sqltools.connections": [
    {
      "name": "MindMatch PostgreSQL",
      "driver": "PostgreSQL",
      "previewLimit": 50,
      "server": "localhost",
      "port": 5432,
      "database": "your_database",
      "username": "your_username"
    }
  ]
}
```

### Workspace Settings (.vscode/settings.json)
```json
{
  "files.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/__pycache__": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true
  }
}
```

## Quick Installation

### Install All Essential Extensions (Command Palette)
```
ext install pmneo.tsimporter dsznajder.es7-react-js-snippets formulahendry.auto-rename-tag bradlc.vscode-tailwindcss ms-python.python esbenp.prettier-vscode dbaeumer.vscode-eslint eamodio.gitlens mtxr.sqltools mtxr.sqltools-driver-pg
```

## Database Connection Setup

1. Install SQLTools PostgreSQL driver
2. Open Command Palette (Ctrl+Shift+P)
3. Run "SQLTools: Add New Connection"
4. Choose PostgreSQL
5. Enter your database credentials:
   - Host: localhost (or your host)
   - Port: 5432
   - Database: your_database_name
   - Username: your_username
   - Password: your_password

## Recommended Keybindings

Add to keybindings.json:
```json
[
  {
    "key": "ctrl+shift+i",
    "command": "editor.action.organizeImports"
  },
  {
    "key": "ctrl+shift+f",
    "command": "editor.action.formatDocument"
  }
]
```

## Project-Specific Features

### For Your MindMatch Project:
- **TypeScript**: Full IntelliSense for your React components
- **Tailwind CSS**: Autocomplete for your Poppins green theme classes
- **PostgreSQL**: Direct database query execution
- **Python**: Support for your database connection scripts
- **React**: Component development and debugging
- **Git**: Version control for collaboration

These extensions will provide you with a complete development environment for your beautiful MindMatch application with the Poppins green theme and PostgreSQL database integration.