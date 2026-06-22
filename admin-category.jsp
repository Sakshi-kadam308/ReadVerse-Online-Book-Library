<%@ page contentType="text/html; charset=ISO-8859-1" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ include file="db_config.jsp" %>
<%
    // Check if admin is logged in
    String adminId = (String) session.getAttribute("admin_id");
    if(adminId == null) {
        response.sendRedirect("login.jsp?user_type=admin");
        return;
    }
    
    // Handle form submission
    if("POST".equals(request.getMethod())) {
        String categoryName = request.getParameter("name");
        String categoryDescription = request.getParameter("description");
        String action = request.getParameter("form_action");
        String categoryId = request.getParameter("category_id");
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = getConnection();
            
            if("add".equals(action)) {
                String sql = "INSERT INTO categories (name, description) VALUES (?, ?)";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, categoryName);
                pstmt.setString(2, categoryDescription != null ? categoryDescription : "");
                pstmt.executeUpdate();
                
                session.setAttribute("message", "Category added successfully!");
                session.setAttribute("message_type", "success");
                
            } else if("edit".equals(action)) {
                String sql = "UPDATE categories SET name = ?, description = ? WHERE category_id = ?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, categoryName);
                pstmt.setString(2, categoryDescription != null ? categoryDescription : "");
                pstmt.setInt(3, Integer.parseInt(categoryId));
                pstmt.executeUpdate();
                
                session.setAttribute("message", "Category updated successfully!");
                session.setAttribute("message_type", "success");
            }
            
        } catch(Exception e) {
            e.printStackTrace();
            session.setAttribute("message", "Error: " + e.getMessage());
            session.setAttribute("message_type", "error");
        } finally {
            if(pstmt != null) { try { pstmt.close(); } catch(Exception e) {} }
            if(conn != null) { try { conn.close(); } catch(Exception e) {} }
        }
        
        response.sendRedirect("admin-category.jsp");
        return;
    }
    
    // Handle delete action
    String action = request.getParameter("action");
    String catId = request.getParameter("id");
    
    if("delete".equals(action) && catId != null) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = getConnection();
            String sql = "DELETE FROM categories WHERE category_id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, Integer.parseInt(catId));
            pstmt.executeUpdate();
            
            session.setAttribute("message", "Category deleted successfully!");
            session.setAttribute("message_type", "success");
            
        } catch(Exception e) {
            e.printStackTrace();
            session.setAttribute("message", "Error deleting category: " + e.getMessage());
            session.setAttribute("message_type", "error");
        } finally {
            if(pstmt != null) { try { pstmt.close(); } catch(Exception e) {} }
            if(conn != null) { try { conn.close(); } catch(Exception e) {} }
        }
        
        response.sendRedirect("admin-category.jsp");
        return;
    }
%>

