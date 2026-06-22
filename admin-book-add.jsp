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
        String title = request.getParameter("title");
        String author = request.getParameter("author");
        String isbn = request.getParameter("isbn");
        String description = request.getParameter("description");
        String priceStr = request.getParameter("price");
        String categoryId = request.getParameter("category_id");
        String stockStr = request.getParameter("stock_quantity");
        String imageUrl = request.getParameter("image_url");
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = getConnection();
            String sql = "INSERT INTO books (title, author, isbn, description, price, category_id, stock_quantity, image_url) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, title);
            pstmt.setString(2, author);
            pstmt.setString(3, isbn);
            pstmt.setString(4, description != null ? description : "");
            pstmt.setDouble(5, Double.parseDouble(priceStr));
            pstmt.setString(6, categoryId != null && !categoryId.isEmpty() ? categoryId : null);
            pstmt.setInt(7, Integer.parseInt(stockStr));
            pstmt.setString(8, imageUrl != null && !imageUrl.trim().isEmpty() ? imageUrl : null);
            
            pstmt.executeUpdate();
            
            session.setAttribute("message", "Book added successfully!");
            session.setAttribute("message_type", "success");
            response.sendRedirect("admin-books.jsp");
            return;
            
        } catch(Exception e) {
            e.printStackTrace();
            session.setAttribute("message", "Error adding book: " + e.getMessage());
            session.setAttribute("message_type", "error");
        } finally {
            if(pstmt != null) { try { pstmt.close(); } catch(Exception e) {} }
            if(conn != null) { try { conn.close(); } catch(Exception e) {} }
        }
    }
%>

