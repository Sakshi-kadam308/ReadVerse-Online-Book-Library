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
    
    // Handle delete action
    String action = request.getParameter("action");
    String bookId = request.getParameter("id");
    
    if("delete".equals(action) && bookId != null) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = getConnection();
            String sql = "DELETE FROM books WHERE book_id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, Integer.parseInt(bookId));
            pstmt.executeUpdate();
            
            session.setAttribute("message", "Book deleted successfully!");
            session.setAttribute("message_type", "success");
            
        } catch(Exception e) {
            e.printStackTrace();
            session.setAttribute("message", "Error deleting book: " + e.getMessage());
            session.setAttribute("message_type", "error");
        } finally {
            try { if(pstmt != null) pstmt.close(); } catch(Exception e) {}
            try { if(conn != null) conn.close(); } catch(Exception e) {}
        }
        
        response.sendRedirect("admin-books.jsp");
        return;
    }
%>

<%
    // Get all books with category names
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;
    List<Map<String, Object>> books = new ArrayList<>();
    
    try {
        conn = getConnection();
        stmt = conn.createStatement();
        String sql = "SELECT b.*, c.name as category_name FROM books b " +
                    "LEFT JOIN categories c ON b.category_id = c.category_id " +
                    "ORDER BY b.created_at DESC";
        rs = stmt.executeQuery(sql);
        
        while(rs.next()) {
            Map<String, Object> book = new HashMap<>();
            book.put("id", rs.getObject("book_id"));
            book.put("title", rs.getObject("title"));
            book.put("author", rs.getObject("author"));
            book.put("isbn", rs.getObject("isbn"));
            
            // Handle price
            Object priceObj = rs.getObject("price");
            if(priceObj != null) {
                book.put("price", String.format("%.2f", rs.getDouble("price")));
            } else {
                book.put("price", "0.00");
            }
            
            // Handle stock
            Object stockObj = rs.getObject("stock_quantity");
            if(stockObj != null) {
                book.put("stock", rs.getInt("stock_quantity"));
            } else {
                book.put("stock", 0);
            }
            
            book.put("category", rs.getObject("category_name"));
            book.put("image", rs.getObject("image_url"));
            book.put("created_at", rs.getObject("created_at"));
            books.add(book);
        }
        
    } catch(Exception e) {
        e.printStackTrace();
        request.setAttribute("error", "Error loading books: " + e.getMessage());
    } finally {
        try { if(rs != null) rs.close(); } catch(Exception e) {}
        try { if(stmt != null) stmt.close(); } catch(Exception e) {}
        try { if(conn != null) conn.close(); } catch(Exception e) {}
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <%@ include file="head_include.jsp" %>
    <title>Manage Books - ReadVerse Admin</title>
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
            cursor: pointer;
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
        
        .page-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
        }
        
        .page-header h1 {
            font-size: 1.8rem;
            color: var(--dark);
            margin: 0;
        }
        
        .add-btn {
            background: var(--primary);
            color: white;
            padding: 12px 25px;
            border-radius: 8px;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-weight: 500;
            transition: var(--transition);
            border: none;
            cursor: pointer;
            font-size: 0.95rem;
        }
        
        .add-btn:hover {
            background: #554fd8;
            color: white;
            transform: translateY(-2px);
            text-decoration: none;
        }
        
        .books-table {
            background: white;
            border-radius: var(--border-radius);
            overflow: hidden;
            box-shadow: var(--shadow);
        }
        
        .table-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 25px;
            border-bottom: 1px solid #e0e0e0;
        }
        
        .table-header h3 {
            margin: 0;
            font-size: 1.3rem;
            color: var(--dark);
        }
        
        .search-box {
            position: relative;
            width: 300px;
        }
        
        .search-box input {
            width: 100%;
            padding: 12px 20px 12px 45px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 0.95rem;
            transition: var(--transition);
            font-family: inherit;
        }
        
        .search-box input:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(108, 99, 255, 0.1);
        }
        
        .search-box i {
            position: absolute;
            left: 15px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--gray);
        }
        
        .table-container {
            padding: 25px;
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
            color: var(--dark);
            border-bottom: 2px solid #e0e0e0;
            font-size: 0.95rem;
        }
        
        td {
            padding: 15px;
            border-bottom: 1px solid #e0e0e0;
            color: var(--gray);
            font-size: 0.9rem;
        }
        
        tbody tr:hover {
            background: #f8f9fa;
        }
        
        .book-image {
            width: 50px;
            height: 70px;
            border-radius: 5px;
            object-fit: cover;
            background: #f0f0f0;
        }
        
        .action-buttons {
            display: flex;
            gap: 8px;
        }
        
        .btn-edit, .btn-delete, .btn-view {
            padding: 6px 12px;
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
            text-decoration: none;
        }
        
        .btn-delete {
            background: rgba(244, 67, 54, 0.1);
            color: #F44336;
        }
        
        .btn-delete:hover {
            background: #F44336;
            color: white;
            text-decoration: none;
        }
        
        .btn-view {
            background: rgba(108, 99, 255, 0.1);
            color: var(--primary);
        }
        
        .btn-view:hover {
            background: var(--primary);
            color: white;
            text-decoration: none;
        }
        
        .status-badge {
            padding: 5px 10px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 500;
            display: inline-block;
        }
        
        .status-in-stock {
            background: rgba(76, 175, 80, 0.1);
            color: #2E7D32;
        }
        
        .status-out-of-stock {
            background: rgba(244, 67, 54, 0.1);
            color: #C62828;
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
        
        .message.info {
            background: rgba(33, 150, 243, 0.1);
            color: #1565C0;
            border-left: 4px solid #2196F3;
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
        
        .empty-state {
            text-align: center;
            padding: 60px 20px;
        }
        
        .empty-state i {
            font-size: 4rem;
            color: #e0e0e0;
            margin-bottom: 20px;
        }
        
        .empty-state h3 {
            color: var(--gray);
            margin-bottom: 10px;
            font-size: 1.5rem;
        }
        
        .empty-state p {
            color: var(--gray);
            margin-bottom: 25px;
            font-size: 1rem;
        }
        
        @media (max-width: 1024px) {
            .admin-sidebar {
                width: 100%;
                height: auto;
                position: relative;
            }
            
            .admin-content {
                margin-left: 0;
            }
            
            .content-grid {
                grid-template-columns: 1fr;
            }
        }
        
        @media (max-width: 768px) {
            .admin-content {
                padding: 20px;
            }
            
            .table-header {
                flex-direction: column;
                gap: 15px;
                align-items: flex-start;
            }
            
            .search-box {
                width: 100%;
            }
            
            .action-buttons {
                flex-direction: column;
                gap: 5px;
            }
            
            .btn-edit, .btn-delete, .btn-view {
                width: 100%;
                justify-content: center;
            }
        }
        
        .btn {
            display: inline-block;
            padding: 10px 20px;
            border-radius: 6px;
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
    </style>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
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
                        <a class="nav-link active" href="admin-books.jsp">
                            <i class="fas fa-book"></i> Books
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="admin-category.jsp">
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
                <div>
                    <h1><i class="fas fa-book"></i> Manage Books</h1>
                    <p style="color: var(--gray); margin-top: 5px;">View and manage all books in the store</p>
                </div>
                <div class="admin-info">
                    <div class="admin-avatar">
                        <%= (session.getAttribute("admin_full_name") != null && !session.getAttribute("admin_full_name").toString().isEmpty()) ? 
                            session.getAttribute("admin_full_name").toString().charAt(0) : "A" %>
                    </div>
                    <div>
                        <h4 style="margin: 0; font-size: 1.1rem;">
                            <%= session.getAttribute("admin_full_name") != null ? session.getAttribute("admin_full_name") : "Admin" %>
                        </h4>
                        <p style="margin: 0; font-size: 0.9rem; color: var(--gray);">
                            <%= session.getAttribute("admin_role") != null ? session.getAttribute("admin_role") : "Administrator" %>
                        </p>
                    </div>
                </div>
            </div>
            
            <% 
            String message = (String) session.getAttribute("message");
            String messageType = (String) session.getAttribute("message_type");
            if(message != null) { 
            %>
            <div class="message <%= messageType != null ? messageType : "info" %>">
                <span><i class="fas fa-info-circle"></i> <%= message %></span>
                <button class="close-message" onclick="this.parentElement.style.display='none'">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <%
                session.removeAttribute("message");
                session.removeAttribute("message_type");
            } 
            
            if(request.getAttribute("error") != null) { 
            %>
            <div class="message error">
                <span><i class="fas fa-exclamation-circle"></i> <%= request.getAttribute("error") %></span>
                <button class="close-message" onclick="this.parentElement.style.display='none'">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <% } %>
            
            <div class="page-header">
                <h1>Books Management</h1>
                <a href="admin-book-add.jsp" class="add-btn">
                    <i class="fas fa-plus"></i> Add New Book
                </a>
            </div>
            
            <div class="books-table">
                <div class="table-header">
                    <h3>All Books (<%= books.size() %>)</h3>
                    <div class="search-box">
                        <i class="fas fa-search"></i>
                        <input type="text" id="searchInput" placeholder="Search books by title, author, or ISBN...">
                    </div>
                </div>
                
                <div class="table-container">
                    <% if(books.isEmpty()) { %>
                    <div class="empty-state">
                        <i class="fas fa-book"></i>
                        <h3>No Books Found</h3>
                        <p>There are no books in the database yet.</p>
                        <a href="admin-book-add.jsp" class="btn btn-primary">
                            <i class="fas fa-plus"></i> Add Your First Book
                        </a>
                    </div>
                    <% } else { %>
                    <table>
                        <thead>
                            <tr>
                                <th>Cover</th>
                                <th>Title & ISBN</th>
                                <th>Author</th>
                                <th>Category</th>
                                <th>Price</th>
                                <th>Stock</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% 
                            for(Map<String, Object> book : books) { 
                                // Get stock safely
                                int stock = 0;
                                Object stockObj = book.get("stock");
                                if(stockObj != null) {
                                    if(stockObj instanceof Integer) {
                                        stock = (Integer) stockObj;
                                    } else if(stockObj instanceof String) {
                                        try {
                                            stock = Integer.parseInt((String) stockObj);
                                        } catch(NumberFormatException e) {
                                            stock = 0;
                                        }
                                    } else if(stockObj instanceof Number) {
                                        stock = ((Number) stockObj).intValue();
                                    }
                                }
                                
                                // Get other values safely
                                String title = book.get("title") != null ? book.get("title").toString() : "Untitled";
                                String author = book.get("author") != null ? book.get("author").toString() : "Unknown";
                                String isbn = book.get("isbn") != null ? book.get("isbn").toString() : "N/A";
                                String price = book.get("price") != null ? book.get("price").toString() : "0.00";
                                String category = book.get("category") != null ? book.get("category").toString() : "Uncategorized";
                                String image = book.get("image") != null ? book.get("image").toString() : "";
                                String id = book.get("id") != null ? book.get("id").toString() : "";
                            %>
                            <tr>
                                <td>
                                    <% if(image != null && !image.trim().isEmpty()) { %>
                                    <img src="<%= image %>" alt="<%= title %>" class="book-image" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                                    <% } %>
                                    <div class="book-image" style="display: <%= (image == null || image.trim().isEmpty()) ? "flex" : "none" %>; align-items: center; justify-content: center; color: #999;">
                                        <i class="fas fa-book"></i>
                                    </div>
                                </td>
                                <td>
                                    <strong style="color: var(--dark); display: block; margin-bottom: 5px;"><%= title %></strong>
                                    <small style="color: var(--gray);">ISBN: <%= isbn %></small>
                                </td>
                                <td><%= author %></td>
                                <td>
                                    <span style="background: rgba(108, 99, 255, 0.1); color: var(--primary); padding: 5px 10px; border-radius: 20px; font-size: 0.85rem; display: inline-block;">
                                        <%= category %>
                                    </span>
                                </td>
                                <td style="font-weight: 600; color: var(--dark);">$<%= price %></td>
                                <td>
                                    <span class="status-badge <%= stock > 0 ? "status-in-stock" : "status-out-of-stock" %>">
                                        <%= stock > 0 ? "In Stock (" + stock + ")" : "Out of Stock" %>
                                    </span>
                                </td>
                                <td>
                                    <div class="action-buttons">
                                        <a href="admin-book-edit.jsp?id=<%= id %>" class="btn-edit">
                                            <i class="fas fa-edit"></i> Edit
                                        </a>
                                        <a href="book-details.jsp?id=<%= id %>" class="btn-view" target="_blank">
                                            <i class="fas fa-eye"></i> View
                                        </a>
                                        <a href="admin-books.jsp?action=delete&id=<%= id %>" 
                                           class="btn-delete"
                                           onclick="return confirm('Are you sure you want to delete this book? This action cannot be undone.')">
                                            <i class="fas fa-trash"></i> Delete
                                        </a>
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                    <% } %>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Search functionality
        document.addEventListener('DOMContentLoaded', function() {
            const searchInput = document.getElementById('searchInput');
            if(searchInput) {
                searchInput.addEventListener('input', function(e) {
                    const searchTerm = e.target.value.toLowerCase().trim();
                    const rows = document.querySelectorAll('tbody tr');
                    
                    rows.forEach(row => {
                        const text = row.textContent.toLowerCase();
                        row.style.display = text.includes(searchTerm) ? '' : 'none';
                    });
                });
            }
            
            // Close message on click
            document.querySelectorAll('.close-message').forEach(button => {
                button.addEventListener('click', function() {
                    this.parentElement.style.display = 'none';
                });
            });
            
            // Handle image errors
            document.querySelectorAll('.book-image[src]').forEach(img => {
                img.addEventListener('error', function() {
                    this.style.display = 'none';
                    const fallback = this.nextElementSibling;
                    if(fallback && fallback.classList.contains('book-image')) {
                        fallback.style.display = 'flex';
                    }
                });
            });
        });
    </script>
</body>
</html>