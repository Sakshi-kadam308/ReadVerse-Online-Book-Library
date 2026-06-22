<%@ page contentType="text/html; charset=ISO-8859-1" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ include file="db_config.jsp" %>
<%
    // Set ISO-8859-1 encoding
    response.setContentType("text/html; charset=ISO-8859-1");
    response.setCharacterEncoding("ISO-8859-1");
    
    // Get category ID from request
    String categoryId = request.getParameter("id");
    String categoryName = "All Categories";
    
    // Get all categories for sidebar
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;
    List<Map<String, Object>> allCategories = new ArrayList<Map<String, Object>>();
    List<Map<String, Object>> books = new ArrayList<Map<String, Object>>();
    
    try {
        conn = getConnection();
        stmt = conn.createStatement();
        
        // Get all categories
        rs = stmt.executeQuery("SELECT * FROM categories ORDER BY name ASC");
        while(rs.next()) {
            Map<String, Object> category = new HashMap<String, Object>();
            category.put("id", rs.getObject("category_id"));
            category.put("name", rs.getObject("name"));
            category.put("description", rs.getObject("description"));
            allCategories.add(category);
        }
        
        // Get books based on category
        String bookQuery;
        if(categoryId != null && !categoryId.isEmpty()) {
            // Get specific category name
            PreparedStatement pstmt = conn.prepareStatement("SELECT name FROM categories WHERE category_id = ?");
            pstmt.setInt(1, Integer.parseInt(categoryId));
            ResultSet catRs = pstmt.executeQuery();
            if(catRs.next()) {
                categoryName = catRs.getString("name");
            }
            catRs.close();
            pstmt.close();
            
            // Get books for specific category
            bookQuery = "SELECT b.*, c.name as category_name FROM books b " +
                       "LEFT JOIN categories c ON b.category_id = c.category_id " +
                       "WHERE b.category_id = ? AND b.stock_quantity > 0 " +
                       "ORDER BY b.created_at DESC";
            PreparedStatement bookStmt = conn.prepareStatement(bookQuery);
            bookStmt.setInt(1, Integer.parseInt(categoryId));
            rs = bookStmt.executeQuery();
        } else {
            // Get all books
            bookQuery = "SELECT b.*, c.name as category_name FROM books b " +
                       "LEFT JOIN categories c ON b.category_id = c.category_id " +
                       "WHERE b.stock_quantity > 0 " +
                       "ORDER BY b.created_at DESC";
            rs = stmt.executeQuery(bookQuery);
        }
        
        // Process books
        while(rs.next()) {
            Map<String, Object> book = new HashMap<String, Object>();
            book.put("id", rs.getObject("book_id"));
            book.put("title", rs.getObject("title"));
            book.put("author", rs.getObject("author"));
            book.put("isbn", rs.getObject("isbn"));
            book.put("description", rs.getObject("description"));
            
            // Handle price - assuming price is in INR
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
    } finally {
        if(rs != null) { try { rs.close(); } catch(Exception e) {} }
        if(stmt != null) { try { stmt.close(); } catch(Exception e) {} }
        if(conn != null) { try { conn.close(); } catch(Exception e) {} }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="ISO-8859-1">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= categoryName %> - ReadVerse</title>
    <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        :root {
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
        
        .header {
            background: var(--gradient-primary);
            padding: 20px 0;
            box-shadow: var(--shadow);
            position: sticky;
            top: 0;
            z-index: 1000;
        }
        
        .header-content {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .logo {
            display: flex;
            align-items: center;
            gap: 10px;
            color: white;
            text-decoration: none;
        }
        
        .logo h1 {
            font-size: 1.8rem;
            margin: 0;
        }
        
        .nav-links {
            display: flex;
            gap: 30px;
            align-items: center;
        }
        
        .nav-link {
            color: white;
            text-decoration: none;
            font-weight: 500;
            transition: var(--transition);
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .nav-link:hover {
            opacity: 0.8;
        }
        
        .user-actions {
            display: flex;
            gap: 15px;
            align-items: center;
        }
        
        .cart-btn, .profile-btn {
            color: white;
            background: rgba(255, 255, 255, 0.1);
            padding: 8px 15px;
            border-radius: 6px;
            text-decoration: none;
            display: flex;
            align-items: center;
            gap: 8px;
            transition: var(--transition);
        }
        
        .cart-btn:hover, .profile-btn:hover {
            background: rgba(255, 255, 255, 0.2);
        }
        
        .container {
            max-width: 1200px;
            margin: 30px auto;
            padding: 0 20px;
            display: grid;
            grid-template-columns: 250px 1fr;
            gap: 30px;
        }
        
        .sidebar {
            background: white;
            border-radius: var(--border-radius);
            padding: 25px;
            box-shadow: var(--shadow);
            height: fit-content;
        }
        
        .sidebar h3 {
            margin-top: 0;
            margin-bottom: 20px;
            color: var(--dark);
            font-size: 1.3rem;
        }
        
        .category-list {
            list-style: none;
            padding: 0;
            margin: 0;
        }
        
        .category-item {
            margin-bottom: 10px;
        }
        
        .category-link {
            display: block;
            padding: 12px 15px;
            color: var(--dark);
            text-decoration: none;
            border-radius: 8px;
            transition: var(--transition);
            border-left: 3px solid transparent;
        }
        
        .category-link:hover {
            background: var(--light);
            color: var(--primary);
            border-left-color: var(--primary);
        }
        
        .category-link.active {
            background: rgba(108, 99, 255, 0.1);
            color: var(--primary);
            border-left-color: var(--primary);
            font-weight: 500;
        }
        
        .main-content {
            background: white;
            border-radius: var(--border-radius);
            padding: 30px;
            box-shadow: var(--shadow);
        }
        
        .page-header {
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 1px solid #e0e0e0;
        }
        
        .page-header h1 {
            font-size: 2rem;
            color: var(--dark);
            margin: 0 0 10px 0;
        }
        
        .page-header p {
            color: var(--gray);
            margin: 0;
        }
        
        .books-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            gap: 25px;
        }
        
        .book-card {
            background: var(--light);
            border-radius: var(--border-radius);
            overflow: hidden;
            transition: var(--transition);
            box-shadow: 0 3px 10px rgba(0,0,0,0.05);
        }
        
        .book-card:hover {
            transform: translateY(-5px);
            box-shadow: var(--shadow);
        }
        
        .book-image {
            width: 100%;
            height: 250px;
            object-fit: cover;
            background: #e0e0e0;
        }
        
        .book-info {
            padding: 20px;
        }
        
        .book-title {
            font-size: 1.2rem;
            color: var(--dark);
            margin: 0 0 8px 0;
            line-height: 1.4;
        }
        
        .book-author {
            color: var(--gray);
            font-size: 0.9rem;
            margin: 0 0 10px 0;
        }
        
        .book-price {
            font-size: 1.3rem;
            font-weight: 600;
            color: var(--primary);
            margin: 0 0 15px 0;
        }
        
        .book-actions {
            display: flex;
            gap: 10px;
        }
        
        .btn-view, .btn-cart {
            flex: 1;
            padding: 10px;
            border-radius: 6px;
            text-decoration: none;
            text-align: center;
            font-weight: 500;
            transition: var(--transition);
            border: none;
            cursor: pointer;
            font-family: inherit;
            font-size: 0.9rem;
        }
        
        .btn-view {
            background: var(--primary);
            color: white;
        }
        
        .btn-view:hover {
            background: #554fd8;
        }
        
        .btn-cart {
            background: rgba(108, 99, 255, 0.1);
            color: var(--primary);
        }
        
        .btn-cart:hover {
            background: rgba(108, 99, 255, 0.2);
        }
        
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            grid-column: 1 / -1;
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
        }
        
        .footer {
            background: var(--dark);
            color: white;
            padding: 40px 0;
            margin-top: 60px;
        }
        
        .footer-content {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 20px;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 40px;
        }
        
        .footer-section h3 {
            margin-bottom: 20px;
            font-size: 1.3rem;
        }
        
        .footer-section p {
            color: #bbb;
            line-height: 1.6;
        }
        
        @media (max-width: 768px) {
            .header-content {
                flex-direction: column;
                gap: 15px;
            }
            
            .nav-links {
                flex-wrap: wrap;
                justify-content: center;
                gap: 15px;
            }
            
            .container {
                grid-template-columns: 1fr;
            }
            
            .books-grid {
                grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            }
        }
        
        @media (max-width: 480px) {
            .books-grid {
                grid-template-columns: 1fr;
            }
            
            .book-actions {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <!-- Header -->
    <header class="header">
        <div class="header-content">
            <a href="index.jsp" class="logo">
                <i class="fas fa-book-open fa-2x"></i>
                <h1>ReadVerse</h1>
            </a>
            
            <div class="nav-links">
                <a href="index.jsp" class="nav-link">
                    <i class="fas fa-home"></i> Home
                </a>
                <a href="category.jsp" class="nav-link active">
                    <i class="fas fa-tags"></i> Categories
                </a>
                <a href="books.jsp" class="nav-link">
                    <i class="fas fa-book"></i> All Books
                </a>
            </div>
            
            <div class="user-actions">
                <%
                String userId = (String) session.getAttribute("user_id");
                if(userId != null) {
                %>
                <a href="cart.jsp" class="cart-btn">
                    <i class="fas fa-shopping-cart"></i>
                    <span>Cart</span>
                    <% if(session.getAttribute("cartCount") != null) { %>
                    <span class="cart-count">(<%= session.getAttribute("cartCount") %>)</span>
                    <% } %>
                </a>
                <a href="profile.jsp" class="profile-btn">
                    <i class="fas fa-user"></i>
                    <span><%= session.getAttribute("username") %></span>
                </a>
                <a href="logout.jsp" class="cart-btn">
                    <i class="fas fa-sign-out-alt"></i>
                    <span>Logout</span>
                </a>
                <% } else { %>
                <a href="login.jsp" class="nav-link">
                    <i class="fas fa-sign-in-alt"></i> Login
                </a>
                <a href="register.jsp" class="nav-link">
                    <i class="fas fa-user-plus"></i> Register
                </a>
                <% } %>
            </div>
        </div>
    </header>
    
    <!-- Main Content -->
    <div class="container">
        <!-- Sidebar with Categories -->
        <aside class="sidebar">
            <h3><i class="fas fa-tags"></i> Categories</h3>
            <ul class="category-list">
                <li class="category-item">
                    <a href="category.jsp" class="category-link <%= categoryId == null ? "active" : "" %>">
                        <i class="fas fa-th-large"></i> All Categories
                    </a>
                </li>
                <% for(Map<String, Object> category : allCategories) { 
                    String catId = category.get("id") != null ? category.get("id").toString() : "";
                    String catName = category.get("name") != null ? category.get("name").toString() : "";
                %>
                <li class="category-item">
                    <a href="category.jsp?id=<%= catId %>" 
                       class="category-link <%= catId.equals(categoryId) ? "active" : "" %>">
                        <i class="fas fa-bookmark"></i> <%= catName %>
                    </a>
                </li>
                <% } %>
            </ul>
        </aside>
        
        <!-- Main Content Area -->
        <main class="main-content">
            <div class="page-header">
                <h1><i class="fas fa-tags"></i> <%= categoryName %></h1>
                <p><%= books.size() %> books found</p>
            </div>
            
            <% if(books.isEmpty()) { %>
            <div class="empty-state">
                <i class="fas fa-book"></i>
                <h3>No Books Found</h3>
                <p>There are no books available in this category at the moment.</p>
                <a href="category.jsp" class="btn btn-primary">
                    <i class="fas fa-arrow-left"></i> Browse All Categories
                </a>
            </div>
            <% } else { %>
            <div class="books-grid">
                <% for(Map<String, Object> book : books) { 
                    String bookId = book.get("id") != null ? book.get("id").toString() : "";
                    String bookTitle = book.get("title") != null ? book.get("title").toString() : "Untitled";
                    String bookAuthor = book.get("author") != null ? book.get("author").toString() : "Unknown Author";
                    String bookPrice = book.get("price") != null ? book.get("price").toString() : "0.00";
                    String bookImage = book.get("image") != null ? book.get("image").toString() : "";
                    String bookCategory = book.get("category") != null ? book.get("category").toString() : "Uncategorized";
                %>
                <div class="book-card">
                    <% if(bookImage != null && !bookImage.isEmpty()) { %>
                    <img src="<%= bookImage %>" alt="<%= bookTitle %>" class="book-image" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                    <div class="book-image" style="display: none; align-items: center; justify-content: center; background: #e0e0e0; color: #999;">
                        <i class="fas fa-book fa-3x"></i>
                    </div>
                    <% } else { %>
                    <div class="book-image" style="display: flex; align-items: center; justify-content: center; background: #e0e0e0; color: #999;">
                        <i class="fas fa-book fa-3x"></i>
                    </div>
                    <% } %>
                    
                    <div class="book-info">
                        <h3 class="book-title"><%= bookTitle %></h3>
                        <p class="book-author"><i class="fas fa-user"></i> <%= bookAuthor %></p>
                        <p class="book-price">&#8377;<%= bookPrice %></p>
                        <p style="color: var(--gray); font-size: 0.9rem; margin-bottom: 15px;">
                            <i class="fas fa-tag"></i> <%= bookCategory %>
                        </p>
                        
                        <div class="book-actions">
                            <a href="book-details.jsp?id=<%= bookId %>" class="btn-view">
                                <i class="fas fa-eye"></i> View Details
                            </a>
                            <% if(userId != null) { %>
                            <a href="cart.jsp?action=add&id=<%= bookId %>" class="btn-cart">
                                <i class="fas fa-cart-plus"></i> Add to Cart
                            </a>
                            <% } %>
                        </div>
                    </div>
                </div>
                <% } %>
            </div>
            <% } %>
        </main>
    </div>
    
    <!-- Footer -->
    <footer class="footer">
        <div class="footer-content">
            <div class="footer-section">
                <h3><i class="fas fa-book-open"></i> ReadVerse</h3>
                <p>Your ultimate destination for digital books and reading materials. Explore thousands of titles across various categories.</p>
            </div>
            
            <div class="footer-section">
                <h3>Quick Links</h3>
                <p>
                    <a href="index.jsp" style="color: #bbb; text-decoration: none;">Home</a><br>
                    <a href="category.jsp" style="color: #bbb; text-decoration: none;">Categories</a><br>
                    <a href="books.jsp" style="color: #bbb; text-decoration: none;">All Books</a><br>
                    <a href="about.jsp" style="color: #bbb; text-decoration: none;">About Us</a>
                </p>
            </div>
            
            <div class="footer-section">
                <h3>Contact Us</h3>
                <p>
                    <i class="fas fa-envelope"></i> support@readverse.com<br>
                    <i class="fas fa-phone"></i> +91 (555) 123-4567<br>
                    <i class="fas fa-map-marker-alt"></i> 123 Book Street, Mumbai, India
                </p>
            </div>
        </div>
    </footer>
    
    <script>
        // Handle image errors with ISO-8859-1 compatibility
        document.addEventListener('DOMContentLoaded', function() {
            var images = document.querySelectorAll('.book-image[src]');
            images.forEach(function(img) {
                img.addEventListener('error', function() {
                    // Find the fallback div next to this image
                    var fallback = this.nextElementSibling;
                    if(fallback && fallback.classList.contains('book-image')) {
                        this.style.display = 'none';
                        fallback.style.display = 'flex';
                    }
                });
            });
        });
    </script>
</body>
</html>