<%
    // Get all categories for dropdown
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;
    List<Map<String, Object>> categories = new ArrayList<Map<String, Object>>();
    
    try {
        conn = getConnection();
        stmt = conn.createStatement();
        rs = stmt.executeQuery("SELECT * FROM categories ORDER BY name ASC");
        
        while(rs.next()) {
            Map<String, Object> category = new HashMap<String, Object>();
            category.put("id", rs.getObject("category_id"));
            category.put("name", rs.getObject("name"));
            categories.add(category);
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
    <title>Add New Book - ReadVerse Admin</title>
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
            --success: #4CAF50;
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
        
        .form-container {
            background: white;
            border-radius: var(--border-radius);
            padding: 40px;
            box-shadow: var(--shadow);
            max-width: 800px;
            margin: 0 auto;
        }
        
        .form-header {
            margin-bottom: 30px;
        }
        
        .form-header h2 {
            font-size: 1.8rem;
            color: var(--dark);
            margin-bottom: 10px;
        }
        
        .form-header p {
            color: var(--gray);
            margin: 0;
        }
        
        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 25px;
        }
        
        @media (max-width: 768px) {
            .form-grid {
                grid-template-columns: 1fr;
            }
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group.full-width {
            grid-column: 1 / -1;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: var(--dark);
            font-weight: 500;
            font-size: 0.95rem;
        }
        
        .form-group label .required {
            color: var(--danger);
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
            min-height: 150px;
            resize: vertical;
        }
        
        select.form-control {
            appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' fill='%23666666' viewBox='0 0 16 16'%3E%3Cpath d='M7.247 11.14 2.451 5.658C1.885 5.013 2.345 4 3.204 4h9.592a1 1 0 0 1 .753 1.659l-4.796 5.48a1 1 0 0 1-1.506 0z'/%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: right 15px center;
            background-size: 16px;
            padding-right: 40px;
        }
        
        .form-actions {
            display: flex;
            gap: 15px;
            margin-top: 30px;
            padding-top: 25px;
            border-top: 1px solid #e0e0e0;
        }
        
        .btn {
            display: inline-block;
            padding: 14px 28px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 500;
            cursor: pointer;
            transition: var(--transition);
            border: none;
            font-family: inherit;
            font-size: 1rem;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }
        
        .btn-primary {
            background: var(--primary);
            color: white;
            flex: 1;
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
            border-left: 4px solid var(--success);
        }
        
        .message.error {
            background: rgba(244, 67, 54, 0.1);
            color: #C62828;
            border-left: 4px solid var(--danger);
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
        
        .image-preview {
            margin-top: 10px;
            text-align: center;
        }
        
        .image-preview img {
            max-width: 200px;
            max-height: 200px;
            border-radius: 8px;
            border: 2px solid #e0e0e0;
            display: none;
        }
        
        .help-text {
            font-size: 0.85rem;
            color: var(--gray);
            margin-top: 5px;
            display: block;
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
            
            .form-container {
                padding: 25px;
            }
            
            .form-actions {
                flex-direction: column;
            }
        }
        
        .form-tips {
            background: rgba(108, 99, 255, 0.05);
            border-radius: 8px;
            padding: 20px;
            margin-top: 30px;
            border-left: 4px solid var(--primary);
        }
        
        .form-tips h4 {
            margin-top: 0;
            margin-bottom: 10px;
            color: var(--primary);
            font-size: 1.1rem;
        }
        
        .form-tips ul {
            margin: 0;
            padding-left: 20px;
            color: var(--gray);
        }
        
        .form-tips li {
            margin-bottom: 8px;
            font-size: 0.9rem;
        }
        
        /* Indian Rupee symbol styling */
        .rupee-symbol {
            position: relative;
            display: inline-block;
        }
        
        .rupee-symbol::before {
            content: "₹";
            position: absolute;
            left: 10px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--gray);
            font-weight: 500;
        }
        
        .price-input {
            padding-left: 30px !important;
        }
    </style>
    <script>
        function previewImage(input) {
            var preview = document.getElementById('imagePreview');
            if (input.files && input.files[0]) {
                var reader = new FileReader();
                reader.onload = function(e) {
                    preview.src = e.target.result;
                    preview.style.display = 'block';
                }
                reader.readAsDataURL(input.files[0]);
            } else {
                preview.style.display = 'none';
            }
        }
        
        function updateImagePreview() {
            var url = document.getElementById('image_url').value;
            var preview = document.getElementById('imagePreview');
            if (url) {
                preview.src = url;
                preview.style.display = 'block';
            } else {
                preview.style.display = 'none';
            }
        }
    </script>
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
                    <li class="nav-link active">
                        <a class="nav-link" href="admin-books.jsp">
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
                <h1><i class="fas fa-book"></i> Add New Book</h1>
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
            
            <div class="form-container">
                <div class="form-header">
                    <h2><i class="fas fa-plus-circle"></i> Book Information</h2>
                    <p>Fill in the details below to add a new book to the store</p>
                </div>
                
                <form method="POST" action="admin-book-add.jsp">
                    <div class="form-grid">
                        <!-- Left Column -->
                        <div>
                            <div class="form-group">
                                <label for="title">Book Title <span class="required">*</span></label>
                                <input type="text" id="title" name="title" class="form-control" required 
                                       placeholder="Enter book title">
                            </div>
                            
                            <div class="form-group">
                                <label for="author">Author <span class="required">*</span></label>
                                <input type="text" id="author" name="author" class="form-control" required 
                                       placeholder="Enter author name">
                            </div>
                            
                            <div class="form-group">
                                <label for="isbn">ISBN <span class="required">*</span></label>
                                <input type="text" id="isbn" name="isbn" class="form-control" required 
                                       placeholder="Enter ISBN number">
                                <span class="help-text">Unique ISBN identifier (e.g., 978-3-16-148410-0)</span>
                            </div>
                            
                            <div class="form-group">
                                <label for="price">Price (₹) <span class="required">*</span></label>
                                <div class="rupee-symbol">
                                    <input type="number" id="price" name="price" class="form-control price-input" required 
                                           min="0" step="0.01" placeholder="0.00">
                                </div>
                                <span class="help-text">Price in Indian Rupees</span>
                            </div>
                        </div>
                        
                        <!-- Right Column -->
                        <div>
                            <div class="form-group">
                                <label for="category_id">Category</label>
                                <select id="category_id" name="category_id" class="form-control">
                                    <option value="">Select Category</option>
                                    <% for(Map<String, Object> category : categories) { 
                                        String catId = category.get("id") != null ? category.get("id").toString() : "";
                                        String catName = category.get("name") != null ? category.get("name").toString() : "";
                                    %>
                                    <option value="<%= catId %>"><%= catName %></option>
                                    <% } %>
                                </select>
                                <span class="help-text">Optional - book can be uncategorized</span>
                            </div>
                            
                            <div class="form-group">
                                <label for="stock_quantity">Stock Quantity <span class="required">*</span></label>
                                <input type="number" id="stock_quantity" name="stock_quantity" class="form-control" required 
                                       min="0" value="0" placeholder="0">
                                <span class="help-text">Number of copies available</span>
                            </div>
                            
                            <div class="form-group">
                                <label for="image_url">Cover Image URL</label>
                                <input type="text" id="image_url" name="image_url" class="form-control" 
                                       placeholder="https://example.com/book-cover.jpg"
                                       onkeyup="updateImagePreview()" onchange="updateImagePreview()">
                                <span class="help-text">Optional - direct URL to book cover image</span>
                                <div class="image-preview">
                                    <img id="imagePreview" src="" alt="Image Preview" style="display: none;">
                                </div>
                            </div>
                            
                            <!-- Alternatively, file upload option
                            <div class="form-group">
                                <label for="image_upload">Upload Cover Image</label>
                                <input type="file" id="image_upload" name="image_upload" class="form-control" 
                                       accept="image/*" onchange="previewImage(this)">
                                <span class="help-text">JPEG, PNG, or GIF (Max 2MB)</span>
                            </div>
                            -->
                        </div>
                        
                        <!-- Full Width Fields -->
                        <div class="form-group full-width">
                            <label for="description">Description</label>
                            <textarea id="description" name="description" class="form-control" 
                                      rows="5" placeholder="Enter book description..."></textarea>
                            <span class="help-text">Provide a detailed description of the book</span>
                        </div>
                    </div>
                    
                    <div class="form-tips">
                        <h4><i class="fas fa-lightbulb"></i> Tips for Adding Books:</h4>
                        <ul>
                            <li>Ensure ISBN is unique - it cannot be duplicated in the system</li>
                            <li>Use descriptive titles that customers can easily search for</li>
                            <li>Set appropriate stock levels to manage inventory</li>
                            <li>High-quality cover images improve book visibility</li>
                            <li>Detailed descriptions help customers make informed decisions</li>
                            <li>Price should be in Indian Rupees (₹)</li>
                        </ul>
                    </div>
                    
                    <div class="form-actions">
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-save"></i> Add Book
                        </button>
                        <a href="admin-books.jsp" class="btn btn-outline">
                            <i class="fas fa-times"></i> Cancel
                        </a>
                    </div>
                </form>
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
            
            // Auto-calculate ISBN format
            var isbnInput = document.getElementById('isbn');
            if(isbnInput) {
                isbnInput.addEventListener('blur', function() {
                    var value = this.value.replace(/[-\s]/g, '');
                    if(value.length === 13) {
                        this.value = value.replace(/(\d{3})(\d{1})(\d{4})(\d{4})(\d{1})/, '$1-$2-$3-$4-$5');
                    } else if(value.length === 10) {
                        this.value = value.replace(/(\d{1})(\d{3})(\d{5})(\d{1})/, '$1-$2-$3-$4');
                    }
                });
            }
            
            // Price formatting
            var priceInput = document.getElementById('price');
            if(priceInput) {
                priceInput.addEventListener('blur', function() {
                    var value = parseFloat(this.value);
                    if(!isNaN(value)) {
                        this.value = value.toFixed(2);
                    }
                });
            }
        });
    </script>
</body>
</html>