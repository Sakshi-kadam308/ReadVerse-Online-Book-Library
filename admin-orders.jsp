<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ include file="db_config.jsp" %>
<%
    // Check if admin is logged in
    String adminId = (String) session.getAttribute("admin_id");
    if(adminId == null) {
        response.sendRedirect("login.jsp?user_type=admin");
        return;
    }
    
    // Handle order status update
    if("POST".equals(request.getMethod())) {
        String orderId = request.getParameter("order_id");
        String status = request.getParameter("status");
        String notes = request.getParameter("notes");
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = getConnection();
            String sql = "UPDATE orders SET status = ?, admin_notes = ?, updated_at = NOW() WHERE order_id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, status);
            pstmt.setString(2, notes);
            pstmt.setInt(3, Integer.parseInt(orderId));
            pstmt.executeUpdate();
            
            session.setAttribute("message", "Order status updated successfully!");
            session.setAttribute("message_type", "success");
            
        } catch(Exception e) {
            e.printStackTrace();
            session.setAttribute("message", "Error updating order: " + e.getMessage());
            session.setAttribute("message_type", "error");
        } finally {
            if(pstmt != null) { try { pstmt.close(); } catch(Exception e) {} }
            if(conn != null) { try { conn.close(); } catch(Exception e) {} }
        }
        
        response.sendRedirect("admin-orders.jsp");
        return;
    }
%>

