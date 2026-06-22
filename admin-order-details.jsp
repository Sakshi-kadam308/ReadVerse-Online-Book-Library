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
    
    // Get order ID from request
    String orderId = request.getParameter("id");
    if(orderId == null || orderId.isEmpty()) {
        response.sendRedirect("admin-orders.jsp");
        return;
    }
    
    // Handle status update
    if("POST".equals(request.getMethod())) {
        String status = request.getParameter("status");
        String notes = request.getParameter("admin_notes");
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = getConnection();
            String sql = "UPDATE orders SET status = ?, admin_notes = ? WHERE order_id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, status);
            pstmt.setString(2, notes);
            pstmt.setInt(3, Integer.parseInt(orderId));
            pstmt.executeUpdate();
            
            session.setAttribute("message", "Order updated successfully!");
            session.setAttribute("message_type", "success");
            
            // Refresh page
            response.sendRedirect("admin-order-details.jsp?id=" + orderId);
            return;
            
        } catch(Exception e) {
            e.printStackTrace();
            session.setAttribute("message", "Error updating order: " + e.getMessage());
            session.setAttribute("message_type", "error");
        } finally {
            if(pstmt != null) { try { pstmt.close(); } catch(Exception e) {} }
            if(conn != null) { try { conn.close(); } catch(Exception e) {} }
        }
    }
%>

