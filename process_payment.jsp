<%@ page contentType="text/html;charset=ISO-8859-1" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.text.DecimalFormat, org.json.*" %>
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
    int userId = Integer.parseInt(userIdStr);
    
    // Get Razorpay response
    String razorpayPaymentId = request.getParameter("razorpay_payment_id");
    String razorpayOrderId = request.getParameter("razorpay_order_id");
    String razorpaySignature = request.getParameter("razorpay_signature");
    
    if(razorpayPaymentId == null || razorpayOrderId == null) {
        session.setAttribute("error", "Invalid payment response");
        response.sendRedirect("checkout.jsp");
        return;
    }
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = getConnection();
        
        // Verify payment with Razorpay (simplified - in production, use Razorpay SDK)
        boolean paymentVerified = verifyPayment(razorpayOrderId, razorpayPaymentId, razorpaySignature);
        
        if(!paymentVerified) {
            session.setAttribute("error", "Payment verification failed");
            response.sendRedirect("checkout.jsp");
            return;
        }
        
        // Start transaction
        conn.setAutoCommit(false);
        
        // Get order from session or database
        String orderNumber = (String) session.getAttribute("order_id");
        List<Map<String, Object>> cartItems = (List<Map<String, Object>>) session.getAttribute("checkout_items");
        double subtotal = (Double) session.getAttribute("checkout_subtotal");
        double tax = (Double) session.getAttribute("checkout_tax");
        double total = (Double) session.getAttribute("checkout_total");
        
        if(orderNumber == null || cartItems == null) {
            session.setAttribute("error", "Order not found");
            response.sendRedirect("cart.jsp");
            return;
        }
        
        // 1. Create order in database
        String orderSql = "INSERT INTO orders (order_number, user_id, total_amount, subtotal, tax, tax_rate, " +
                         "payment_method, status, shipping_address, billing_address) " +
                         "VALUES (?, ?, ?, ?, ?, 18.0, 'razorpay', 'processing', '', '')";
        
        pstmt = conn.prepareStatement(orderSql, Statement.RETURN_GENERATED_KEYS);
        pstmt.setString(1, orderNumber);
        pstmt.setInt(2, userId);
        pstmt.setDouble(3, total);
        pstmt.setDouble(4, subtotal);
        pstmt.setDouble(5, tax);
        pstmt.executeUpdate();
        
        // Get generated order ID
        int orderId = 0;
        rs = pstmt.getGeneratedKeys();
        if(rs.next()) {
            orderId = rs.getInt(1);
        }
        rs.close();
        pstmt.close();
        
        // 2. Insert order items
        String itemsSql = "INSERT INTO order_items (order_id, book_id, title, type, rental_days, " +
                         "unit_price, total_price, purchase_price) " +
                         "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        
        pstmt = conn.prepareStatement(itemsSql);
        
        for(Map<String, Object> item : cartItems) {
            // Get book details
            String bookSql = "SELECT price, rental_price_per_day FROM books WHERE book_id = ?";
            PreparedStatement bookStmt = conn.prepareStatement(bookSql);
            bookStmt.setInt(1, (Integer) item.get("book_id"));
            ResultSet bookRs = bookStmt.executeQuery();
            
            double purchasePrice = 0;
            if(bookRs.next()) {
                purchasePrice = bookRs.getDouble("price");
            }
            bookRs.close();
            bookStmt.close();
            
            pstmt.setInt(1, orderId);
            pstmt.setInt(2, (Integer) item.get("book_id"));
            pstmt.setString(3, (String) item.get("title"));
            pstmt.setString(4, (String) item.get("type"));
            
            if("rental".equals(item.get("type"))) {
                pstmt.setInt(5, (Integer) item.get("rental_days"));
            } else {
                pstmt.setInt(5, 0);
            }
            
            pstmt.setDouble(6, (Double) item.get("price"));
            pstmt.setDouble(7, (Double) item.get("price"));
            pstmt.setDouble(8, purchasePrice);
            pstmt.addBatch();
        }
        
        pstmt.executeBatch();
        pstmt.close();
        
        // 3. Insert payment record
        String paymentSql = "INSERT INTO payments (order_id, user_id, payment_method, payment_status, " +
                           "razorpay_payment_id, razorpay_order_id, razorpay_signature, amount, currency) " +
                           "VALUES (?, ?, 'razorpay', 'completed', ?, ?, ?, ?, 'INR')";
        
        pstmt = conn.prepareStatement(paymentSql);
        pstmt.setInt(1, orderId);
        pstmt.setInt(2, userId);
        pstmt.setString(3, razorpayPaymentId);
        pstmt.setString(4, razorpayOrderId);
        pstmt.setString(5, razorpaySignature);
        pstmt.setDouble(6, total);
        pstmt.setString(7, "INR");
        pstmt.executeUpdate();
        pstmt.close();
        
        // 4. Update book stock
        for(Map<String, Object> item : cartItems) {
            String updateStockSql = "UPDATE books SET available_copies = available_copies - 1 " +
                                   "WHERE book_id = ? AND available_copies > 0";
            pstmt = conn.prepareStatement(updateStockSql);
            pstmt.setInt(1, (Integer) item.get("book_id"));
            pstmt.executeUpdate();
            pstmt.close();
        }
        
        // 5. Clear user's cart
        String clearCartSql = "DELETE FROM cart WHERE user_id = ?";
        pstmt = conn.prepareStatement(clearCartSql);
        pstmt.setInt(1, userId);
        pstmt.executeUpdate();
        pstmt.close();
        
        // Commit transaction
        conn.commit();
        
        // Clear session attributes
        session.removeAttribute("checkout_items");
        session.removeAttribute("checkout_subtotal");
        session.removeAttribute("checkout_tax");
        session.removeAttribute("checkout_total");
        
        // Set success message
        session.setAttribute("success", "Payment processed successfully!");
        
        // Redirect to success page
        response.sendRedirect("payment_success.jsp?order_id=" + orderNumber);
        
    } catch(Exception e) {
        // Rollback on error
        if(conn != null) {
            try {
                conn.rollback();
            } catch(Exception ex) {
                ex.printStackTrace();
            }
        }
        
        e.printStackTrace();
        session.setAttribute("error", "Payment processing failed: " + e.getMessage());
        response.sendRedirect("checkout.jsp");
        
    } finally {
        if(rs != null) try { rs.close(); } catch(Exception e) {}
        if(pstmt != null) try { pstmt.close(); } catch(Exception e) {}
        if(conn != null) {
            try {
                conn.setAutoCommit(true);
                conn.close();
            } catch(Exception e) {}
        }
    }