<%
    // Get all orders with user information
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;
    List<Map<String, Object>> orders = new ArrayList<Map<String, Object>>();
    
    String filter = request.getParameter("filter");
    DecimalFormat df = new DecimalFormat("#,##0.00");
    
    try {
        conn = getConnection();
        stmt = conn.createStatement();
        
        // Build query based on filter
        String query = "SELECT o.*, u.username, u.email, u.full_name, u.phone, " +
                      "(SELECT COUNT(*) FROM order_items oi WHERE oi.order_id = o.order_id) as item_count, " +
                      "(SELECT SUM(oi.quantity) FROM order_items oi WHERE oi.order_id = o.order_id) as total_items " +
                      "FROM orders o " +
                      "LEFT JOIN users u ON o.user_id = u.user_id ";
        
        if(filter != null && !filter.isEmpty() && !filter.equals("all")) {
            query += "WHERE o.status = '" + filter + "' ";
        }
        
        query += "ORDER BY o.created_at DESC";
        
        rs = stmt.executeQuery(query);
        
        while(rs.next()) {
            Map<String, Object> order = new HashMap<String, Object>();
            order.put("id", rs.getObject("order_id"));
            order.put("order_number", rs.getObject("order_number"));
            order.put("user_id", rs.getObject("user_id"));
            order.put("username", rs.getObject("username"));
            order.put("email", rs.getObject("email"));
            order.put("full_name", rs.getObject("full_name"));
            order.put("phone", rs.getObject("phone"));
            order.put("total_amount", rs.getObject("total_amount"));
            order.put("subtotal", rs.getObject("subtotal"));
            order.put("tax", rs.getObject("tax"));
            order.put("shipping", rs.getObject("shipping"));
            order.put("status", rs.getObject("status"));
            order.put("payment_method", rs.getObject("payment_method"));
            order.put("payment_status", rs.getObject("payment_status"));
            order.put("shipping_address", rs.getObject("shipping_address"));
            order.put("billing_address", rs.getObject("billing_address"));
            order.put("notes", rs.getObject("notes"));
            order.put("admin_notes", rs.getObject("admin_notes"));
            order.put("created_at", rs.getObject("created_at"));
            order.put("updated_at", rs.getObject("updated_at"));
            order.put("item_count", rs.getObject("item_count"));
            order.put("total_items", rs.getObject("total_items"));
            orders.add(order);
        }
        
    } catch(Exception e) {
        e.printStackTrace();
    } finally {
        if(rs != null) { try { rs.close(); } catch(Exception e) {} }
        if(stmt != null) { try { stmt.close(); } catch(Exception e) {} }
        if(conn != null) { try { conn.close(); } catch(Exception e) {} }
    }
    
    // Get order statistics
    int totalOrders = 0;
    int pendingOrders = 0;
    int processingOrders = 0;
    int completedOrders = 0;
    int cancelledOrders = 0;
    double totalRevenue = 0;
    double todayRevenue = 0;
    
    try {
        conn = getConnection();
        stmt = conn.createStatement();
        
        // Total orders
        rs = stmt.executeQuery("SELECT COUNT(*) as count FROM orders");
        if(rs.next()) totalOrders = rs.getInt("count");
        
        // Pending orders
        rs = stmt.executeQuery("SELECT COUNT(*) as count FROM orders WHERE status = 'pending'");
        if(rs.next()) pendingOrders = rs.getInt("count");
        
        // Processing orders
        rs = stmt.executeQuery("SELECT COUNT(*) as count FROM orders WHERE status = 'processing'");
        if(rs.next()) processingOrders = rs.getInt("count");
        
        // Completed orders
        rs = stmt.executeQuery("SELECT COUNT(*) as count FROM orders WHERE status = 'completed'");
        if(rs.next()) completedOrders = rs.getInt("count");
        
        // Cancelled orders
        rs = stmt.executeQuery("SELECT COUNT(*) as count FROM orders WHERE status = 'cancelled'");
        if(rs.next()) cancelledOrders = rs.getInt("count");
        
        // Total revenue
        rs = stmt.executeQuery("SELECT SUM(total_amount) as revenue FROM orders WHERE status = 'completed'");
        if(rs.next()) {
            Object revenueObj = rs.getObject("revenue");
            if(revenueObj != null) {
                totalRevenue = rs.getDouble("revenue");
            }
        }
        
        // Today's revenue
        rs = stmt.executeQuery("SELECT SUM(total_amount) as revenue FROM orders WHERE status = 'completed' AND DATE(created_at) = CURDATE()");
        if(rs.next()) {
            Object revenueObj = rs.getObject("revenue");
            if(revenueObj != null) {
                todayRevenue = rs.getDouble("revenue");
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
    <title>Manage Orders - ReadVerse Admin</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        :root {
            --sidebar-width: 250px;
            --primary: #6c63ff;
            --primary-light: #8a84ff;
            --primary-dark: #554fd8;
            --secondary: #667eea;
            --success: #10b981;
            --warning: #f59e0b;
            --danger: #ef4444;
            --info: #3b82f6;
            --light: #f8f9fa;
            --dark: #1f2937;
            --gray: #6b7280;
            --gradient-primary: linear-gradient(135deg, var(--primary) 0%, var(--secondary) 100%);
            --gradient-success: linear-gradient(135deg, var(--success) 0%, #059669 100%);
            --gradient-warning: linear-gradient(135deg, var(--warning) 0%, #d97706 100%);
            --gradient-danger: linear-gradient(135deg, var(--danger) 0%, #dc2626 100%);
            --gradient-info: linear-gradient(135deg, var(--info) 0%, #2563eb 100%);
            --shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
            --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
            --shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
            --radius: 8px;
            --radius-lg: 12px;
            --radius-xl: 16px;
            --transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: #f3f4f6;
            color: var(--dark);
            line-height: 1.5;
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
            border-right: 1px solid #e5e7eb;
        }
        
        .admin-content {
            flex: 1;
            margin-left: var(--sidebar-width);
            padding: 30px;
            max-width: calc(100% - var(--sidebar-width));
        }
        
        .sidebar-header {
            padding: 25px 20px;
            background: var(--gradient-primary);
            color: white;
        }
        
        .sidebar-header h3 {
            margin: 0;
            font-size: 1.5rem;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .sidebar-header p {
            margin: 5px 0 0 0;
            opacity: 0.9;
            font-size: 0.875rem;
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
            margin: 4px 0;
        }
        
        .nav-link {
            padding: 12px 20px;
            color: var(--dark);
            display: flex;
            align-items: center;
            text-decoration: none;
            transition: var(--transition);
            border-left: 3px solid transparent;
            font-weight: 500;
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
            font-weight: 600;
        }
        
        .nav-link i {
            width: 20px;
            margin-right: 12px;
            font-size: 1.1rem;
        }
        
        .admin-header {
            background: white;
            padding: 25px 30px;
            border-radius: var(--radius-xl);
            box-shadow: var(--shadow);
            margin-bottom: 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 3px solid var(--primary);
        }
        
        .admin-header h1 {
            font-size: 1.875rem;
            color: var(--dark);
            margin: 0;
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .admin-header h1 i {
            color: var(--primary);
        }
        
        .admin-info {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .admin-avatar {
            width: 50px;
            height: 50px;
            background: var(--gradient-primary);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 700;
            font-size: 1.25rem;
            box-shadow: 0 4px 12px rgba(108, 99, 255, 0.3);
        }
        
        /* Statistics Cards */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: white;
            padding: 25px;
            border-radius: var(--radius-xl);
            box-shadow: var(--shadow);
            transition: var(--transition);
            position: relative;
            overflow: hidden;
        }
        
        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: var(--shadow-lg);
        }
        
        .stat-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 4px;
        }
        
        .stat-card:nth-child(1)::before { background: var(--gradient-primary); }
        .stat-card:nth-child(2)::before { background: var(--gradient-warning); }
        .stat-card:nth-child(3)::before { background: var(--gradient-success); }
        .stat-card:nth-child(4)::before { background: var(--gradient-info); }
        .stat-card:nth-child(5)::before { background: var(--gradient-danger); }
        .stat-card:nth-child(6)::before { background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%); }
        
        .stat-icon {
            width: 60px;
            height: 60px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 20px;
            font-size: 1.5rem;
            color: white;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        
        .stat-card:nth-child(1) .stat-icon { background: var(--gradient-primary); }
        .stat-card:nth-child(2) .stat-icon { background: var(--gradient-warning); }
        .stat-card:nth-child(3) .stat-icon { background: var(--gradient-success); }
        .stat-card:nth-child(4) .stat-icon { background: var(--gradient-info); }
        .stat-card:nth-child(5) .stat-icon { background: var(--gradient-danger); }
        .stat-card:nth-child(6) .stat-icon { background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%); }
        
        .stat-content h3 {
            font-size: 2rem;
            margin: 0 0 5px 0;
            color: var(--dark);
            font-weight: 700;
        }
        
        .stat-content p {
            margin: 0;
            color: var(--gray);
            font-size: 0.875rem;
            font-weight: 500;
        }
        
        .stat-trend {
            display: flex;
            align-items: center;
            gap: 5px;
            margin-top: 10px;
            font-size: 0.875rem;
            font-weight: 600;
            padding: 4px 8px;
            border-radius: 20px;
            background: rgba(16, 185, 129, 0.1);
            color: var(--success);
            width: fit-content;
        }
        
        /* Filter Controls */
        .filter-tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 25px;
            flex-wrap: wrap;
            background: white;
            padding: 15px 20px;
            border-radius: var(--radius-lg);
            box-shadow: var(--shadow);
        }
        
        .filter-tab {
            padding: 8px 20px;
            border-radius: 20px;
            text-decoration: none;
            font-size: 0.875rem;
            font-weight: 500;
            transition: var(--transition);
            border: 2px solid transparent;
            background: var(--light);
            color: var(--dark);
        }
        
        .filter-tab:hover {
            transform: translateY(-2px);
        }
        
        .filter-tab.active {
            background: var(--primary);
            color: white;
            border-color: var(--primary);
            box-shadow: 0 4px 12px rgba(108, 99, 255, 0.3);
        }
        
        .filter-tab.pending.active { background: var(--warning); border-color: var(--warning); }
        .filter-tab.processing.active { background: var(--info); border-color: var(--info); }
        .filter-tab.completed.active { background: var(--success); border-color: var(--success); }
        .filter-tab.cancelled.active { background: var(--danger); border-color: var(--danger); }
        
        /* Orders Table */
        .orders-table {
            background: white;
            border-radius: var(--radius-xl);
            box-shadow: var(--shadow);
            overflow: hidden;
        }
        
        .table-header {
            padding: 25px 30px;
            border-bottom: 1px solid #e5e7eb;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 20px;
        }
        
        .table-header h3 {
            margin: 0;
            font-size: 1.25rem;
            color: var(--dark);
            font-weight: 600;
        }
        
        .search-box {
            position: relative;
            width: 300px;
        }
        
        .search-box input {
            width: 100%;
            padding: 12px 20px 12px 45px;
            border: 2px solid #e5e7eb;
            border-radius: var(--radius-lg);
            font-size: 0.875rem;
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
            padding: 20px;
            overflow-x: auto;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 1200px;
        }
        
        thead {
            background: #f9fafb;
        }
        
        th {
            padding: 16px;
            text-align: left;
            font-weight: 600;
            color: var(--dark);
            border-bottom: 2px solid #e5e7eb;
            font-size: 0.875rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        
        td {
            padding: 16px;
            border-bottom: 1px solid #e5e7eb;
            color: var(--gray);
            font-size: 0.875rem;
        }
        
        tbody tr:hover {
            background: rgba(108, 99, 255, 0.02);
        }
        
        /* Order Status Badges */
        .status-badge {
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 0.75rem;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        
        .status-pending {
            background: rgba(245, 158, 11, 0.1);
            color: #92400e;
            border: 1px solid rgba(245, 158, 11, 0.2);
        }
        
        .status-processing {
            background: rgba(59, 130, 246, 0.1);
            color: #1e40af;
            border: 1px solid rgba(59, 130, 246, 0.2);
        }
        
        .status-completed {
            background: rgba(16, 185, 129, 0.1);
            color: #065f46;
            border: 1px solid rgba(16, 185, 129, 0.2);
        }
        
        .status-cancelled {
            background: rgba(239, 68, 68, 0.1);
            color: #991b1b;
            border: 1px solid rgba(239, 68, 68, 0.2);
        }
        
        /* Customer Info */
        .customer-info {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        
        .customer-avatar {
            width: 40px;
            height: 40px;
            background: var(--gradient-primary);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
            font-size: 1rem;
        }
        
        .customer-details {
            display: flex;
            flex-direction: column;
        }
        
        .customer-name {
            font-weight: 600;
            color: var(--dark);
            margin-bottom: 2px;
        }
        
        .customer-email {
            font-size: 0.75rem;
            color: var(--gray);
        }
        
        /* Payment Status */
        .payment-badge {
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 0.75rem;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .payment-paid {
            background: rgba(16, 185, 129, 0.1);
            color: var(--success);
            border: 1px solid rgba(16, 185, 129, 0.2);
        }
        
        .payment-pending {
            background: rgba(245, 158, 11, 0.1);
            color: var(--warning);
            border: 1px solid rgba(245, 158, 11, 0.2);
        }
        
        .payment-failed {
            background: rgba(239, 68, 68, 0.1);
            color: var(--danger);
            border: 1px solid rgba(239, 68, 68, 0.2);
        }
        
        /* Action Buttons */
        .action-buttons {
            display: flex;
            gap: 8px;
        }
        
        .btn-action {
            padding: 8px 16px;
            border-radius: var(--radius);
            font-size: 0.875rem;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: var(--transition);
            border: none;
            cursor: pointer;
            font-weight: 500;
        }
        
        .btn-view {
            background: rgba(59, 130, 246, 0.1);
            color: var(--info);
            border: 1px solid rgba(59, 130, 246, 0.2);
        }
        
        .btn-view:hover {
            background: var(--info);
            color: white;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
        }
        
        .btn-update {
            background: rgba(108, 99, 255, 0.1);
            color: var(--primary);
            border: 1px solid rgba(108, 99, 255, 0.2);
        }
        
        .btn-update:hover {
            background: var(--primary);
            color: white;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(108, 99, 255, 0.3);
        }
        
        .btn-print {
            background: rgba(107, 114, 128, 0.1);
            color: var(--gray);
            border: 1px solid rgba(107, 114, 128, 0.2);
        }
        
        .btn-print:hover {
            background: var(--gray);
            color: white;
            transform: translateY(-2px);
        }
        
        /* Empty State */
        .empty-state {
            text-align: center;
            padding: 80px 40px;
        }
        
        .empty-state i {
            font-size: 4rem;
            color: #d1d5db;
            margin-bottom: 20px;
        }
        
        .empty-state h3 {
            color: var(--gray);
            margin-bottom: 10px;
            font-size: 1.5rem;
            font-weight: 600;
        }
        
        .empty-state p {
            color: var(--gray);
            margin-bottom: 25px;
            max-width: 400px;
            margin-left: auto;
            margin-right: auto;
        }
        
        /* Messages */
        .message {
            padding: 16px 24px;
            border-radius: var(--radius-lg);
            margin-bottom: 25px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .message.success {
            background: rgba(16, 185, 129, 0.1);
            color: #065f46;
            border-left: 4px solid var(--success);
        }
        
        .message.error {
            background: rgba(239, 68, 68, 0.1);
            color: #991b1b;
            border-left: 4px solid var(--danger);
        }
        
        .close-message {
            background: none;
            border: none;
            color: inherit;
            cursor: pointer;
            font-size: 1.25rem;
            opacity: 0.7;
            padding: 0;
        }
        
        .close-message:hover {
            opacity: 1;
        }
        
        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            z-index: 2000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0,0,0,0.5);
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        
        .modal-content {
            background-color: white;
            border-radius: var(--radius-xl);
            width: 90%;
            max-width: 800px;
            max-height: 90vh;
            overflow-y: auto;
            box-shadow: var(--shadow-xl);
        }
        
        .modal-header {
            padding: 25px 30px;
            border-bottom: 1px solid #e5e7eb;
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: var(--gradient-primary);
            color: white;
            border-radius: var(--radius-xl) var(--radius-xl) 0 0;
        }
        
        .modal-header h3 {
            margin: 0;
            font-size: 1.5rem;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .close-modal {
            background: none;
            border: none;
            font-size: 1.5rem;
            color: white;
            cursor: pointer;
            padding: 0;
        }
        
        .modal-body {
            padding: 30px;
        }
        
        .modal-section {
            margin-bottom: 30px;
        }
        
        .modal-section:last-child {
            margin-bottom: 0;
        }
        
        .modal-section h4 {
            font-size: 1.125rem;
            color: var(--dark);
            margin-bottom: 15px;
            font-weight: 600;
        }
        
        .order-details-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 25px;
        }
        
        .detail-card {
            background: #f9fafb;
            padding: 20px;
            border-radius: var(--radius-lg);
            border-left: 4px solid var(--primary);
        }
        
        .detail-label {
            font-size: 0.75rem;
            color: var(--gray);
            text-transform: uppercase;
            margin-bottom: 5px;
            font-weight: 600;
        }
        
        .detail-value {
            font-size: 1rem;
            color: var(--dark);
            font-weight: 500;
        }
        
        .order-items-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
            background: white;
            border-radius: var(--radius);
            overflow: hidden;
            box-shadow: var(--shadow);
        }
        
        .order-items-table th {
            background: #f3f4f6;
            padding: 12px 15px;
            font-size: 0.75rem;
            text-transform: uppercase;
            color: var(--gray);
        }
        
        .order-items-table td {
            padding: 15px;
            border-bottom: 1px solid #e5e7eb;
        }
        
        .item-info {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .item-image {
            width: 60px;
            height: 80px;
            background: #f3f4f6;
            border-radius: 6px;
            overflow: hidden;
            flex-shrink: 0;
        }
        
        .item-details {
            flex: 1;
        }
        
        .item-title {
            font-weight: 600;
            color: var(--dark);
            margin-bottom: 5px;
        }
        
        .item-meta {
            font-size: 0.75rem;
            color: var(--gray);
        }
        
        .amount-summary {
            background: #f9fafb;
            padding: 20px;
            border-radius: var(--radius-lg);
            margin-top: 20px;
        }
        
        .summary-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px dashed #e5e7eb;
        }
        
        .summary-row:last-child {
            border-bottom: none;
            font-weight: 700;
            color: var(--dark);
            font-size: 1.125rem;
            padding-top: 12px;
        }
        
        /* Form Styles */
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-label {
            display: block;
            margin-bottom: 8px;
            color: var(--dark);
            font-weight: 500;
        }
        
        .form-control {
            width: 100%;
            padding: 12px 16px;
            border: 2px solid #e5e7eb;
            border-radius: var(--radius);
            font-size: 0.875rem;
            font-family: inherit;
            transition: var(--transition);
        }
        
        .form-control:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(108, 99, 255, 0.1);
        }
        
        .textarea-control {
            min-height: 100px;
            resize: vertical;
        }
        
        .form-select {
            appearance: none;
            background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e");
            background-position: right 0.5rem center;
            background-repeat: no-repeat;
            background-size: 1.5em 1.5em;
            padding-right: 2.5rem;
        }
        
        .modal-footer {
            padding: 20px 30px;
            border-top: 1px solid #e5e7eb;
            display: flex;
            justify-content: flex-end;
            gap: 15px;
        }
        
        .btn {
            padding: 12px 24px;
            border-radius: var(--radius);
            font-weight: 500;
            font-size: 0.875rem;
            text-decoration: none;
            cursor: pointer;
            transition: var(--transition);
            border: 2px solid transparent;
            font-family: inherit;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .btn-primary {
            background: var(--primary);
            color: white;
        }
        
        .btn-primary:hover {
            background: var(--primary-dark);
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(108, 99, 255, 0.3);
        }
        
        .btn-secondary {
            background: white;
            color: var(--dark);
            border-color: #e5e7eb;
        }
        
        .btn-secondary:hover {
            background: #f9fafb;
            transform: translateY(-2px);
        }
        
        /* Responsive Design */
        @media (max-width: 1024px) {
            .admin-sidebar {
                width: 70px;
            }
            
            .admin-content {
                margin-left: 70px;
                max-width: calc(100% - 70px);
            }
            
            .sidebar-header h3 span,
            .sidebar-header p,
            .nav-link span {
                display: none;
            }
            
            .nav-link {
                justify-content: center;
                padding: 15px;
            }
            
            .nav-link i {
                margin-right: 0;
                font-size: 1.25rem;
            }
        }
        
        @media (max-width: 768px) {
            .admin-content {
                padding: 20px;
            }
            
            .admin-header {
                flex-direction: column;
                gap: 15px;
                align-items: flex-start;
                padding: 20px;
            }
            
            .stats-grid {
                grid-template-columns: repeat(2, 1fr);
            }
            
            .table-header {
                flex-direction: column;
                align-items: flex-start;
                gap: 15px;
            }
            
            .search-box {
                width: 100%;
            }
            
            .action-buttons {
                flex-direction: column;
                gap: 5px;
            }
            
            .modal-content {
                width: 95%;
            }
        }
        
        @media (max-width: 480px) {
            .stats-grid {
                grid-template-columns: 1fr;
            }
            
            .filter-tabs {
                justify-content: center;
            }
            
            .order-details-grid {
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
                        <a class="nav-link" href="admin-users.jsp">
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
                        <a class="nav-link active" href="admin-orders.jsp">
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
                <h1><i class="fas fa-shopping-cart"></i> Manage Orders</h1>
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
            
            <!-- Order Statistics -->
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon">
                        <i class="fas fa-shopping-cart"></i>
                    </div>
                    <div class="stat-content">
                        <h3><%= totalOrders %></h3>
                        <p>Total Orders</p>
                        <div class="stat-trend">
                            <i class="fas fa-arrow-up"></i>
                            <span>12% from last month</span>
                        </div>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon">
                        <i class="fas fa-clock"></i>
                    </div>
                    <div class="stat-content">
                        <h3><%= pendingOrders %></h3>
                        <p>Pending Orders</p>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon">
                        <i class="fas fa-sync-alt"></i>
                    </div>
                    <div class="stat-content">
                        <h3><%= processingOrders %></h3>
                        <p>Processing</p>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon">
                        <i class="fas fa-check-circle"></i>
                    </div>
                    <div class="stat-content">
                        <h3><%= completedOrders %></h3>
                        <p>Completed</p>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon">
                        <i class="fas fa-times-circle"></i>
                    </div>
                    <div class="stat-content">
                        <h3><%= cancelledOrders %></h3>
                        <p>Cancelled</p>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon">
                        <i class="fas fa-dollar-sign"></i>
                    </div>
                    <div class="stat-content">
                        <h3>$<%= df.format(totalRevenue) %></h3>
                        <p>Total Revenue</p>
                        <div class="stat-trend">
                            <i class="fas fa-arrow-up"></i>
                            <span>18% from last month</span>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Filter Tabs -->
            <div class="filter-tabs">
                <a href="admin-orders.jsp?filter=all" class="filter-tab <%= (filter == null || filter.equals("all")) ? "active" : "" %>">
                    <i class="fas fa-list"></i> All Orders
                </a>
                <a href="admin-orders.jsp?filter=pending" class="filter-tab pending <%= "pending".equals(filter) ? "active" : "" %>">
                    <i class="fas fa-clock"></i> Pending (<%= pendingOrders %>)
                </a>
                <a href="admin-orders.jsp?filter=processing" class="filter-tab processing <%= "processing".equals(filter) ? "active" : "" %>">
                    <i class="fas fa-sync-alt"></i> Processing (<%= processingOrders %>)
                </a>
                <a href="admin-orders.jsp?filter=completed" class="filter-tab completed <%= "completed".equals(filter) ? "active" : "" %>">
                    <i class="fas fa-check-circle"></i> Completed (<%= completedOrders %>)
                </a>
                <a href="admin-orders.jsp?filter=cancelled" class="filter-tab cancelled <%= "cancelled".equals(filter) ? "active" : "" %>">
                    <i class="fas fa-times-circle"></i> Cancelled (<%= cancelledOrders %>)
                </a>
            </div>
            
            <!-- Orders Table -->
            <div class="orders-table">
                <div class="table-header">
                    <h3><i class="fas fa-list"></i> All Orders (<%= orders.size() %>)</h3>
                    <div class="search-box">
                        <i class="fas fa-search"></i>
                        <input type="text" id="searchInput" placeholder="Search by order ID, customer, email...">
                    </div>
                </div>
                
                <div class="table-container">
                    <% if(orders.isEmpty()) { %>
                    <div class="empty-state">
                        <i class="fas fa-shopping-cart"></i>
                        <h3>No Orders Found</h3>
                        <p>There are no orders in the system yet. When customers place orders, they will appear here.</p>
                    </div>
                    <% } else { %>
                    <table>
                        <thead>
                            <tr>
                                <th>Order ID</th>
                                <th>Customer</th>
                                <th>Date</th>
                                <th>Items</th>
                                <th>Total</th>
                                <th>Status</th>
                                <th>Payment</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% 
                            for(Map<String, Object> order : orders) { 
                                String orderId = order.get("id") != null ? order.get("id").toString() : "";
                                String orderNumber = order.get("order_number") != null ? order.get("order_number").toString() : "ORD-" + String.format("%06d", Integer.parseInt(orderId));
                                String customerName = order.get("full_name") != null ? order.get("full_name").toString() : "Guest";
                                String customerEmail = order.get("email") != null ? order.get("email").toString() : "";
                                String customerPhone = order.get("phone") != null ? order.get("phone").toString() : "";
                                String createdAt = order.get("created_at") != null ? order.get("created_at").toString() : "";
                                String itemCount = order.get("item_count") != null ? order.get("item_count").toString() : "0";
                                String totalItems = order.get("total_items") != null ? order.get("total_items").toString() : "0";
                                Object totalAmountObj = order.get("total_amount");
                                String totalAmount = totalAmountObj != null ? "$" + df.format(Double.parseDouble(totalAmountObj.toString())) : "$0.00";
                                String subtotal = order.get("subtotal") != null ? "$" + df.format(Double.parseDouble(order.get("subtotal").toString())) : "$0.00";
                                String tax = order.get("tax") != null ? "$" + df.format(Double.parseDouble(order.get("tax").toString())) : "$0.00";
                                String shipping = order.get("shipping") != null ? "$" + df.format(Double.parseDouble(order.get("shipping").toString())) : "$0.00";
                                String status = order.get("status") != null ? order.get("status").toString() : "pending";
                                String paymentMethod = order.get("payment_method") != null ? order.get("payment_method").toString() : "N/A";
                                String paymentStatus = order.get("payment_status") != null ? order.get("payment_status").toString() : "pending";
                            %>
                            <tr>
                                <td>
                                    <strong style="color: var(--dark);">#<%= orderNumber %></strong>
                                    <div style="font-size: 0.75rem; color: var(--gray); margin-top: 2px;">
                                        ID: <%= orderId %>
                                    </div>
                                </td>
                                <td>
                                    <div class="customer-info">
                                        <div class="customer-avatar">
                                            <%= customerName.isEmpty() ? "G" : customerName.charAt(0) %>
                                        </div>
                                        <div class="customer-details">
                                            <div class="customer-name"><%= customerName %></div>
                                            <div class="customer-email"><%= customerEmail %></div>
                                            <% if(customerPhone != null && !customerPhone.isEmpty()) { %>
                                            <div class="customer-email"><%= customerPhone %></div>
                                            <% } %>
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <%= createdAt.length() > 10 ? createdAt.substring(0, 10) : createdAt %>
                                </td>
                                <td>
                                    <div style="font-weight: 600; color: var(--dark);">
                                        <%= totalItems %> items
                                    </div>
                                    <div style="font-size: 0.75rem; color: var(--gray);">
                                        <%= itemCount %> products
                                    </div>
                                </td>
                                <td>
                                    <div style="font-weight: 700; color: var(--dark); font-size: 1.125rem;">
                                        <%= totalAmount %>
                                    </div>
                                    <div style="font-size: 0.75rem; color: var(--gray);">
                                        Subtotal: <%= subtotal %>
                                    </div>
                                </td>
                                <td>
                                    <span class="status-badge status-<%= status %>">
                                        <i class="fas fa-circle" style="font-size: 0.5rem;"></i>
                                        <%= status.substring(0, 1).toUpperCase() + status.substring(1) %>
                                    </span>
                                </td>
                                <td>
                                    <div style="margin-bottom: 5px;">
                                        <span class="payment-badge payment-<%= paymentStatus %>">
                                            <%= paymentStatus %>
                                        </span>
                                    </div>
                                    <div style="font-size: 0.75rem; color: var(--gray);">
                                        <%= paymentMethod %>
                                    </div>
                                </td>
                                <td>
                                    <div class="action-buttons">
                                        <button class="btn-action btn-view" onclick="viewOrderDetails('<%= orderId %>', '<%= orderNumber %>')">
                                            <i class="fas fa-eye"></i> View
                                        </button>
                                        <button class="btn-action btn-update" onclick="openUpdateModal('<%= orderId %>', '<%= status %>', '<%= order.get("admin_notes") != null ? order.get("admin_notes").toString() : "" %>')">
                                            <i class="fas fa-edit"></i> Update
                                        </button>
                                        <button class="btn-action btn-print" onclick="printOrder('<%= orderId %>')">
                                            <i class="fas fa-print"></i> Print
                                        </button>
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
    
    <!-- Order Details Modal -->
    <div id="orderDetailsModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h3><i class="fas fa-file-invoice"></i> Order Details - <span id="modalOrderNumber"></span></h3>
                <button class="close-modal" onclick="closeOrderDetailsModal()">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <div class="modal-body">
                <div id="orderDetailsContent">
                    <!-- Content loaded via JavaScript -->
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closeOrderDetailsModal()">
                    <i class="fas fa-times"></i> Close
                </button>
                <button type="button" class="btn btn-primary" onclick="printOrderDetails()">
                    <i class="fas fa-print"></i> Print Invoice
                </button>
            </div>
        </div>
    </div>
    
    <!-- Update Status Modal -->
    <div id="updateModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h3><i class="fas fa-edit"></i> Update Order Status</h3>
                <button class="close-modal" onclick="closeUpdateModal()">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <form id="updateForm" method="POST" action="admin-orders.jsp">
                <input type="hidden" id="modalOrderId" name="order_id">
                <div class="modal-body">
                    <div class="form-group">
                        <label class="form-label">Select New Status</label>
                        <select id="modalStatus" name="status" class="form-control form-select">
                            <option value="pending">Pending</option>
                            <option value="processing">Processing</option>
                            <option value="completed">Completed</option>
                            <option value="cancelled">Cancelled</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Admin Notes</label>
                        <textarea id="modalNotes" name="notes" class="form-control textarea-control" 
                                  placeholder="Add any internal notes about this order..."></textarea>
                    </div>
                    <div style="background: #f9fafb; padding: 15px; border-radius: var(--radius);">
                        <h4 style="margin-top: 0; margin-bottom: 10px; font-size: 0.875rem; color: var(--dark);">Status Guide:</h4>
                        <ul style="margin: 0; padding-left: 20px; color: var(--gray); font-size: 0.875rem;">
                            <li><strong>Pending:</strong> Order placed but not processed</li>
                            <li><strong>Processing:</strong> Order is being prepared for delivery</li>
                            <li><strong>Completed:</strong> Order delivered/shipped successfully</li>
                            <li><strong>Cancelled:</strong> Order cancelled by customer or admin</li>
                        </ul>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeUpdateModal()">
                        <i class="fas fa-times"></i> Cancel
                    </button>
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-save"></i> Update Status
                    </button>
                </div>
            </form>
        </div>
    </div>
    
    <script>
        // Close message on click
        document.addEventListener('DOMContentLoaded', function() {
            // Close message buttons
            document.querySelectorAll('.close-message').forEach(function(button) {
                button.addEventListener('click', function() {
                    this.parentElement.style.display = 'none';
                });
            });
            
            // Auto-hide messages after 5 seconds
            setTimeout(function() {
                document.querySelectorAll('.message').forEach(function(message) {
                    message.style.display = 'none';
                });
            }, 5000);
            
            // Search functionality
            var searchInput = document.getElementById('searchInput');
            if(searchInput) {
                searchInput.addEventListener('input', function(e) {
                    var searchTerm = e.target.value.toLowerCase().trim();
                    var rows = document.querySelectorAll('tbody tr');
                    
                    rows.forEach(function(row) {
                        var text = row.textContent.toLowerCase();
                        row.style.display = text.includes(searchTerm) ? '' : 'none';
                    });
                });
            }
            
            // Add row hover effects
            document.querySelectorAll('tbody tr').forEach(function(row) {
                row.addEventListener('mouseenter', function() {
                    this.style.backgroundColor = 'rgba(108, 99, 255, 0.02)';
                });
                row.addEventListener('mouseleave', function() {
                    this.style.backgroundColor = '';
                });
            });
        });
        
        // View Order Details
        function viewOrderDetails(orderId, orderNumber) {
            document.getElementById('modalOrderNumber').textContent = '#' + orderNumber;
            
            // Show loading state
            document.getElementById('orderDetailsContent').innerHTML = '<div style="text-align: center; padding: 40px;">' +
                '<i class="fas fa-spinner fa-spin" style="font-size: 2rem; color: var(--primary);"></i>' +
                '<p style="margin-top: 15px; color: var(--gray);">Loading order details...</p>' +
            '</div>';
            
            // Show modal
            document.getElementById('orderDetailsModal').style.display = 'flex';
            
            // In a real application, you would fetch order details via AJAX
            // For now, we'll simulate with static content
            setTimeout(function() {
                loadOrderDetails(orderId, orderNumber);
            }, 500);
        }
        
        function loadOrderDetails(orderId, orderNumber) {
            // This is a simulation. In real app, fetch from server via AJAX
            var orderDetails = {
                customerName: "John Doe",
                customerEmail: "john@example.com",
                customerPhone: "+1234567890",
                shippingAddress: "123 Main St, New York, NY 10001, USA",
                billingAddress: "123 Main St, New York, NY 10001, USA",
                orderDate: "2024-01-15 14:30:00",
                status: "Processing",
                paymentMethod: "Credit Card",
                paymentStatus: "Paid",
                items: [
                    { name: "The Great Gatsby", price: 12.99, quantity: 1, total: 12.99 },
                    { name: "To Kill a Mockingbird", price: 14.99, quantity: 2, total: 29.98 },
                    { name: "1984", price: 9.99, quantity: 1, total: 9.99 }
                ],
                subtotal: 52.96,
                tax: 4.77,
                shipping: 0.00,
                total: 57.73,
                notes: "Gift wrapping requested"
            };
            
            var itemsHtml = '';
            orderDetails.items.forEach(function(item) {
                itemsHtml += '<tr>' +
                    '<td>' +
                        '<div class="item-info">' +
                            '<div class="item-image">' +
                                '<div style="width: 100%; height: 100%; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); display: flex; align-items: center; justify-content: center; color: white;">' +
                                    '<i class="fas fa-book"></i>' +
                                '</div>' +
                            '</div>' +
                            '<div class="item-details">' +
                                '<div class="item-title">' + item.name + '</div>' +
                                '<div class="item-meta">Price: $' + item.price.toFixed(2) + '</div>' +
                            '</div>' +
                        '</div>' +
                    '</td>' +
                    '<td style="text-align: center;">' + item.quantity + '</td>' +
                    '<td style="text-align: right;">$' + item.total.toFixed(2) + '</td>' +
                '</tr>';
            });
            
            var notesHtml = '';
            if (orderDetails.notes) {
                notesHtml = '<div class="modal-section">' +
                    '<h4><i class="fas fa-sticky-note"></i> Order Notes</h4>' +
                    '<div class="detail-card">' +
                        '<div class="detail-value">' + orderDetails.notes + '</div>' +
                    '</div>' +
                '</div>';
            }
            
            document.getElementById('orderDetailsContent').innerHTML = 
                '<div class="modal-section">' +
                    '<h4><i class="fas fa-info-circle"></i> Order Information</h4>' +
                    '<div class="order-details-grid">' +
                        '<div class="detail-card">' +
                            '<div class="detail-label">Order Number</div>' +
                            '<div class="detail-value">#' + orderNumber + '</div>' +
                        '</div>' +
                        '<div class="detail-card">' +
                            '<div class="detail-label">Order Date</div>' +
                            '<div class="detail-value">' + orderDetails.orderDate + '</div>' +
                        '</div>' +
                        '<div class="detail-card">' +
                            '<div class="detail-label">Order Status</div>' +
                            '<div class="detail-value">' +
                                '<span class="status-badge status-processing">' + orderDetails.status + '</span>' +
                            '</div>' +
                        '</div>' +
                        '<div class="detail-card">' +
                            '<div class="detail-label">Payment Status</div>' +
                            '<div class="detail-value">' +
                                '<span class="payment-badge payment-paid">' + orderDetails.paymentStatus + '</span>' +
                            '</div>' +
                        '</div>' +
                    '</div>' +
                '</div>' +
                
                '<div class="modal-section">' +
                    '<h4><i class="fas fa-user"></i> Customer Information</h4>' +
                    '<div class="order-details-grid">' +
                        '<div class="detail-card">' +
                            '<div class="detail-label">Customer Name</div>' +
                            '<div class="detail-value">' + orderDetails.customerName + '</div>' +
                        '</div>' +
                        '<div class="detail-card">' +
                            '<div class="detail-label">Email Address</div>' +
                            '<div class="detail-value">' + orderDetails.customerEmail + '</div>' +
                        '</div>' +
                        '<div class="detail-card">' +
                            '<div class="detail-label">Phone Number</div>' +
                            '<div class="detail-value">' + orderDetails.customerPhone + '</div>' +
                        '</div>' +
                        '<div class="detail-card">' +
                            '<div class="detail-label">Payment Method</div>' +
                            '<div class="detail-value">' + orderDetails.paymentMethod + '</div>' +
                        '</div>' +
                    '</div>' +
                '</div>' +
                
                '<div class="modal-section">' +
                    '<h4><i class="fas fa-map-marker-alt"></i> Shipping & Billing Address</h4>' +
                    '<div class="order-details-grid">' +
                        '<div class="detail-card">' +
                            '<div class="detail-label">Shipping Address</div>' +
                            '<div class="detail-value">' + orderDetails.shippingAddress + '</div>' +
                        '</div>' +
                        '<div class="detail-card">' +
                            '<div class="detail-label">Billing Address</div>' +
                            '<div class="detail-value">' + orderDetails.billingAddress + '</div>' +
                        '</div>' +
                    '</div>' +
                '</div>' +
                
                '<div class="modal-section">' +
                    '<h4><i class="fas fa-box"></i> Order Items</h4>' +
                    '<table class="order-items-table">' +
                        '<thead>' +
                            '<tr>' +
                                '<th>Product</th>' +
                                '<th style="text-align: center;">Quantity</th>' +
                                '<th style="text-align: right;">Total</th>' +
                            '</tr>' +
                        '</thead>' +
                        '<tbody>' +
                            itemsHtml +
                        '</tbody>' +
                    '</table>' +
                '</div>' +
                
                '<div class="modal-section">' +
                    '<h4><i class="fas fa-calculator"></i> Order Summary</h4>' +
                    '<div class="amount-summary">' +
                        '<div class="summary-row">' +
                            '<span>Subtotal:</span>' +
                            '<span>$' + orderDetails.subtotal.toFixed(2) + '</span>' +
                        '</div>' +
                        '<div class="summary-row">' +
                            '<span>Tax (9%):</span>' +
                            '<span>$' + orderDetails.tax.toFixed(2) + '</span>' +
                        '</div>' +
                        '<div class="summary-row">' +
                            '<span>Shipping:</span>' +
                            '<span>$' + orderDetails.shipping.toFixed(2) + '</span>' +
                        '</div>' +
                        '<div class="summary-row">' +
                            '<span>Total Amount:</span>' +
                            '<span>$' + orderDetails.total.toFixed(2) + '</span>' +
                        '</div>' +
                    '</div>' +
                '</div>' +
                notesHtml;
        }
        
        function closeOrderDetailsModal() {
            document.getElementById('orderDetailsModal').style.display = 'none';
        }
        
        function printOrderDetails() {
            window.print();
        }
        
        // Update Status Modal
        function openUpdateModal(orderId, currentStatus, adminNotes) {
            document.getElementById('modalOrderId').value = orderId;
            document.getElementById('modalStatus').value = currentStatus;
            document.getElementById('modalNotes').value = adminNotes || '';
            document.getElementById('updateModal').style.display = 'flex';
        }
        
        function closeUpdateModal() {
            document.getElementById('updateModal').style.display = 'none';
        }
        
        // Print order
        function printOrder(orderId) {
            window.open('print-order.jsp?id=' + orderId, '_blank');
        }
        
        // Close modals when clicking outside
        window.onclick = function(event) {
            if (event.target.classList.contains('modal')) {
                event.target.style.display = 'none';
            }
        }
    </script>
</body>
</html>