<%
    // Get order details
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    Map<String, Object> order = new HashMap<String, Object>();
    List<Map<String, Object>> orderItems = new ArrayList<Map<String, Object>>();
    Map<String, Object> customer = new HashMap<String, Object>();
    
    try {
        conn = getConnection();
        
        // Get order details
        String sql = "SELECT o.*, u.username, u.email, u.full_name, " +
                    "COUNT(oi.order_item_id) as item_count, " +
                    "SUM(oi.quantity) as total_items " +
                    "FROM orders o " +
                    "LEFT JOIN users u ON o.user_id = u.user_id " +
                    "LEFT JOIN order_items oi ON o.order_id = oi.order_id " +
                    "WHERE o.order_id = ? " +
                    "GROUP BY o.order_id";
        
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, Integer.parseInt(orderId));
        rs = pstmt.executeQuery();
        
        if(rs.next()) {
            order.put("id", rs.getObject("order_id"));
            order.put("order_number", "ORD-" + String.format("%06d", rs.getInt("order_id")));
            order.put("user_id", rs.getObject("user_id"));
            order.put("total_amount", rs.getObject("total_amount"));
            order.put("status", rs.getObject("status"));
            order.put("payment_method", rs.getObject("payment_method"));
            order.put("shipping_address", rs.getObject("shipping_address"));
            order.put("admin_notes", rs.getObject("admin_notes"));
            order.put("created_at", rs.getObject("created_at"));
            order.put("updated_at", rs.getObject("updated_at"));
            order.put("item_count", rs.getObject("item_count"));
            order.put("total_items", rs.getObject("total_items"));
            
            // Customer info
            customer.put("username", rs.getObject("username"));
            customer.put("email", rs.getObject("email"));
            customer.put("full_name", rs.getObject("full_name"));
        } else {
            response.sendRedirect("admin-orders.jsp");
            return;
        }
        
        rs.close();
        pstmt.close();
        
        // Get order items
        sql = "SELECT oi.*, b.title, b.author, b.isbn, b.price as unit_price, b.image_url " +
              "FROM order_items oi " +
              "LEFT JOIN books b ON oi.book_id = b.book_id " +
              "WHERE oi.order_id = ?";
        
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, Integer.parseInt(orderId));
        rs = pstmt.executeQuery();
        
        while(rs.next()) {
            Map<String, Object> item = new HashMap<String, Object>();
            item.put("id", rs.getObject("order_item_id"));
            item.put("book_id", rs.getObject("book_id"));
            item.put("title", rs.getObject("title"));
            item.put("author", rs.getObject("author"));
            item.put("isbn", rs.getObject("isbn"));
            item.put("quantity", rs.getObject("quantity"));
            item.put("price", rs.getObject("price"));
            item.put("unit_price", rs.getObject("unit_price"));
            item.put("image_url", rs.getObject("image_url"));
            
            // Calculate subtotal
            int quantity = rs.getInt("quantity");
            double price = rs.getDouble("price");
            item.put("subtotal", quantity * price);
            
            orderItems.add(item);
        }
        
    } catch(Exception e) {
        e.printStackTrace();
        response.sendRedirect("admin-orders.jsp");
        return;
    } finally {
        if(rs != null) { try { rs.close(); } catch(Exception e) {} }
        if(pstmt != null) { try { pstmt.close(); } catch(Exception e) {} }
        if(conn != null) { try { conn.close(); } catch(Exception e) {} }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Order #<%= order.get("order_number") %> - ReadVerse Admin</title>
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
            --warning: #FF9800;
            --info: #2196F3;
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
        
        .order-header {
            background: white;
            border-radius: var(--border-radius);
            padding: 25px;
            margin-bottom: 25px;
            box-shadow: var(--shadow);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .order-info h2 {
            font-size: 1.8rem;
            color: var(--dark);
            margin: 0 0 10px 0;
        }
        
        .order-meta {
            display: flex;
            gap: 20px;
            color: var(--gray);
            font-size: 0.95rem;
        }
        
        .order-actions {
            display: flex;
            gap: 10px;
        }
        
        .status-badge {
            padding: 8px 20px;
            border-radius: 20px;
            font-size: 0.9rem;
            font-weight: 500;
            display: inline-block;
            text-align: center;
            min-width: 100px;
        }
        
        .status-pending {
            background: rgba(255, 152, 0, 0.1);
            color: #E65100;
            border: 1px solid rgba(255, 152, 0, 0.3);
        }
        
        .status-processing {
            background: rgba(33, 150, 243, 0.1);
            color: #0D47A1;
            border: 1px solid rgba(33, 150, 243, 0.3);
        }
        
        .status-completed {
            background: rgba(76, 175, 80, 0.1);
            color: #1B5E20;
            border: 1px solid rgba(76, 175, 80, 0.3);
        }
        
        .status-cancelled {
            background: rgba(244, 67, 54, 0.1);
            color: #B71C1C;
            border: 1px solid rgba(244, 67, 54, 0.3);
        }
        
        .content-grid {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 25px;
        }
        
        @media (max-width: 992px) {
            .content-grid {
                grid-template-columns: 1fr;
            }
        }
        
        .card {
            background: white;
            border-radius: var(--border-radius);
            padding: 25px;
            box-shadow: var(--shadow);
            margin-bottom: 25px;
        }
        
        .card h3 {
            font-size: 1.3rem;
            color: var(--dark);
            margin: 0 0 20px 0;
            padding-bottom: 15px;
            border-bottom: 1px solid #e0e0e0;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .card h3 i {
            color: var(--primary);
        }
        
        .items-table {
            width: 100%;
            border-collapse: collapse;
        }
        
        .items-table th {
            padding: 15px;
            text-align: left;
            font-weight: 600;
            color: var(--dark);
            border-bottom: 2px solid #e0e0e0;
            background: #f8f9fa;
        }
        
        .items-table td {
            padding: 15px;
            border-bottom: 1px solid #e0e0e0;
            color: var(--gray);
            vertical-align: top;
        }
        
        .items-table tr:hover {
            background: #f8f9fa;
        }
        
        .book-info {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .book-image {
            width: 60px;
            height: 80px;
            border-radius: 5px;
            object-fit: cover;
            background: #f0f0f0;
        }
        
        .book-details h4 {
            margin: 0 0 5px 0;
            color: var(--dark);
            font-size: 1rem;
        }
        
        .book-details p {
            margin: 0;
            color: var(--gray);
            font-size: 0.9rem;
        }
        
        .customer-info p {
            margin: 0 0 10px 0;
            color: var(--gray);
        }
        
        .customer-info strong {
            color: var(--dark);
            display: inline-block;
            min-width: 120px;
        }
        
        .order-summary {
            background: #f8f9fa;
            border-radius: 8px;
            padding: 20px;
            margin-top: 20px;
        }
        
        .summary-row {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #e0e0e0;
        }
        
        .summary-row:last-child {
            border-bottom: none;
            font-weight: 600;
            color: var(--dark);
            font-size: 1.1rem;
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
            padding: 12px;
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
            min-height: 100px;
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
            display: flex;
            align-items: center;
            gap: 8px;
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
        
        .btn-secondary {
            background: var(--gray);
            color: white;
        }
        
        .btn-secondary:hover {
            background: #555;
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
        
        .order-timeline {
            margin-top: 20px;
        }
        
        .timeline-item {
            display: flex;
            gap: 15px;
            margin-bottom: 20px;
            padding-bottom: 20px;
            border-bottom: 1px solid #e0e0e0;
        }
        
        .timeline-item:last-child {
            border-bottom: none;
            margin-bottom: 0;
            padding-bottom: 0;
        }
        
        .timeline-icon {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: var(--light);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--primary);
            font-size: 1.2rem;
            flex-shrink: 0;
        }
        
        .timeline-content h4 {
            margin: 0 0 5px 0;
            color: var(--dark);
            font-size: 1rem;
        }
        
        .timeline-content p {
            margin: 0;
            color: var(--gray);
            font-size: 0.9rem;
        }
        
        .timeline-time {
            color: var(--gray);
            font-size: 0.85rem;
            margin-top: 5px;
        }
        
        .print-btn {
            margin-left: auto;
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
            
            .order-header {
                flex-direction: column;
                gap: 20px;
                align-items: flex-start;
            }
            
            .order-meta {
                flex-direction: column;
                gap: 10px;
            }
            
            .order-actions {
                width: 100%;
                justify-content: flex-start;
            }
            
            .items-table {
                display: block;
                overflow-x: auto;
            }
            
            .book-info {
                flex-direction: column;
                align-items: flex-start;
                gap: 10px;
            }
            
            .form-actions {
                flex-direction: column;
            }
        }
        
        .invoice-section {
            background: white;
            border-radius: var(--border-radius);
            padding: 30px;
            margin-top: 30px;
            box-shadow: var(--shadow);
        }
        
        .invoice-header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #e0e0e0;
        }
        
        .invoice-header h2 {
            color: var(--primary);
            margin: 0 0 10px 0;
        }
        
        .invoice-meta {
            display: flex;
            justify-content: space-between;
            margin-bottom: 30px;
        }
        
        .invoice-from, .invoice-to {
            flex: 1;
        }
        
        .invoice-title {
            font-weight: 600;
            color: var(--dark);
            margin-bottom: 10px;
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
                        <a class="nav-link" href="admin-category.jsp">
                            <i class="fas fa-tags"></i> Categories
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link active" href="admin-orders.jsp">
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
                <h1><i class="fas fa-file-invoice"></i> Order Details</h1>
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
            
            <!-- Order Header -->
            <div class="order-header">
                <div class="order-info">
                    <h2><%= order.get("order_number") %></h2>
                    <div class="order-meta">
                        <span><i class="far fa-calendar"></i> <%= order.get("created_at") %></span>
                        <span><i class="fas fa-user"></i> <%= customer.get("full_name") %></span>
                        <span><i class="fas fa-shopping-bag"></i> <%= order.get("total_items") %> items</span>
                    </div>
                </div>
                <div class="order-actions">
                    <span class="status-badge status-<%= order.get("status") %>">
                        <%= ((String) order.get("status")).substring(0, 1).toUpperCase() + ((String) order.get("status")).substring(1) %>
                    </span>
                    <a href="admin-orders.jsp" class="btn btn-outline">
                        <i class="fas fa-arrow-left"></i> Back to Orders
                    </a>
                    <button class="btn btn-secondary" onclick="window.print()">
                        <i class="fas fa-print"></i> Print Invoice
                    </button>
                </div>
            </div>
            
            <!-- Main Content Grid -->
            <div class="content-grid">
                <!-- Left Column -->
                <div>
                    <!-- Order Items -->
                    <div class="card">
                        <h3><i class="fas fa-shopping-basket"></i> Order Items (<%= order.get("item_count") %>)</h3>
                        
                        <table class="items-table">
                            <thead>
                                <tr>
                                    <th>Product</th>
                                    <th>Price</th>
                                    <th>Quantity</th>
                                    <th>Subtotal</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% 
                                double orderTotal = 0;
                                for(Map<String, Object> item : orderItems) { 
                                    String title = item.get("title") != null ? item.get("title").toString() : "Unknown Book";
                                    String author = item.get("author") != null ? item.get("author").toString() : "Unknown Author";
                                    String isbn = item.get("isbn") != null ? item.get("isbn").toString() : "";
                                    String imageUrl = item.get("image_url") != null ? item.get("image_url").toString() : "";
                                    int quantity = Integer.parseInt(item.get("quantity").toString());
                                    double price = Double.parseDouble(item.get("price").toString());
                                    double subtotal = quantity * price;
                                    orderTotal += subtotal;
                                %>
                                <tr>
                                    <td>
                                        <div class="book-info">
                                            <% if(imageUrl != null && !imageUrl.isEmpty()) { %>
                                            <img src="<%= imageUrl %>" alt="<%= title %>" class="book-image">
                                            <% } else { %>
                                            <div class="book-image" style="display: flex; align-items: center; justify-content: center; background: #f0f0f0; color: #999;">
                                                <i class="fas fa-book"></i>
                                            </div>
                                            <% } %>
                                            <div class="book-details">
                                                <h4><%= title %></h4>
                                                <p><i class="fas fa-user"></i> <%= author %></p>
                                                <p><i class="fas fa-barcode"></i> <%= isbn %></p>
                                            </div>
                                        </div>
                                    </td>
                                    <td>$<%= String.format("%.2f", price) %></td>
                                    <td><%= quantity %></td>
                                    <td style="font-weight: 600;">$<%= String.format("%.2f", subtotal) %></td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                        
                        <!-- Order Summary -->
                        <div class="order-summary">
                            <div class="summary-row">
                                <span>Subtotal:</span>
                                <span>$<%= String.format("%.2f", orderTotal) %></span>
                            </div>
                            <div class="summary-row">
                                <span>Shipping:</span>
                                <span>$0.00</span>
                            </div>
                            <div class="summary-row">
                                <span>Tax:</span>
                                <span>$0.00</span>
                            </div>
                            <div class="summary-row">
                                <span>Total:</span>
                                <span>$<%= order.get("total_amount") %></span>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Order Timeline -->
                    <div class="card">
                        <h3><i class="fas fa-history"></i> Order Timeline</h3>
                        <div class="order-timeline">
                            <div class="timeline-item">
                                <div class="timeline-icon">
                                    <i class="fas fa-shopping-cart"></i>
                                </div>
                                <div class="timeline-content">
                                    <h4>Order Placed</h4>
                                    <p>Order was placed successfully</p>
                                    <div class="timeline-time"><%= order.get("created_at") %></div>
                                </div>
                            </div>
                            
                            <% if("processing".equals(order.get("status")) || "completed".equals(order.get("status"))) { %>
                            <div class="timeline-item">
                                <div class="timeline-icon">
                                    <i class="fas fa-cog"></i>
                                </div>
                                <div class="timeline-content">
                                    <h4>Processing</h4>
                                    <p>Order is being processed</p>
                                    <div class="timeline-time"><%= order.get("updated_at") != null ? order.get("updated_at") : order.get("created_at") %></div>
                                </div>
                            </div>
                            <% } %>
                            
                            <% if("completed".equals(order.get("status"))) { %>
                            <div class="timeline-item">
                                <div class="timeline-icon">
                                    <i class="fas fa-check-circle"></i>
                                </div>
                                <div class="timeline-content">
                                    <h4>Completed</h4>
                                    <p>Order was completed successfully</p>
                                    <div class="timeline-time"><%= order.get("updated_at") %></div>
                                </div>
                            </div>
                            <% } %>
                            
                            <% if("cancelled".equals(order.get("status"))) { %>
                            <div class="timeline-item">
                                <div class="timeline-icon">
                                    <i class="fas fa-times-circle"></i>
                                </div>
                                <div class="timeline-content">
                                    <h4>Cancelled</h4>
                                    <p>Order was cancelled</p>
                                    <div class="timeline-time"><%= order.get("updated_at") %></div>
                                </div>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>
                
                <!-- Right Column -->
                <div>
                    <!-- Customer Information -->
                    <div class="card">
                        <h3><i class="fas fa-user"></i> Customer Information</h3>
                        <div class="customer-info">
                            <p><strong>Name:</strong> <%= customer.get("full_name") %></p>
                            <p><strong>Email:</strong> <%= customer.get("email") %></p>
                            <p><strong>Username:</strong> <%= customer.get("username") %></p>
                            <p><strong>Customer ID:</strong> <%= order.get("user_id") %></p>
                        </div>
                    </div>
                    
                    <!-- Shipping & Payment -->
                    <div class="card">
                        <h3><i class="fas fa-truck"></i> Shipping & Payment</h3>
                        <div class="customer-info">
                            <p><strong>Payment Method:</strong> <%= order.get("payment_method") != null ? order.get("payment_method") : "Not specified" %></p>
                            <p><strong>Shipping Address:</strong></p>
                            <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-top: 10px; font-size: 0.9rem;">
                                <%= order.get("shipping_address") != null ? ((String) order.get("shipping_address")).replace("\n", "<br>") : "Not specified" %>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Update Order Status -->
                    <div class="card">
                        <h3><i class="fas fa-edit"></i> Update Order</h3>
                        <form method="POST" action="admin-order-details.jsp?id=<%= orderId %>">
                            <div class="form-group">
                                <label for="status">Order Status</label>
                                <select id="status" name="status" class="form-control">
                                    <option value="pending" <%= "pending".equals(order.get("status")) ? "selected" : "" %>>Pending</option>
                                    <option value="processing" <%= "processing".equals(order.get("status")) ? "selected" : "" %>>Processing</option>
                                    <option value="completed" <%= "completed".equals(order.get("status")) ? "selected" : "" %>>Completed</option>
                                    <option value="cancelled" <%= "cancelled".equals(order.get("status")) ? "selected" : "" %>>Cancelled</option>
                                </select>
                            </div>
                            
                            <div class="form-group">
                                <label for="admin_notes">Admin Notes</label>
                                <textarea id="admin_notes" name="admin_notes" class="form-control" 
                                          placeholder="Add any notes or comments about this order..."><%= order.get("admin_notes") != null ? order.get("admin_notes") : "" %></textarea>
                            </div>
                            
                            <div class="form-actions">
                                <button type="submit" class="btn btn-primary">
                                    <i class="fas fa-save"></i> Update Order
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
            
            <!-- Printable Invoice Section -->
            <div class="invoice-section" id="printableInvoice" style="display: none;">
                <div class="invoice-header">
                    <h2><i class="fas fa-book-open"></i> ReadVerse</h2>
                    <p>Digital Bookstore Invoice</p>
                </div>
                
                <div class="invoice-meta">
                    <div class="invoice-from">
                        <div class="invoice-title">From:</div>
                        <p>ReadVerse Bookstore<br>
                        123 Book Street<br>
                        Reading City, RC 12345<br>
                        support@readverse.com<br>
                        (555) 123-4567</p>
                    </div>
                    
                    <div class="invoice-to">
                        <div class="invoice-title">To:</div>
                        <p><%= customer.get("full_name") %><br>
                        <%= customer.get("email") %><br>
                        Order #: <%= order.get("order_number") %><br>
                        Date: <%= order.get("created_at") %></p>
                    </div>
                </div>
                
                <table class="items-table">
                    <thead>
                        <tr>
                            <th>Description</th>
                            <th>Qty</th>
                            <th>Unit Price</th>
                            <th>Amount</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for(Map<String, Object> item : orderItems) { 
                            String title = item.get("title") != null ? item.get("title").toString() : "Unknown Book";
                            String author = item.get("author") != null ? item.get("author").toString() : "";
                            int quantity = Integer.parseInt(item.get("quantity").toString());
                            double price = Double.parseDouble(item.get("price").toString());
                            double subtotal = quantity * price;
                        %>
                        <tr>
                            <td><%= title %><br><small>by <%= author %></small></td>
                            <td><%= quantity %></td>
                            <td>$<%= String.format("%.2f", price) %></td>
                            <td>$<%= String.format("%.2f", subtotal) %></td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
                
                <div style="text-align: right; margin-top: 30px;">
                    <div style="display: inline-block; text-align: left;">
                        <p><strong>Subtotal: $<%= String.format("%.2f", orderTotal) %></strong></p>
                        <p>Shipping: $0.00</p>
                        <p>Tax: $0.00</p>
                        <h3 style="margin-top: 20px;">Total: $<%= order.get("total_amount") %></h3>
                    </div>
                </div>
                
                <div style="margin-top: 40px; padding-top: 20px; border-top: 2px solid #e0e0e0; text-align: center; color: var(--gray); font-size: 0.9rem;">
                    <p>Thank you for your purchase!<br>
                    This is a digital invoice. No physical goods will be shipped.</p>
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
            
            // Handle image errors
            var images = document.querySelectorAll('.book-image[src]');
            images.forEach(function(img) {
                img.addEventListener('error', function() {
                    this.style.display = 'none';
                    var fallback = document.createElement('div');
                    fallback.className = 'book-image';
                    fallback.style.cssText = 'display: flex; align-items: center; justify-content: center; background: #f0f0f0; color: #999; width: 60px; height: 80px;';
                    fallback.innerHTML = '<i class="fas fa-book"></i>';
                    this.parentNode.insertBefore(fallback, this.nextSibling);
                });
            });
            
            // Print functionality
            window.onbeforeprint = function() {
                document.getElementById('printableInvoice').style.display = 'block';
                document.querySelector('.admin-container').style.display = 'none';
            };
            
            window.onafterprint = function() {
                document.getElementById('printableInvoice').style.display = 'none';
                document.querySelector('.admin-container').style.display = 'flex';
            };
        });
        
        // Custom print function
        function printInvoice() {
            var printContents = document.getElementById('printableInvoice').innerHTML;
            var originalContents = document.body.innerHTML;
            
            document.body.innerHTML = printContents;
            window.print();
            document.body.innerHTML = originalContents;
            location.reload(); // Reload to restore event listeners
        }
    </script>
</body>
</html>