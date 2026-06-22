<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.text.SimpleDateFormat, java.text.DecimalFormat" %>
<%@ include file="db_config.jsp" %>
<%
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    if(username == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    String userIdStr = (String) session.getAttribute("user_id");
    
    List<Map<String, Object>> orders = new ArrayList<>();
    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy, hh:mm a");
    DecimalFormat df = new DecimalFormat("#0.00");
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = getConnection();
        
        String sql = "SELECT o.*, COUNT(oi.id) as item_count, " +
                     "SUM(oi.total_price) as total_amount " +
                     "FROM orders o " +
                     "LEFT JOIN order_items oi ON o.id = oi.order_id " +
                     "WHERE o.user_id = ? " +
                     "GROUP BY o.id " +
                     "ORDER BY o.created_at DESC";
        
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, Integer.parseInt(userIdStr));
        rs = pstmt.executeQuery();
        
        while(rs.next()) {
            Map<String, Object> order = new HashMap<>();
            order.put("order_number", rs.getString("order_number"));
            order.put("total_amount", rs.getDouble("total_amount"));
            order.put("payment_method", rs.getString("payment_method"));
            order.put("status", rs.getString("status"));
            order.put("created_at", rs.getTimestamp("created_at"));
            order.put("item_count", rs.getInt("item_count"));
            orders.add(order);
        }
        
    } catch(Exception e) {
        e.printStackTrace();
    } finally {
        try { if(rs != null) rs.close(); } catch(Exception e) {}
        try { if(pstmt != null) pstmt.close(); } catch(Exception e) {}
        try { if(conn != null) conn.close(); } catch(Exception e) {}
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <%@ include file="head_include.jsp" %>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Orders - ReadVerse</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        /* Add order history styles similar to library page */
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f5f7fa; }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #6c63ff, #5952d4); color: white; padding: 30px; border-radius: 15px; text-align: center; margin-bottom: 30px; }
        .orders-table { background: white; border-radius: 10px; overflow: hidden; box-shadow: 0 5px 15px rgba(0,0,0,0.1); }
        table { width: 100%; border-collapse: collapse; }
        th { background: #f8f9fa; padding: 15px; text-align: left; font-weight: 600; color: #333; }
        td { padding: 15px; border-top: 1px solid #eee; }
        .status { padding: 5px 12px; border-radius: 20px; font-size: 0.85rem; font-weight: 600; }
        .status-completed { background: #d4edda; color: #155724; }
        .status-pending { background: #fff3cd; color: #856404; }
        .btn-view { background: #6c63ff; color: white; padding: 8px 16px; border-radius: 6px; text-decoration: none; font-size: 0.9rem; }
    </style>
</head>
<body>
    <%@ include file="header.jsp" %>
    
    <div class="container">
        <div class="header">
            <h1><i class="fas fa-receipt"></i> My Orders</h1>
            <p>View your purchase history and order details</p>
        </div>
        
        <% if(!orders.isEmpty()) { %>
        <div class="orders-table">
            <table>
                <thead>
                    <tr>
                        <th>Order #</th>
                        <th>Date</th>
                        <th>Items</th>
                        <th>Total</th>
                        <th>Payment Method</th>
                        <th>Status</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                    <% for(Map<String, Object> order : orders) { %>
                    <tr>
                        <td><strong><%= order.get("order_number") %></strong></td>
                        <td><%= dateFormat.format(order.get("created_at")) %></td>
                        <td><%= order.get("item_count") %> item(s)</td>
                        <td>$<%= df.format(order.get("total_amount")) %></td>
                        <td><%= order.get("payment_method") %></td>
                        <td>
                            <span class="status status-<%= order.get("status") %>">
                                <%= order.get("status") %>
                            </span>
                        </td>
                        <td>
                            <a href="payment_success.jsp?order_id=<%= order.get("order_number") %>" class="btn-view">
                                <i class="fas fa-eye"></i> View
                            </a>
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
        <% } else { %>
        <div style="text-align: center; padding: 50px; background: white; border-radius: 10px;">
            <i class="fas fa-shopping-bag" style="font-size: 4rem; color: #ddd; margin-bottom: 20px;"></i>
            <h3 style="color: #666; margin-bottom: 15px;">No orders yet</h3>
            <p style="color: #888; margin-bottom: 25px;">You haven't placed any orders yet.</p>
            <a href="browse.jsp" class="btn-view" style="display: inline-block;">
                <i class="fas fa-shopping-bag"></i> Start Shopping
            </a>
        </div>
        <% } %>
    </div>
    
    <%@ include file="footer.jsp" %>
</body>
</html>