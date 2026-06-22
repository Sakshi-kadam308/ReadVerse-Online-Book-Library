<%@ page contentType="application/json;charset=ISO-8859-1" %>
<%@ page import="javax.crypto.Mac, javax.crypto.spec.SecretKeySpec" %>
<%@ page import="org.json.JSONObject" %>
<%@ page import="java.sql.*" %>
<%@ include file="db_config.jsp" %>
<%
response.setContentType("application/json;charset=ISO-8859-1");

// Get payment details
String razorpayPaymentId = request.getParameter("razorpay_payment_id");
String razorpayOrderId = request.getParameter("razorpay_order_id");
String razorpaySignature = request.getParameter("razorpay_signature");
String orderId = request.getParameter("order_id");
String userId = request.getParameter("user_id");
String amount = request.getParameter("amount");

// Razorpay secret - REPLACE WITH YOUR ACTUAL SECRET
String razorpaySecret = "rzp_test_S9nu7nJrIp5cZA";

JSONObject result = new JSONObject();
Connection conn = null;

try {
    // Verify signature
    String payload = razorpayOrderId + "|" + razorpayPaymentId;
    String generatedSignature = calculateHMAC(payload, razorpaySecret);
    
    if (!generatedSignature.equals(razorpaySignature)) {
        result.put("success", false);
        result.put("message", "Invalid payment signature");
        out.print(result.toString());
        return;
    }
    
    // Connect to database
    conn = getConnection();
    
    // Get cart items from session
    java.util.List cartItems = (java.util.List) session.getAttribute("checkout_items");
    double subtotal = ((Double) session.getAttribute("checkout_subtotal")).doubleValue();
    double tax = ((Double) session.getAttribute("checkout_tax")).doubleValue();
    double total = ((Double) session.getAttribute("checkout_total")).doubleValue();
    
    if (cartItems == null) {
        result.put("success", false);
        result.put("message", "Cart items not found");
        out.print(result.toString());
        return;
    }
    
    // Begin transaction
    conn.setAutoCommit(false);
    
    // 1. Create order record
    String orderSql = "INSERT INTO orders (order_number, user_id, total_amount, subtotal, tax, payment_id, " +
                      "payment_method, status, created_at) VALUES (?, ?, ?, ?, ?, ?, 'razorpay', 'completed', NOW())";
    
    PreparedStatement orderStmt = conn.prepareStatement(orderSql, Statement.RETURN_GENERATED_KEYS);
    orderStmt.setString(1, orderId);
    orderStmt.setInt(2, Integer.parseInt(userId));
    orderStmt.setDouble(3, Double.parseDouble(amount));
    orderStmt.setDouble(4, subtotal);
    orderStmt.setDouble(5, tax);
    orderStmt.setString(6, razorpayPaymentId);
    
    int rows = orderStmt.executeUpdate();
    
    if (rows == 0) {
        conn.rollback();
        result.put("success", false);
        result.put("message", "Failed to create order");
        out.print(result.toString());
        return;
    }
    
    // Get generated order ID
    ResultSet rs = orderStmt.getGeneratedKeys();
    int dbOrderId = 0;
    if (rs.next()) {
        dbOrderId = rs.getInt(1);
    }
    orderStmt.close();
    
    // 2. Create order items
    String itemSql = "INSERT INTO order_items (order_id, book_id, title, type, rental_days, unit_price, total_price) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?)";
    PreparedStatement itemStmt = conn.prepareStatement(itemSql);
    
    for (Object obj : cartItems) {
        java.util.Map item = (java.util.Map) obj;
        itemStmt.setInt(1, dbOrderId);
        itemStmt.setInt(2, ((Integer) item.get("book_id")).intValue());
        itemStmt.setString(3, (String) item.get("title"));
        itemStmt.setString(4, (String) item.get("type"));
        itemStmt.setInt(5, item.get("type").equals("rental") ? ((Integer) item.get("rental_days")).intValue() : 0);
        itemStmt.setDouble(6, ((Double) item.get("price")).doubleValue());
        itemStmt.setDouble(7, ((Double) item.get("price")).doubleValue());
        itemStmt.addBatch();
    }
    
    itemStmt.executeBatch();
    itemStmt.close();
    
    // 3. Clear user's cart
    String clearCartSql = "DELETE FROM cart WHERE user_id = ?";
    PreparedStatement clearStmt = conn.prepareStatement(clearCartSql);
    clearStmt.setInt(1, Integer.parseInt(userId));
    clearStmt.executeUpdate();
    clearStmt.close();
    
    // 4. Create payment record
    String paymentSql = "INSERT INTO payments (order_id, payment_id, razorpay_order_id, amount, currency, " +
                        "status, created_at) VALUES (?, ?, ?, ?, 'INR', 'captured', NOW())";
    PreparedStatement paymentStmt = conn.prepareStatement(paymentSql);
    paymentStmt.setInt(1, dbOrderId);
    paymentStmt.setString(2, razorpayPaymentId);
    paymentStmt.setString(3, razorpayOrderId);
    paymentStmt.setDouble(4, Double.parseDouble(amount));
    paymentStmt.executeUpdate();
    paymentStmt.close();
    
    // Commit transaction
    conn.commit();
    
    // Clear session checkout data
    session.removeAttribute("checkout_items");
    session.removeAttribute("checkout_subtotal");
    session.removeAttribute("checkout_tax");
    session.removeAttribute("checkout_total");
    session.removeAttribute("order_id");
    
    result.put("success", true);
    result.put("message", "Payment verified and order created successfully");
    result.put("order_number", orderId);
    result.put("order_id", dbOrderId);
    
} catch (Exception e) {
    if (conn != null) {
        try { conn.rollback(); } catch (SQLException ex) {}
    }
    e.printStackTrace();
    result.put("success", false);
    result.put("message", "Database error: " + e.getMessage());
} finally {
    if (conn != null) {
        try { conn.close(); } catch (SQLException e) {}
    }
}

out.print(result.toString());
%>

<%!
// Helper method to calculate HMAC SHA256
private String calculateHMAC(String data, String secret) throws Exception {
    Mac sha256_HMAC = Mac.getInstance("HmacSHA256");
    SecretKeySpec secret_key = new SecretKeySpec(secret.getBytes("ISO-8859-1"), "HmacSHA256");
    sha256_HMAC.init(secret_key);
    
    byte[] hash = sha256_HMAC.doFinal(data.getBytes("ISO-8859-1"));
    StringBuilder hexString = new StringBuilder();
    
    for (byte b : hash) {
        String hex = Integer.toHexString(0xff & b);
        if (hex.length() == 1) hexString.append('0');
        hexString.append(hex);
    }
    
    return hexString.toString();
}
%>