<%@ page contentType="text/html;charset=ISO-8859-1" language="java" %>
<%@ page import="java.sql.*, java.util.*, javax.crypto.Mac, javax.crypto.spec.SecretKeySpec" %>
<%@ include file="db_config.jsp" %>
<%
    // This is the webhook endpoint for Razorpay callbacks
    // Configure in Razorpay dashboard: https://dashboard.razorpay.com/#/app/webhooks
    
    String razorpayWebhookSecret = ""; // Get from Razorpay dashboard
    
    try {
        // Get request body
        StringBuilder requestBody = new StringBuilder();
        String line;
        while ((line = request.getReader().readLine()) != null) {
            requestBody.append(line);
        }
        
        // Get Razorpay signature from header
        String razorpaySignature = request.getHeader("X-Razorpay-Signature");
        
        // Verify webhook signature
        boolean isValid = verifyWebhookSignature(requestBody.toString(), razorpaySignature, razorpayWebhookSecret);
        
        if(!isValid) {
            response.setStatus(401);
            out.print("Invalid signature");
            return;
        }
        
        // Simple JSON parsing without external library
        String jsonString = requestBody.toString();
        
        // Extract event type
        String event = extractJsonValue(jsonString, "event");
        
        if("payment.captured".equals(event)) {
            // Extract payment details
            String razorpayPaymentId = extractNestedJsonValue(jsonString, "payload", "payment", "id");
            String razorpayOrderId = extractNestedJsonValue(jsonString, "payload", "payment", "order_id");
            String status = extractNestedJsonValue(jsonString, "payload", "payment", "status");
            String amountStr = extractNestedJsonValue(jsonString, "payload", "payment", "amount");
            double amount = Double.parseDouble(amountStr) / 100.0; // Convert from paise
            
            Connection conn = getConnection();
            
            // Update payment status
            String sql = "UPDATE payments SET payment_status = ? WHERE razorpay_payment_id = ?";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, status);
            pstmt.setString(2, razorpayPaymentId);
            pstmt.executeUpdate();
            pstmt.close();
            
            // If payment captured, update order status
            if("captured".equals(status)) {
                sql = "UPDATE orders o JOIN payments p ON o.id = p.order_id " +
                     "SET o.status = 'completed' " +
                     "WHERE p.razorpay_payment_id = ?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, razorpayPaymentId);
                pstmt.executeUpdate();
                pstmt.close();
            }
            
            conn.close();
            
        } else if("payment.failed".equals(event)) {
            // Extract payment failure details
            String razorpayPaymentId = extractNestedJsonValue(jsonString, "payload", "payment", "id");
            String errorDescription = extractNestedJsonValue(jsonString, "payload", "payment", "error_description");
            if(errorDescription == null) errorDescription = "Payment failed";
            
            Connection conn = getConnection();
            
            String sql = "UPDATE payments SET payment_status = 'failed', payment_details = CONCAT('Error: ', ?) " +
                        "WHERE razorpay_payment_id = ?";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, errorDescription);
            pstmt.setString(2, razorpayPaymentId);
            pstmt.executeUpdate();
            pstmt.close();
            
            // Also update order status
            sql = "UPDATE orders o JOIN payments p ON o.id = p.order_id " +
                 "SET o.status = 'failed' " +
                 "WHERE p.razorpay_payment_id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, razorpayPaymentId);
            pstmt.executeUpdate();
            pstmt.close();
            
            conn.close();
            
        } else if("refund.created".equals(event)) {
            // Handle refunds
            String razorpayPaymentId = extractNestedJsonValue(jsonString, "payload", "refund", "payment_id");
            String refundId = extractNestedJsonValue(jsonString, "payload", "refund", "id");
            String refundAmountStr = extractNestedJsonValue(jsonString, "payload", "refund", "amount");
            double refundAmount = Double.parseDouble(refundAmountStr) / 100.0;
            
            Connection conn = getConnection();
            
            String sql = "UPDATE payments SET refund_status = 'processed', refund_amount = ?, refund_date = NOW() " +
                        "WHERE razorpay_payment_id = ?";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setDouble(1, refundAmount);
            pstmt.setString(2, razorpayPaymentId);
            pstmt.executeUpdate();
            pstmt.close();
            
            conn.close();
        }
        
        response.setStatus(200);
        out.print("Webhook processed successfully");
        
    } catch(Exception e) {
        e.printStackTrace();
        response.setStatus(500);
        out.print("Internal server error");
    }
%>

<%!
    private boolean verifyWebhookSignature(String requestBody, String razorpaySignature, String secret) {
        try {
            // If secret is empty, skip verification (for testing)
            if(secret == null || secret.trim().isEmpty()) {
                return true;
            }
            
            Mac sha256_HMAC = Mac.getInstance("HmacSHA256");
            SecretKeySpec secretKey = new SecretKeySpec(secret.getBytes(), "HmacSHA256");
            sha256_HMAC.init(secretKey);
            
            byte[] hash = sha256_HMAC.doFinal(requestBody.getBytes());
            String generatedSignature = bytesToHex(hash);
            
            return generatedSignature.equals(razorpaySignature);
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
    
    // Simple JSON value extractor
    private String extractJsonValue(String json, String key) {
        try {
            String searchKey = "\"" + key + "\":";
            int startIndex = json.indexOf(searchKey);
            if (startIndex == -1) return null;
            
            startIndex += searchKey.length();
            int endIndex = json.indexOf(",", startIndex);
            if (endIndex == -1) endIndex = json.indexOf("}", startIndex);
            
            String value = json.substring(startIndex, endIndex).trim();
            
            // Remove quotes if present
            if (value.startsWith("\"") && value.endsWith("\"")) {
                value = value.substring(1, value.length() - 1);
            }
            
            return value;
        } catch (Exception e) {
            return null;
        }
    }
    
    // Extract nested JSON value
    private String extractNestedJsonValue(String json, String... keys) {
        String currentJson = json;
        for (int i = 0; i < keys.length - 1; i++) {
            String key = keys[i];
            String searchKey = "\"" + key + "\":";
            int startIndex = currentJson.indexOf(searchKey);
            if (startIndex == -1) return null;
            
            // Find the start of the object/array
            startIndex = currentJson.indexOf("{", startIndex);
            if (startIndex == -1) startIndex = currentJson.indexOf("[", startIndex);
            if (startIndex == -1) return null;
            
            // Find matching closing bracket
            int bracketCount = 1;
            int endIndex = startIndex + 1;
            while (bracketCount > 0 && endIndex < currentJson.length()) {
                char c = currentJson.charAt(endIndex);
                if (c == '{' || c == '[') bracketCount++;
                else if (c == '}' || c == ']') bracketCount--;
                endIndex++;
            }
            
            currentJson = currentJson.substring(startIndex, endIndex);
        }
        
        return extractJsonValue(currentJson, keys[keys.length - 1]);
    }
%>