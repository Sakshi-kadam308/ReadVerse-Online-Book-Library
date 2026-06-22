<%@ page contentType="application/json;charset=ISO-8859-1" %>
<%@ page import="java.net.*, java.io.*, java.util.Base64" %>
<%@ page import="org.json.JSONObject" %>
<%
response.setContentType("application/json;charset=ISO-8859-1");

// Get parameters
String amount = request.getParameter("amount");
String orderId = request.getParameter("order_id");
String userId = request.getParameter("user_id");

// Razorpay credentials - REPLACE WITH YOUR ACTUAL KEYS
String razorpayKeyId = "rzp_test_S9nu7nJrIp5cZA";
String razorpaySecret = "rVEZ4zPCExIu5xfzmayZUHcO";

JSONObject result = new JSONObject();

try {
    // Create request to Razorpay API
    URL url = new URL("https://api.razorpay.com/v1/orders");
    HttpURLConnection conn = (HttpURLConnection) url.openConnection();
    conn.setRequestMethod("POST");
    conn.setRequestProperty("Content-Type", "application/json");
    
    // Basic authentication
    String auth = razorpayKeyId + ":" + razorpaySecret;
    String encodedAuth = Base64.getEncoder().encodeToString(auth.getBytes());
    conn.setRequestProperty("Authorization", "Basic " + encodedAuth);
    
    // Create request body
    JSONObject requestBody = new JSONObject();
    requestBody.put("amount", amount);
    requestBody.put("currency", "INR");
    requestBody.put("receipt", orderId);
    requestBody.put("payment_capture", 1);
    
    // Send request
    conn.setDoOutput(true);
    OutputStream os = conn.getOutputStream();
    byte[] input = requestBody.toString().getBytes("ISO-8859-1");
    os.write(input, 0, input.length);
    os.close();
    
    // Get response
    int responseCode = conn.getResponseCode();
    BufferedReader in;
    if (responseCode == 200) {
        in = new BufferedReader(new InputStreamReader(conn.getInputStream(), "ISO-8859-1"));
    } else {
        in = new BufferedReader(new InputStreamReader(conn.getErrorStream(), "ISO-8859-1"));
    }
    
    String inputLine;
    StringBuilder responseContent = new StringBuilder();
    while ((inputLine = in.readLine()) != null) {
        responseContent.append(inputLine);
    }
    in.close();
    
    if (responseCode == 200) {
        JSONObject razorpayResponse = new JSONObject(responseContent.toString());
        
        result.put("success", true);
        result.put("razorpay_order_id", razorpayResponse.getString("id"));
        result.put("amount", razorpayResponse.getInt("amount"));
        
    } else {
        JSONObject errorResponse = new JSONObject(responseContent.toString());
        result.put("success", false);
        result.put("message", errorResponse.optString("error", "Failed to create order"));
    }
    
    conn.disconnect();
    
} catch (Exception e) {
    e.printStackTrace();
    result.put("success", false);
    result.put("message", "Server error: " + e.getMessage());
}

out.print(result.toString());
%>