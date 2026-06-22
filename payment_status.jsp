<%@ page contentType="text/html;charset=ISO-8859-1" language="java" %>
<%@ page import="java.sql.*, java.text.DecimalFormat" %>
<%@ include file="db_config.jsp" %>
<%
    // Set ISO-8859-1 encoding
    response.setContentType("text/html; charset=ISO-8859-1");
    response.setCharacterEncoding("ISO-8859-1");
    
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    if(username == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    String userIdStr = (String) session.getAttribute("user_id");
    String paymentId = request.getParameter("id");
    String orderId = request.getParameter("order_id");
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    Map<String, Object> payment = new HashMap<>();
    Map<String, Object> order = new HashMap<>();
    DecimalFormat df = new DecimalFormat("#0.00");
    
    try {
        conn = getConnection();
        
        String sql = "SELECT p.*, o.order_number, o.total_amount, o.status as order_status, " +
                     "o.created_at as order_date " +
                     "FROM payments p " +
                     "JOIN orders o ON p.order_id = o.id " +
                     "WHERE p.user_id = ? ";
        
        if(paymentId != null && !paymentId.isEmpty()) {
            sql += "AND p.payment_id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, Integer.parseInt(userIdStr));
            pstmt.setInt(2, Integer.parseInt(paymentId));
        } else if(orderId != null && !orderId.isEmpty()) {
            sql += "AND o.order_number = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, Integer.parseInt(userIdStr));
            pstmt.setString(2, orderId);
        } else {
            // Get latest payment
            sql += "ORDER BY p.payment_date DESC LIMIT 1";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, Integer.parseInt(userIdStr));
        }
        
        rs = pstmt.executeQuery();
        
        if(rs.next()) {
            payment.put("payment_id", rs.getInt("payment_id"));
            payment.put("payment_method", rs.getString("payment_method"));
            payment.put("payment_status", rs.getString("payment_status"));
            payment.put("razorpay_payment_id", rs.getString("razorpay_payment_id"));
            payment.put("razorpay_order_id", rs.getString("razorpay_order_id"));
            payment.put("amount", rs.getDouble("amount"));
            payment.put("currency", rs.getString("currency"));
            payment.put("payment_date", rs.getTimestamp("payment_date"));
            payment.put("refund_status", rs.getString("refund_status"));
            payment.put("refund_amount", rs.getDouble("refund_amount"));
            
            order.put("order_number", rs.getString("order_number"));
            order.put("total_amount", rs.getDouble("total_amount"));
            order.put("status", rs.getString("order_status"));
            order.put("created_at", rs.getTimestamp("order_date"));
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
    <meta charset="ISO-8859-1">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Status - ReadVerse</title>
    <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
</head>
<body>
    <%@ include file="header.jsp" %>
    
    <div class="container" style="margin: 50px auto; max-width: 800px;">
        <h1 style="margin-bottom: 30px; color: #333;">
            <i class="fas fa-credit-card"></i> Payment Status
        </h1>
        
        <% if(payment.isEmpty()) { %>
        <div style="text-align: center; padding: 50px; background: white; border-radius: 10px; box-shadow: 0 5px 15px rgba(0,0,0,0.1);">
            <i class="fas fa-search" style="font-size: 60px; color: #6c757d; margin-bottom: 20px;"></i>
            <h3 style="color: #6c757d; margin-bottom: 15px;">Payment Not Found</h3>
            <p style="color: #6c757d; margin-bottom: 25px;">No payment information found for your account.</p>
            <a href="my_orders.jsp" class="btn btn-primary">
                <i class="fas fa-list"></i> View My Orders
            </a>
        </div>
        <% } else { %>
        
        <div style="background: white; border-radius: 10px; overflow: hidden; box-shadow: 0 5px 15px rgba(0,0,0,0.1);">
            <!-- Status Header -->
            <div style="background: <%= "completed".equals(payment.get("payment_status")) ? "#28a745" : 
                                       "failed".equals(payment.get("payment_status")) ? "#dc3545" : 
                                       "pending".equals(payment.get("payment_status")) ? "#ffc107" : "#6c63ff" %>; 
                         color: white; padding: 25px; text-align: center;">
                <h2 style="margin: 0 0 10px 0;">
                    <i class="fas fa-<%= "completed".equals(payment.get("payment_status")) ? "check-circle" : 
                                         "failed".equals(payment.get("payment_status")) ? "times-circle" : 
                                         "clock" %>"></i>
                    <%= ((String)payment.get("payment_status")).toUpperCase() %>
                </h2>
                <p style="margin: 0; opacity: 0.9;">Payment Status</p>
            </div>
            
            <!-- Payment Details -->
            <div style="padding: 30px;">
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-bottom: 30px;">
                    <div style="background: #f8f9fa; padding: 20px; border-radius: 8px;">
                        <h4 style="color: #6c757d; margin-bottom: 15px;">
                            <i class="fas fa-info-circle"></i> Payment Details
                        </h4>
                        <div style="display: grid; gap: 10px;">
                            <div style="display: flex; justify-content: space-between;">
                                <span style="color: #6c757d;">Payment ID:</span>
                                <span style="font-weight: 600;"><%= payment.get("razorpay_payment_id") %></span>
                            </div>
                            <div style="display: flex; justify-content: space-between;">
                                <span style="color: #6c757d;">Method:</span>
                                <span style="font-weight: 600; text-transform: capitalize;">
                                    <%= payment.get("payment_method") %>
                                </span>
                            </div>
                            <div style="display: flex; justify-content: space-between;">
                                <span style="color: #6c757d;">Date:</span>
                                <span style="font-weight: 600;">
                                    <%= new java.text.SimpleDateFormat("dd MMM yyyy, hh:mm a").format(payment.get("payment_date")) %>
                                </span>
                            </div>
                            <div style="display: flex; justify-content: space-between;">
                                <span style="color: #6c757d;">Currency:</span>
                                <span style="font-weight: 600;"><%= payment.get("currency") %></span>
                            </div>
                        </div>
                    </div>
                    
                    <div style="background: #f8f9fa; padding: 20px; border-radius: 8px;">
                        <h4 style="color: #6c757d; margin-bottom: 15px;">
                            <i class="fas fa-receipt"></i> Order Details
                        </h4>
                        <div style="display: grid; gap: 10px;">
                            <div style="display: flex; justify-content: space-between;">
                                <span style="color: #6c757d;">Order Number:</span>
                                <span style="font-weight: 600;"><%= order.get("order_number") %></span>
                            </div>
                            <div style="display: flex; justify-content: space-between;">
                                <span style="color: #6c757d;">Order Status:</span>
                                <span style="font-weight: 600; text-transform: capitalize;">
                                    <%= order.get("status") %>
                                </span>
                            </div>
                            <div style="display: flex; justify-content: space-between;">
                                <span style="color: #6c757d;">Order Date:</span>
                                <span style="font-weight: 600;">
                                    <%= new java.text.SimpleDateFormat("dd MMM yyyy, hh:mm a").format(order.get("created_at")) %>
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Amount Section -->
                <div style="background: #e8f5e9; padding: 25px; border-radius: 8px; margin-bottom: 30px; text-align: center;">
                    <div style="font-size: 0.9rem; color: #2e7d32; margin-bottom: 5px;">Total Amount Paid</div>
                    <div style="font-size: 2.5rem; font-weight: 700; color: #2e7d32;">
                        &#8377;<%= df.format(payment.get("amount")) %>
                    </div>
                    
                    <% if(payment.get("refund_status") != null && !"none".equals(payment.get("refund_status"))) { %>
                    <div style="margin-top: 15px; padding-top: 15px; border-top: 1px dashed #a5d6a7;">
                        <div style="font-size: 0.9rem; color: #d32f2f;">Refund Status: <%= payment.get("refund_status") %></div>
                        <% if(payment.get("refund_amount") != null && (Double)payment.get("refund_amount") > 0) { %>
                        <div style="font-size: 1.2rem; font-weight: 600; color: #d32f2f;">
                            Refunded: &#8377;<%= df.format(payment.get("refund_amount")) %>
                        </div>
                        <% } %>
                    </div>
                    <% } %>
                </div>
                
                <!-- Action Buttons -->
                <div style="display: flex; gap: 15px; justify-content: center;">
                    <a href="payment_success.jsp?order_id=<%= order.get("order_number") %>" 
                       class="btn btn-primary" style="text-decoration: none;">
                        <i class="fas fa-receipt"></i> View Receipt
                    </a>
                    <a href="my_orders.jsp" class="btn" style="text-decoration: none; background: #6c757d; color: white;">
                        <i class="fas fa-list"></i> All Orders
                    </a>
                    <% if("failed".equals(payment.get("payment_status"))) { %>
                    <a href="checkout.jsp" class="btn btn-danger" style="text-decoration: none;">
                        <i class="fas fa-redo"></i> Try Again
                    </a>
                    <% } %>
                </div>
                
                <!-- Additional Info -->
                <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #dee2e6; text-align: center;">
                    <p style="color: #6c757d; font-size: 0.9rem;">
                        <i class="fas fa-info-circle"></i> 
                        For any issues with this payment, please contact our support team.
                    </p>
                </div>
            </div>
        </div>
        <% } %>
    </div>
    
    <%@ include file="footer.jsp" %>
</body>
</html>