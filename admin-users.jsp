<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ include file="db_config.jsp" %>

<%
    // Check if admin is logged in
    String adminId = (String) session.getAttribute("admin_id");
    if (adminId == null) {
        response.sendRedirect("login.jsp?user_type=admin");
        return;
    }

    // Handle delete action
    String action = request.getParameter("action");
    String userId = request.getParameter("id");
    
    if ("delete".equals(action) && userId != null) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = getConnection();
            String sql = "DELETE FROM users WHERE user_id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, Integer.parseInt(userId));
            pstmt.executeUpdate();
            
            session.setAttribute("message", "User deleted successfully!");
            session.setAttribute("message_type", "success");
            
        } catch(Exception e) {
            session.setAttribute("message", "Error deleting user: " + e.getMessage());
            session.setAttribute("message_type", "error");
            e.printStackTrace();
        } finally {
            try { if (pstmt != null) pstmt.close(); } catch(Exception e) {}
            try { if (conn != null) conn.close(); } catch(Exception e) {}
        }
        
        response.sendRedirect("admin-users.jsp");
        return;
    }

    // Get all users
    List<Map<String, String>> users = new ArrayList<>();
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;
    
    try {
        conn = getConnection();
        stmt = conn.createStatement();
        rs = stmt.executeQuery("SELECT * FROM users ORDER BY created_at DESC");
        
        while (rs.next()) {
            Map<String, String> user = new HashMap<>();
            user.put("id", rs.getString("user_id"));
            user.put("username", rs.getString("username"));
            user.put("email", rs.getString("email"));
            user.put("full_name", rs.getString("full_name"));
            user.put("created_at", rs.getString("created_at"));
            users.add(user);
        }
        
    } catch(Exception e) {
        e.printStackTrace();
    } finally {
        try { if (rs != null) rs.close(); } catch(Exception e) {}
        try { if (stmt != null) stmt.close(); } catch(Exception e) {}
        try { if (conn != null) conn.close(); } catch(Exception e) {}
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Users - ReadVerse Admin</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Poppins', sans-serif;
            background: #f5f7fa;
            color: #333;
            line-height: 1.6;
        }
        
        .admin-container {
            display: flex;
            min-height: 100vh;
        }
        
        .admin-sidebar {
            width: 250px;
            background: #2c3e50;
            color: white;
            position: fixed;
            height: 100%;
            overflow-y: auto;
        }
        
        .sidebar-header {
            padding: 30px 20px;
            background: #1a252f;
            text-align: center;
        }
        
        .sidebar-header h3 {
            font-size: 1.5rem;
            margin-bottom: 5px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }
        
        .sidebar-menu {
            padding: 20px 0;
        }
        
        .nav {
            list-style: none;
        }
        
        .nav-item {
            margin: 5px 0;
        }
        
        .nav-link {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 15px 20px;
            color: #bdc3c7;
            text-decoration: none;
            transition: all 0.3s ease;
        }
        
        .nav-link:hover, .nav-link.active {
            background: #34495e;
            color: white;
            border-left: 4px solid #3498db;
        }
        
        .nav-link i {
            width: 20px;
            text-align: center;
        }
        
        .admin-content {
            flex: 1;
            margin-left: 250px;
            padding: 30px;
        }
        
        .admin-header {
            background: white;
            padding: 25px 30px;
            border-radius: 10px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            margin-bottom: 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .admin-header h1 {
            font-size: 1.8rem;
            color: #2c3e50;
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .admin-info {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .admin-avatar {
            width: 50px;
            height: 50px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            font-size: 1.2rem;
        }
        
        .message {
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            animation: slideDown 0.3s ease;
        }
        
        @keyframes slideDown {
            from { transform: translateY(-20px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }
        
        .message.success {
            background: #d4edda;
            color: #155724;
            border-left: 4px solid #28a745;
        }
        
        .message.error {
            background: #f8d7da;
            color: #721c24;
            border-left: 4px solid #dc3545;
        }
        
        .close-message {
            background: none;
            border: none;
            color: inherit;
            cursor: pointer;
            font-size: 1.2rem;
            opacity: 0.7;
        }
        
        .close-message:hover {
            opacity: 1;
        }
        
        .users-table {
            background: white;
            border-radius: 10px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .table-header {
            padding: 20px 30px;
            background: #f8f9fa;
            border-bottom: 1px solid #e9ecef;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .table-header h3 {
            font-size: 1.3rem;
            color: #2c3e50;
            margin: 0;
        }
        
        .search-box {
            position: relative;
            width: 300px;
        }
        
        .search-box input {
            width: 100%;
            padding: 12px 20px 12px 45px;
            border: 2px solid #e9ecef;
            border-radius: 8px;
            font-size: 0.95rem;
            transition: all 0.3s ease;
            font-family: 'Poppins', sans-serif;
        }
        
        .search-box input:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        .search-box i {
            position: absolute;
            left: 15px;
            top: 50%;
            transform: translateY(-50%);
            color: #6c757d;
        }
        
        .table-container {
            padding: 20px;
            overflow-x: auto;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 800px;
        }
        
        thead {
            background: #f8f9fa;
        }
        
        th {
            padding: 15px;
            text-align: left;
            font-weight: 600;
            color: #2c3e50;
            border-bottom: 2px solid #e9ecef;
            font-size: 0.95rem;
        }
        
        td {
            padding: 15px;
            border-bottom: 1px solid #e9ecef;
            color: #6c757d;
        }
        
        tbody tr {
            transition: all 0.3s ease;
        }
        
        tbody tr:hover {
            background: #f8f9fa;
            transform: translateX(5px);
        }
        
        .user-avatar {
            width: 45px;
            height: 45px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            font-size: 1.1rem;
        }
        
        .user-info {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        
        .user-name {
            font-weight: 600;
            color: #2c3e50;
        }
        
        .action-buttons {
            display: flex;
            gap: 10px;
        }
        
        .btn-action {
            padding: 8px 15px;
            border-radius: 6px;
            font-size: 0.85rem;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: all 0.3s ease;
            border: none;
            cursor: pointer;
            font-family: 'Poppins', sans-serif;
            font-weight: 500;
        }
        
        .btn-action.view {
            background: #e3f2fd;
            color: #1976d2;
        }
        
        .btn-action.edit {
            background: #fff3e0;
            color: #f57c00;
        }
        
        .btn-action.delete {
            background: #ffebee;
            color: #d32f2f;
        }
        
        .btn-action:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        
        .btn-action.view:hover {
            background: #1976d2;
            color: white;
        }
        
        .btn-action.edit:hover {
            background: #f57c00;
            color: white;
        }
        
        .btn-action.delete:hover {
            background: #d32f2f;
            color: white;
        }
        
        .empty-state {
            text-align: center;
            padding: 50px 20px;
        }
        
        .empty-state i {
            font-size: 4rem;
            color: #e9ecef;
            margin-bottom: 20px;
        }
        
        .empty-state h3 {
            color: #6c757d;
            margin-bottom: 10px;
        }
        
        .empty-state p {
            color: #6c757d;
            margin-bottom: 20px;
        }
        
        .btn-add {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 12px 25px;
            border-radius: 8px;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-weight: 500;
            border: none;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .btn-add:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 20px rgba(102, 126, 234, 0.3);
        }
        
        @media (max-width: 992px) {
            .admin-sidebar {
                width: 70px;
            }
            
            .admin-content {
                margin-left: 70px;
            }
            
            .sidebar-header h3 span,
            .sidebar-header p,
            .nav-link span {
                display: none;
            }
            
            .nav-link {
                justify-content: center;
                padding: 20px;
            }
            
            .nav-link i {
                font-size: 1.3rem;
            }
        }
        
        @media (max-width: 768px) {
            .admin-content {
                padding: 15px;
            }
            
            .admin-header {
                flex-direction: column;
                gap: 20px;
                text-align: center;
                padding: 20px;
            }
            
            .search-box {
                width: 100%;
            }
            
            .table-header {
                flex-direction: column;
                align-items: flex-start;
                gap: 15px;
            }
            
            .btn-action span {
                display: none;
            }
            
            .btn-action i {
                margin: 0;
            }
        }
    </style>
</head>
<body>
    <div class="admin-container">
        <!-- Sidebar -->
        <div class="admin-sidebar">
            <div class="sidebar-header">
                <h3><i class="fas fa-book-open"></i> <span>ReadVerse</span></h3>
                <p>Admin Panel</p>
            </div>
            
            <div class="sidebar-menu">
                <ul class="nav">
                    <li class="nav-item">
                        <a class="nav-link" href="admin-dashboard.jsp">
                            <i class="fas fa-tachometer-alt"></i> <span>Dashboard</span>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link active" href="admin-users.jsp">
                            <i class="fas fa-users"></i> <span>Users</span>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="admin-books.jsp">
                            <i class="fas fa-book"></i> <span>Books</span>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="admin-category.jsp">
                            <i class="fas fa-tags"></i> <span>Categories</span>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="admin-orders.jsp">
                            <i class="fas fa-shopping-cart"></i> <span>Orders</span>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="index.jsp">
                            <i class="fas fa-home"></i> <span>View Site</span>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="logout.jsp?type=admin">
                            <i class="fas fa-sign-out-alt"></i> <span>Logout</span>
                        </a>
                    </li>
                </ul>
            </div>
        </div>
        
        <!-- Main Content -->
        <div class="admin-content">
            <div class="admin-header">
                <div>
                    <h1><i class="fas fa-users"></i> Manage Users</h1>
                    <p style="color: #6c757d; margin-top: 5px;">View and manage all registered users</p>
                </div>
                <div class="admin-info">
                    <div class="admin-avatar">
                        <% 
                            String adminName = (String) session.getAttribute("admin_full_name");
                            if (adminName != null && !adminName.isEmpty()) {
                                out.print(adminName.charAt(0));
                            } else {
                                out.print("A");
                            }
                        %>
                    </div>
                    <div>
                        <h4 style="margin: 0; font-size: 1.1rem;">
                            <% 
                                if (adminName != null) {
                                    out.print(adminName);
                                } else {
                                    out.print("Admin");
                                }
                            %>
                        </h4>
                        <p style="margin: 0; font-size: 0.9rem; color: #6c757d;">
                            <%= session.getAttribute("admin_role") != null ? session.getAttribute("admin_role") : "Administrator" %>
                        </p>
                    </div>
                </div>
            </div>
            
            <!-- Messages -->
            <% if (session.getAttribute("message") != null) { %>
            <div class="message <%= session.getAttribute("message_type") %>">
                <span><i class="fas fa-info-circle"></i> <%= session.getAttribute("message") %></span>
                <button class="close-message" onclick="this.parentElement.style.display='none'">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <%
                session.removeAttribute("message");
                session.removeAttribute("message_type");
            } %>
            
            <!-- Users Table -->
            <div class="users-table">
                <div class="table-header">
                    <h3>All Users (<%= users.size() %>)</h3>
                    <div class="search-box">
                        <i class="fas fa-search"></i>
                        <input type="text" id="searchInput" placeholder="Search users by name or email...">
                    </div>
                    <button class="btn-add" onclick="addUser()">
                        <i class="fas fa-plus"></i> Add User
                    </button>
                </div>
                
                <div class="table-container">
                    <table>
                        <thead>
                            <tr>
                                <th>User</th>
                                <th>Username</th>
                                <th>Email</th>
                                <th>Joined Date</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody id="userTableBody">
                            <% for (Map<String, String> user : users) { %>
                            <tr>
                                <td>
                                    <div class="user-info">
                                        <div class="user-avatar">
                                            <%= user.get("full_name").charAt(0) %>
                                        </div>
                                        <div>
                                            <div class="user-name"><%= user.get("full_name") %></div>
                                        </div>
                                    </div>
                                </td>
                                <td><%= user.get("username") %></td>
                                <td><%= user.get("email") %></td>
                                <td><%= user.get("created_at") %></td>
                                <td>
                                    <div class="action-buttons">
                                        <button class="btn-action view" onclick="viewUser('<%= user.get("id") %>')">
                                            <i class="fas fa-eye"></i> <span>View</span>
                                        </button>
                                        <button class="btn-action edit" onclick="editUser('<%= user.get("id") %>')">
                                            <i class="fas fa-edit"></i> <span>Edit</span>
                                        </button>
                                        <button class="btn-action delete" 
                                                onclick="deleteUser('<%= user.get("id") %>', '<%= user.get("full_name") %>')">
                                            <i class="fas fa-trash"></i> <span>Delete</span>
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                            
                            <% if (users.isEmpty()) { %>
                            <tr>
                                <td colspan="5">
                                    <div class="empty-state">
                                        <i class="fas fa-users"></i>
                                        <h3>No Users Found</h3>
                                        <p>No users have registered yet.</p>
                                        <button class="btn-add" onclick="addUser()">
                                            <i class="fas fa-plus"></i> Add First User
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Search functionality
        document.getElementById('searchInput').addEventListener('input', function(e) {
            const searchTerm = e.target.value.toLowerCase();
            const rows = document.querySelectorAll('#userTableBody tr');
            let visibleCount = 0;
            
            rows.forEach(row => {
                const text = row.textContent.toLowerCase();
                const isVisible = text.includes(searchTerm);
                row.style.display = isVisible ? '' : 'none';
                if (isVisible) visibleCount++;
            });
            
            // Update the user count in header
            const header = document.querySelector('.table-header h3');
            if (header) {
                if (searchTerm === '') {
                    header.textContent = `All Users (<%= users.size() %>)`;
                } else {
                    header.textContent = `Search Results (${visibleCount})`;
                }
            }
        });
        
        // User actions
        function viewUser(userId) {
            window.location.href = 'admin-user-view.jsp?id=' + userId;
        }
        
        function editUser(userId) {
            window.location.href = 'admin-user-edit.jsp?id=' + userId;
        }
        
        function deleteUser(userId, userName) {
            if (confirm('Are you sure you want to delete "' + userName + '"? This action cannot be undone.')) {
                window.location.href = 'admin-users.jsp?action=delete&id=' + userId;
            }
        }
        
        function addUser() {
            alert('Add user functionality coming soon!');
            // window.location.href = 'admin-user-add.jsp';
        }
        
        // Close message when clicked
        document.addEventListener('DOMContentLoaded', function() {
            // Add click event to all close buttons
            document.querySelectorAll('.close-message').forEach(button => {
                button.addEventListener('click', function() {
                    this.parentElement.style.display = 'none';
                });
            });
            
            // Auto-hide messages after 5 seconds
            const messages = document.querySelectorAll('.message');
            messages.forEach(message => {
                setTimeout(() => {
                    message.style.display = 'none';
                }, 5000);
            });
            
            // Add animation to table rows
            const rows = document.querySelectorAll('#userTableBody tr');
            rows.forEach((row, index) => {
                row.style.animationDelay = (index * 0.1) + 's';
                row.classList.add('fade-in');
            });
        });
        
        // Add fade-in animation
        const style = document.createElement('style');
        style.textContent = `
            @keyframes fadeIn {
                from { opacity: 0; transform: translateY(10px); }
                to { opacity: 1; transform: translateY(0); }
            }
            .fade-in {
                animation: fadeIn 0.5s ease forwards;
                opacity: 0;
            }
        `;
        document.head.appendChild(style);
    </script>
</body>
</html>