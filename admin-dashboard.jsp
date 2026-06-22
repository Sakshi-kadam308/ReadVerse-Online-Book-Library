<%@ page contentType="text/html; charset=ISO-8859-1" %>
<%@ page import="java.sql.*" %>
<%@ include file="db_config.jsp" %>
<%
    // Check if admin is logged in
    String adminId = (String) session.getAttribute("admin_id");
    if(adminId == null) {
        response.sendRedirect("login.jsp?user_type=admin");
        return;
    }
%>

<%
    // Get counts for dashboard
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;
    
    int totalUsers = 0;
    int totalBooks = 0;
    int totalCategories = 0;
    int totalOrders = 0;
    double totalRevenue = 0;
    
    try {
        conn = getConnection();
        stmt = conn.createStatement();
        
        // Get total users
        rs = stmt.executeQuery("SELECT COUNT(*) as count FROM users");
        if(rs.next()) totalUsers = rs.getInt("count");
        
        // Get total books
        rs = stmt.executeQuery("SELECT COUNT(*) as count FROM books");
        if(rs.next()) totalBooks = rs.getInt("count");
        
        // Get total categories
        rs = stmt.executeQuery("SELECT COUNT(*) as count FROM categories");
        if(rs.next()) totalCategories = rs.getInt("count");
        
        // Get total orders and revenue
        rs = stmt.executeQuery("SELECT COUNT(*) as order_count, SUM(total_amount) as revenue FROM orders WHERE status = 'completed'");
        if(rs.next()) {
            totalOrders = rs.getInt("order_count");
            totalRevenue = rs.getDouble("revenue");
            if(rs.wasNull()) totalRevenue = 0;
        }
        
    } catch(Exception e) {
        e.printStackTrace();
    } finally {
        if(rs != null) try { rs.close(); } catch(Exception e) {}
        if(stmt != null) try { stmt.close(); } catch(Exception e) {}
        if(conn != null) try { conn.close(); } catch(Exception e) {}
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <%@ include file="head_include.jsp" %>
    <title>Admin Dashboard - ReadVerse</title>
    <style>
        :root {
            --sidebar-width: 250px;
        }
        
        body {
            background: #f8f9fa;
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
            border-bottom: 1px solid var(--light);
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
        
        .logout-btn {
            background: var(--danger);
            color: white;
            border: none;
            padding: 8px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 0.9rem;
            transition: var(--transition);
        }
        
        .logout-btn:hover {
            background: #d32f2f;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 25px;
            margin-bottom: 40px;
        }
        
        .stat-card {
            background: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: var(--shadow);
            display: flex;
            align-items: center;
            transition: var(--transition);
        }
        
        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        
        .stat-icon {
            width: 70px;
            height: 70px;
            border-radius: 15px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.8rem;
            margin-right: 20px;
            color: white;
        }
        
        .stat-content {
            flex: 1;
        }
        
        .stat-content h3 {
            font-size: 2rem;
            margin: 0 0 5px 0;
            color: var(--dark);
        }
        
        .stat-content p {
            margin: 0;
            color: var(--gray);
            font-size: 0.95rem;
        }
        
        .recent-activity {
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: var(--shadow);
        }
        
        .recent-activity h2 {
            margin-top: 0;
            margin-bottom: 25px;
            color: var(--dark);
            font-size: 1.5rem;
        }
        
        .activity-item {
            display: flex;
            align-items: center;
            padding: 15px;
            border-bottom: 1px solid var(--light);
            transition: var(--transition);
        }
        
        .activity-item:hover {
            background: var(--light);
        }
        
        .activity-item:last-child {
            border-bottom: none;
        }
        
        .activity-icon {
            width: 45px;
            height: 45px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-right: 15px;
            font-size: 1.2rem;
        }
        
        .activity-content {
            flex: 1;
        }
        
        .activity-content h4 {
            margin: 0 0 5px 0;
            font-size: 1rem;
            color: var(--dark);
        }
        
        .activity-content p {
            margin: 0;
            color: var(--gray);
            font-size: 0.9rem;
        }
        
        .activity-time {
            color: var(--gray);
            font-size: 0.85rem;
            white-space: nowrap;
        }
        
        @media (max-width: 768px) {
            .admin-sidebar {
                width: 100%;
                height: auto;
                position: relative;
            }
            
            .admin-content {
                margin-left: 0;
            }
            
            .stats-grid {
                grid-template-columns: 1fr;
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
                <ul class="nav flex-column">
                    <li class="nav-item">
                        <a class="nav-link active" href="admin-dashboard.jsp">
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
                <h1><i class="fas fa-tachometer-alt"></i> Dashboard</h1>
                <div class="admin-info">
                    <div class="admin-avatar">
                        <%= session.getAttribute("admin_full_name").toString().charAt(0) %>
                    </div>
                    <div>
                        <h4 style="margin: 0; font-size: 1.1rem;"><%= session.getAttribute("admin_full_name") %></h4>
                        <p style="margin: 0; font-size: 0.9rem; color: var(--gray);"><%= session.getAttribute("admin_role") %></p>
                    </div>
                    <a href="logout.jsp?type=admin" class="logout-btn">
                        <i class="fas fa-sign-out-alt"></i> Logout
                    </a>
                </div>
            </div>
            
            <!-- Stats Grid -->
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
                        <i class="fas fa-users"></i>
                    </div>
                    <div class="stat-content">
                        <h3><%= totalUsers %></h3>
                        <p>Total Users</p>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);">
                        <i class="fas fa-book"></i>
                    </div>
                    <div class="stat-content">
                        <h3><%= totalBooks %></h3>
                        <p>Total Books</p>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);">
                        <i class="fas fa-tags"></i>
                    </div>
                    <div class="stat-content">
                        <h3><%= totalCategories %></h3>
                        <p>Categories</p>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);">
                        <i class="fas fa-dollar-sign"></i>
                    </div>
                    <div class="stat-content">
                        <h3>$<%= String.format("%.2f", totalRevenue) %></h3>
                        <p>Total Revenue</p>
                    </div>
                </div>
            </div>
            
            <!-- Recent Activity -->
            <div class="recent-activity">
                <h2><i class="fas fa-history"></i> Recent Activity</h2>
                
                <div class="activity-item">
                    <div class="activity-icon" style="background: rgba(108, 99, 255, 0.1); color: var(--primary);">
                        <i class="fas fa-user-plus"></i>
                    </div>
                    <div class="activity-content">
                        <h4>New User Registration</h4>
                        <p>John Doe registered as a new user</p>
                    </div>
                    <div class="activity-time">10 mins ago</div>
                </div>
                
                <div class="activity-item">
                    <div class="activity-icon" style="background: rgba(76, 175, 80, 0.1); color: #4CAF50;">
                        <i class="fas fa-shopping-cart"></i>
                    </div>
                    <div class="activity-content">
                        <h4>New Order Placed</h4>
                        <p>Order #ORD-2024-001 placed successfully</p>
                    </div>
                    <div class="activity-time">1 hour ago</div>
                </div>
                
                <div class="activity-item">
                    <div class="activity-icon" style="background: rgba(255, 152, 0, 0.1); color: #FF9800;">
                        <i class="fas fa-book"></i>
                    </div>
                    <div class="activity-content">
                        <h4>New Book Added</h4>
                        <p>"The Great Gatsby" added to catalog</p>
                    </div>
                    <div class="activity-time">2 hours ago</div>
                </div>
                
                <div class="activity-item">
                    <div class="activity-icon" style="background: rgba(33, 150, 243, 0.1); color: #2196F3;">
                        <i class="fas fa-tag"></i>
                    </div>
                    <div class="activity-content">
                        <h4>New Category Created</h4>
                        <p>"Science Fiction" category created</p>
                    </div>
                    <div class="activity-time">5 hours ago</div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>