<%
    // Get all categories
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;
    List<Map<String, Object>> categories = new ArrayList<Map<String, Object>>();
    
    String editId = request.getParameter("edit");
    Map<String, Object> editCategory = null;
    
    try {
        conn = getConnection();
        stmt = conn.createStatement();
        
        // Get categories
        rs = stmt.executeQuery("SELECT c.*, COUNT(b.book_id) as book_count FROM categories c " +
                              "LEFT JOIN books b ON c.category_id = b.category_id " +
                              "GROUP BY c.category_id ORDER BY c.created_at DESC");
        
        while(rs.next()) {
            Map<String, Object> category = new HashMap<String, Object>();
            category.put("id", rs.getObject("category_id"));
            category.put("name", rs.getObject("name"));
            category.put("description", rs.getObject("description"));
            category.put("book_count", rs.getObject("book_count"));
            category.put("created_at", rs.getObject("created_at"));
            categories.add(category);
            
            // Get category to edit
            if(editId != null) {
                Object idObj = category.get("id");
                if(idObj != null && editId.equals(idObj.toString())) {
                    editCategory = category;
                }
            }
        }
        
    } catch(Exception e) {
        e.printStackTrace();
    } finally {
        if(rs != null) { try { rs.close(); } catch(Exception e) {} }
        if(stmt != null) { try { stmt.close(); } catch(Exception e) {} }
        if(conn != null) { try { conn.close(); } catch(Exception e) {} }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Categories - ReadVerse Admin</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        :root {
            --sidebar-width: 250px;
            --primary: #6c63ff;
            --light: #f8f9fa;
            --dark: #333;
            --gray: #666;
            --gradient-primary: linear-gradient(135deg, #6c63ff 0%, #36d1dc 100%);
            --shadow: 0 5px 20px rgba(0,0,0,0.08);
            --border-radius: 12px;
            --transition: all 0.3s ease;
            --danger: #f44336;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f8f9fa;
            color: var(--dark);
        }
        
        .admin-container {
            display: flex;
            min-height: 100vh;
        }
        
        .admin-sidebar {
            width: var(--sidebar-width);
            background: white;
            box-shadow: var(--shadow);
            position: fixed;
            height: 100vh;
            overflow-y: auto;
            z-index: 1000;
        }
        
        .admin-content {
            flex: 1;
            margin-left: var(--sidebar-width);
            padding: 30px;
        }
        
        .sidebar-header {
            padding: 25px 20px;
            background: var(--gradient-primary);
            color: white;
            text-align: center;
        }
        
        .sidebar-header h3 {
            margin: 0;
            font-size: 1.5rem;
        }
        
        .sidebar-header p {
            margin: 5px 0 0 0;
            opacity: 0.9;
            font-size: 0.9rem;
        }
        
        .sidebar-menu {
            padding: 20px 0;
        }
        
        .nav {
            list-style: none;
            padding: 0;
            margin: 0;
        }
        
        .nav-item {
            padding: 0;
        }
        
        .nav-link {
            padding: 15px 25px;
            color: var(--dark);
            display: flex;
            align-items: center;
            transition: var(--transition);
            border-left: 3px solid transparent;
            text-decoration: none;
        }
        
        .nav-link:hover {
            background: rgba(108, 99, 255, 0.05);
            color: var(--primary);
            border-left-color: var(--primary);
        }
        
        .nav-link.active {
            background: rgba(108, 99, 255, 0.1);
            color: var(--primary);
            border-left-color: var(--primary);
            font-weight: 500;
        }
        
        .nav-link i {
            width: 25px;
            margin-right: 10px;
            font-size: 1.1rem;
        }
        
        .admin-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 1px solid #e0e0e0;
        }
        
        .admin-header h1 {
            font-size: 2rem;
            color: var(--dark);
            margin: 0;
        }
        
        .admin-info {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .admin-avatar {
            width: 45px;
            height: 45px;
            background: var(--gradient-primary);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            font-size: 1.2rem;
        }
        
        .content-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
        }
        
        @media (max-width: 1200px) {
            .content-grid {
                grid-template-columns: 1fr;
            }
        }
        
        .form-card, .categories-table {
            background: white;
            border-radius: var(--border-radius);
            padding: 30px;
            box-shadow: var(--shadow);
        }
        
        .form-card h3, .categories-table h3 {
            margin-top: 0;
            margin-bottom: 25px;
            color: var(--dark);
            font-size: 1.5rem;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: var(--dark);
            font-weight: 500;
            font-size: 0.95rem;
        }
        
        .form-control {
            width: 100%;
            padding: 14px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 1rem;
            transition: var(--transition);
            font-family: inherit;
        }
        
        .form-control:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(108, 99, 255, 0.1);
        }
        
        textarea.form-control {
            min-height: 120px;
            resize: vertical;
        }
        
        .category-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 20px;
            border: 1px solid #e0e0e0;
            border-radius: 10px;
            margin-bottom: 15px;
            transition: var(--transition);
        }
        
        .category-item:hover {
            border-color: var(--primary);
            box-shadow: 0 5px 15px rgba(108, 99, 255, 0.1);
        }
        
        .category-info h4 {
            margin: 0 0 5px 0;
            color: var(--dark);
            font-size: 1.1rem;
        }
        
        .category-info p {
            margin: 0 0 8px 0;
            color: var(--gray);
            font-size: 0.9rem;
        }
        
        .category-stats {
            display: flex;
            gap: 15px;
            font-size: 0.85rem;
        }
        
        .stat {
            background: var(--light);
            padding: 5px 10px;
            border-radius: 15px;
            color: var(--gray);
        }
        
        .category-actions {
            display: flex;
            gap: 10px;
        }
        
        .btn-edit, .btn-delete {
            padding: 8px 15px;
            border-radius: 6px;
            font-size: 0.85rem;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            transition: var(--transition);
            border: none;
            cursor: pointer;
            font-family: inherit;
        }
        
        .btn-edit {
            background: rgba(33, 150, 243, 0.1);
            color: #2196F3;
        }
        
        .btn-edit:hover {
            background: #2196F3;
            color: white;
        }
        
        .btn-delete {
            background: rgba(244, 67, 54, 0.1);
            color: var(--danger);
        }
        
        .btn-delete:hover {
            background: var(--danger);
            color: white;
        }
        
        .empty-state {
            text-align: center;
            padding: 50px 20px;
            color: var(--gray);
        }
        
        .empty-state i {
            font-size: 3rem;
            margin-bottom: 15px;
            opacity: 0.3;
        }
        
        .btn {
            display: inline-block;
            padding: 12px 25px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 500;
            cursor: pointer;
            transition: var(--transition);
            border: none;
            font-family: inherit;
            font-size: 0.95rem;
        }
        
        .btn-primary {
            background: var(--primary);
            color: white;
        }
        
        .btn-primary:hover {
            background: #554fd8;
            color: white;
        }
        
        .btn-outline {
            background: transparent;
            color: var(--primary);
            border: 2px solid var(--primary);
        }
        
        .btn-outline:hover {
            background: var(--primary);
            color: white;
        }
        
        .message {
            padding: 15px 25px;
            border-radius: 10px;
            margin-bottom: 25px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .message.success {
            background: rgba(76, 175, 80, 0.1);
            color: #2E7D32;
            border-left: 4px solid #4CAF50;
        }
        
        .message.error {
            background: rgba(244, 67, 54, 0.1);
            color: #C62828;
            border-left: 4px solid #F44336;
        }
        
        .close-message {
            background: none;
            border: none;
            color: inherit;
            cursor: pointer;
            font-size: 1.2rem;
            opacity: 0.7;
            padding: 0;
            width: 24px;
            height: 24px;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .close-message:hover {
            opacity: 1;
        }
        
        @media (max-width: 768px) {
            .admin-sidebar {
                width: 100%;
                height: auto;
                position: relative;
            }
            
            .admin-content {
                margin-left: 0;
                padding: 20px;
            }
            
            .admin-header {
                flex-direction: column;
                gap: 15px;
                align-items: flex-start;
            }
            
            .admin-info {
                width: 100%;
                justify-content: flex-start;
            }
            
            .content-grid {
                grid-template-columns: 1fr;
                gap: 20px;
            }
            
            .category-item {
                flex-direction: column;
                gap: 15px;
                align-items: flex-start;
            }
            
            .category-actions {
                width: 100%;
                justify-content: flex-end;
            }
        }
    </style>
</head>
<body>
    <div class="admin-container">
        <!-- Sidebar -->
        <div class="admin-sidebar">
            <div class="sidebar-header">
                <h3><i class="fas fa-book-open"></i> ReadVerse</h3>
                <p>Admin Panel</p>
            </div>
            
            <div class="sidebar-menu">
                <ul class="nav">
                    <li class="nav-item">
                        <a class="nav-link" href="admin-dashboard.jsp">
                            <i class="fas fa-tachometer-alt"></i> Dashboard
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="admin-users.jsp">
                            <i class="fas fa-users"></i> Users
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="admin-books.jsp">
                            <i class="fas fa-book"></i> Books
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link active" href="admin-category.jsp">
                            <i class="fas fa-tags"></i> Categories
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="admin-orders.jsp">
                            <i class="fas fa-shopping-cart"></i> Orders
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="index.jsp">
                            <i class="fas fa-home"></i> View Site
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="logout.jsp?type=admin">
                            <i class="fas fa-sign-out-alt"></i> Logout
                        </a>
                    </li>
                </ul>
            </div>
        </div>
        
        <!-- Main Content -->
        <div class="admin-content">
            <div class="admin-header">
                <h1><i class="fas fa-tags"></i> Manage Categories</h1>
                <div class="admin-info">
                    <div class="admin-avatar">
                        <%
                        String adminFullName = (String) session.getAttribute("admin_full_name");
                        if(adminFullName != null && !adminFullName.isEmpty()) {
                            out.print(adminFullName.charAt(0));
                        } else {
                            out.print("A");
                        }
                        %>
                    </div>
                    <div>
                        <h4 style="margin: 0; font-size: 1.1rem;">
                            <%
                            if(adminFullName != null && !adminFullName.isEmpty()) {
                                out.print(adminFullName);
                            } else {
                                out.print("Admin");
                            }
                            %>
                        </h4>
                        <p style="margin: 0; font-size: 0.9rem; color: var(--gray);">
                            <%
                            String adminRole = (String) session.getAttribute("admin_role");
                            if(adminRole != null && !adminRole.isEmpty()) {
                                out.print(adminRole);
                            } else {
                                out.print("Administrator");
                            }
                            %>
                        </p>
                    </div>
                </div>
            </div>
            
            <%
            String message = (String) session.getAttribute("message");
            String messageType = (String) session.getAttribute("message_type");
            if(message != null) {
            %>
            <div class="message <%= messageType != null ? messageType : "success" %>">
                <span><i class="fas fa-info-circle"></i> <%= message %></span>
                <button class="close-message" onclick="this.parentElement.style.display='none'">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <%
                session.removeAttribute("message");
                session.removeAttribute("message_type");
            }
            %>
            
            <div class="content-grid">
                <!-- Add/Edit Category Form -->
                <div class="form-card">
                    <h3>
                        <i class="fas fa-<%= editCategory != null ? "edit" : "plus" %>"></i> 
                        <%= editCategory != null ? "Edit Category" : "Add New Category" %>
                    </h3>
                    
                    <form method="POST" action="admin-category.jsp">
                        <input type="hidden" name="form_action" value="<%= editCategory != null ? "edit" : "add" %>">
                        <% if(editCategory != null && editCategory.get("id") != null) { %>
                        <input type="hidden" name="category_id" value="<%= editCategory.get("id") %>">
                        <% } %>
                        
                        <div class="form-group">
                            <label for="name">Category Name *</label>
                            <input type="text" id="name" name="name" class="form-control" required
                                   value="<%= editCategory != null && editCategory.get("name") != null ? editCategory.get("name") : "" %>"
                                   placeholder="Enter category name">
                        </div>
                        
                        <div class="form-group">
                            <label for="description">Description</label>
                            <textarea id="description" name="description" class="form-control"
                                      placeholder="Enter category description"><%= editCategory != null && editCategory.get("description") != null ? editCategory.get("description") : "" %></textarea>
                        </div>
                        
                        <div style="display: flex; gap: 15px; margin-top: 30px;">
                            <button type="submit" class="btn btn-primary" style="flex: 1;">
                                <i class="fas fa-<%= editCategory != null ? "save" : "plus" %>"></i>
                                <%= editCategory != null ? "Update Category" : "Add Category" %>
                            </button>
                            
                            <% if(editCategory != null) { %>
                            <a href="admin-category.jsp" class="btn btn-outline" style="flex: 1; text-align: center;">
                                <i class="fas fa-times"></i> Cancel
                            </a>
                            <% } %>
                        </div>
                    </form>
                </div>
                
                <!-- Categories List -->
                <div class="categories-table">
                    <h3><i class="fas fa-list"></i> All Categories (<%= categories.size() %>)</h3>
                    
                    <% if(categories.isEmpty()) { %>
                    <div class="empty-state">
                        <i class="fas fa-tags"></i>
                        <h3>No Categories Found</h3>
                        <p>Add your first category to get started.</p>
                    </div>
                    <% } else { 
                        for(Map<String, Object> category : categories) { 
                            String CatId = category.get("id") != null ? category.get("id").toString() : "";
                            String catName = category.get("name") != null ? category.get("name").toString() : "Unnamed";
                            String catDesc = category.get("description") != null ? category.get("description").toString() : "";
                            Object bookCountObj = category.get("book_count");
                            String bookCount = bookCountObj != null ? bookCountObj.toString() : "0";
                            String createdAt = category.get("created_at") != null ? category.get("created_at").toString() : "";
                    %>
                        <div class="category-item">
                            <div class="category-info">
                                <h4><%= catName %></h4>
                                <% if(catDesc != null && !catDesc.isEmpty()) { %>
                                <p><%= catDesc %></p>
                                <% } %>
                                <div class="category-stats">
                                    <span class="stat">
                                        <i class="fas fa-book"></i> <%= bookCount %> books
                                    </span>
                                    <% if(createdAt != null && !createdAt.isEmpty()) { %>
                                    <span class="stat">
                                        <i class="fas fa-calendar"></i> <%= createdAt %>
                                    </span>
                                    <% } %>
                                </div>
                            </div>
                            
                            <div class="category-actions">
                                <a href="admin-category.jsp?edit=<%= catId %>" class="btn-edit">
                                    <i class="fas fa-edit"></i> Edit
                                </a>
                                <a href="admin-category.jsp?action=delete&id=<%= catId %>" 
                                   class="btn-delete"
                                   onclick="return confirm('Are you sure you want to delete this category?')">
                                    <i class="fas fa-trash"></i> Delete
                                </a>
                            </div>
                        </div>
                    <% } 
                    } %>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Close message on click
        document.addEventListener('DOMContentLoaded', function() {
            var closeButtons = document.querySelectorAll('.close-message');
            closeButtons.forEach(function(button) {
                button.addEventListener('click', function() {
                    this.parentElement.style.display = 'none';
                });
            });
        });
    </script>
</body>
</html>