%>

<%!
    // Payment verification method (simplified - use Razorpay SDK in production)
    private boolean verifyPayment(String razorpayOrderId, String razorpayPaymentId, String razorpaySignature) {
        try {
            // In production, use Razorpay SDK to verify signature
            // For now, we'll assume verification passes
            return true;
            
            /* Production code would look like:
            String secret = "rzp_test_S9nu7nJrIp5cZA";
            
            String generatedSignature = "";
            try {
                String payload = razorpayOrderId + "|" + razorpayPaymentId;
                Mac sha256_HMAC = Mac.getInstance("HmacSHA256");
                SecretKeySpec secretKey = new SecretKeySpec(secret.getBytes(), "HmacSHA256");
                sha256_HMAC.init(secretKey);
                byte[] hash = sha256_HMAC.doFinal(payload.getBytes());
                generatedSignature = bytesToHex(hash);
            } catch(Exception e) {
                e.printStackTrace();
                return false;
            }
            
            return generatedSignature.equals(razorpaySignature);
            */
            
        } catch(Exception e) {
            e.printStackTrace();
            return false;
        }
    }
    
    private String bytesToHex(byte[] bytes) {
        StringBuilder result = new StringBuilder();
        for (byte b : bytes) {
            result.append(String.format("%02x", b));
        }
        return result.toString();
    }
%>