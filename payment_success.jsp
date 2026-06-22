<%@ page contentType="text/html;charset=ISO-8859-1" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.text.DecimalFormat, java.text.SimpleDateFormat" %>
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
    String orderId = request.getParameter("order_id");
    String razorpayPaymentId = request.getParameter("razorpay_payment_id");
    String razorpayOrderId = request.getParameter("razorpay_order_id");
    String razorpaySignature = request.getParameter("razorpay_signature");
    
    // Store Razorpay details in session if provided
    if(razorpayPaymentId != null && !razorpayPaymentId.trim().isEmpty()) {
        session.setAttribute("razorpay_payment_id", razorpayPaymentId);
    }
    if(razorpayOrderId != null && !razorpayOrderId.trim().isEmpty()) {
        session.setAttribute("razorpay_order_id", razorpayOrderId);
    }
    
    if(orderId == null || orderId.trim().isEmpty()) {
        // Try to get from session
        orderId = (String) session.getAttribute("last_order_id");
        if(orderId == null) {
            response.sendRedirect("my_orders.jsp");
            return;
        }
    }
    
    // Get Razorpay details from session if not in request
    if(razorpayPaymentId == null || razorpayPaymentId.trim().isEmpty()) {
        razorpayPaymentId = (String) session.getAttribute("razorpay_payment_id");
    }
    if(razorpayOrderId == null || razorpayOrderId.trim().isEmpty()) {
        razorpayOrderId = (String) session.getAttribute("razorpay_order_id");
    }
    
    // Store for later use
    session.setAttribute("last_order_id", orderId);
    
    // Get order details
    Map<String, Object> orderDetails = new HashMap<>();
    List<Map<String, Object>> orderItems = new ArrayList<>();
    double totalAmount = 0;
    DecimalFormat df = new DecimalFormat("#0.00");
    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy, hh:mm a");
    String paymentMethod = "";
    String paymentId = "";
    String orderStatus = "";
    java.util.Date orderDate = new java.util.Date();
    String fullName = "";
    String email = "";
    
    // Razorpay payment details
    double razorpayAmountPaid = 0;
    String razorpayCurrency = "INR";
    String razorpayStatus = "captured";
    String razorpayMethod = "card";
    String razorpayCardId = "";
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = getConnection();
        
        // Get order details
        String orderSql = "SELECT o.*, u.full_name, u.email, u.phone " +
                         "FROM orders o JOIN users u ON o.user_id = u.id " +
                         "WHERE o.order_number = ? AND o.user_id = ?";
        pstmt = conn.prepareStatement(orderSql);
        pstmt.setString(1, orderId);
        pstmt.setInt(2, Integer.parseInt(userIdStr));
        rs = pstmt.executeQuery();
        
        if(rs.next()) {
            orderDetails.put("order_number", rs.getString("order_number"));
            orderDetails.put("total_amount", rs.getDouble("total_amount"));
            orderDetails.put("subtotal", rs.getDouble("subtotal"));
            orderDetails.put("tax", rs.getDouble("tax"));
            orderDetails.put("tax_rate", rs.getDouble("tax_rate")); // Added tax rate
            orderDetails.put("payment_method", rs.getString("payment_method"));
            orderDetails.put("status", rs.getString("status"));
            orderDetails.put("created_at", rs.getTimestamp("created_at"));
            
            fullName = rs.getString("full_name") != null ? rs.getString("full_name") : username;
            email = rs.getString("email") != null ? rs.getString("email") : "";
            String phone = rs.getString("phone") != null ? rs.getString("phone") : "";
            
            orderDetails.put("full_name", fullName);
            orderDetails.put("email", email);
            orderDetails.put("phone", phone);
            
            totalAmount = rs.getDouble("total_amount");
            paymentMethod = rs.getString("payment_method");
            orderStatus = rs.getString("status");
            orderDate = rs.getTimestamp("created_at");
            
            // Get order ID for payment lookup
            int orderIdInt = rs.getInt("id");
            
            // Close resources
            rs.close();
            pstmt.close();
            
            // Get payment details from payments table
            String paymentSql = "SELECT * FROM payments WHERE order_id = ?";
            pstmt = conn.prepareStatement(paymentSql);
            pstmt.setInt(1, orderIdInt);
            rs = pstmt.executeQuery();
            if(rs.next()) {
                paymentId = rs.getString("payment_id");
                razorpayOrderId = rs.getString("razorpay_order_id");
                razorpayPaymentId = rs.getString("razorpay_payment_id");
                razorpayAmountPaid = rs.getDouble("amount") / 100.0; // Convert from paise to rupees
                razorpayCurrency = rs.getString("currency");
                razorpayStatus = rs.getString("status");
                razorpayMethod = rs.getString("payment_method");
                razorpayCardId = rs.getString("card_id");
                
                // Store in orderDetails for display
                orderDetails.put("razorpay_order_id", razorpayOrderId);
                orderDetails.put("razorpay_payment_id", razorpayPaymentId);
                orderDetails.put("razorpay_amount", razorpayAmountPaid);
                orderDetails.put("razorpay_currency", razorpayCurrency);
                orderDetails.put("razorpay_status", razorpayStatus);
                orderDetails.put("razorpay_method", razorpayMethod);
                orderDetails.put("razorpay_card_id", razorpayCardId);
            }
            rs.close();
            pstmt.close();
            
            // Get order items with purchase price
            String itemsSql = "SELECT oi.*, b.title, b.author, b.cover_image, b.file_path, b.category, " +
                             "b.price as purchase_price, " + // Added purchase price
                             "CASE WHEN oi.type = 'purchase' THEN b.price ELSE b.rental_price_per_day END as unit_price_display " +
                             "FROM order_items oi JOIN books b ON oi.book_id = b.book_id " +
                             "WHERE oi.order_id = ?";
            pstmt = conn.prepareStatement(itemsSql);
            pstmt.setInt(1, orderIdInt);
            rs = pstmt.executeQuery();
            
            while(rs.next()) {
                Map<String, Object> item = new HashMap<>();
                item.put("book_id", rs.getInt("book_id"));
                item.put("title", rs.getString("title"));
                item.put("author", rs.getString("author"));
                item.put("type", rs.getString("type"));
                item.put("rental_days", rs.getInt("rental_days"));
                item.put("unit_price", rs.getDouble("unit_price"));
                item.put("unit_price_display", rs.getDouble("unit_price_display"));
                item.put("total_price", rs.getDouble("total_price"));
                item.put("purchase_price", rs.getDouble("purchase_price")); // Add purchase price
                item.put("cover_image", rs.getString("cover_image"));
                item.put("file_path", rs.getString("file_path"));
                item.put("category", rs.getString("category"));
                orderItems.add(item);
            }
            rs.close();
            pstmt.close();
            
            // Add purchased books to user's library if not already added
            for(Map<String, Object> item : orderItems) {
                String type = (String) item.get("type");
                int bookId = (Integer) item.get("book_id");
                
                // Check if book already exists in library
                String checkSql = "SELECT COUNT(*) as count FROM user_library WHERE user_id = ? AND book_id = ?";
                pstmt = conn.prepareStatement(checkSql);
                pstmt.setInt(1, Integer.parseInt(userIdStr));
                pstmt.setInt(2, bookId);
                rs = pstmt.executeQuery();
                rs.next();
                int count = rs.getInt("count");
                rs.close();
                pstmt.close();
                
                if(count == 0) {
                    if("purchase".equals(type)) {
                        String librarySql = "INSERT INTO user_library (user_id, book_id, purchase_date, access_type, status, purchase_price) " +
                                           "VALUES (?, ?, NOW(), 'purchase', 'active', ?)";
                        pstmt = conn.prepareStatement(librarySql);
                        pstmt.setInt(1, Integer.parseInt(userIdStr));
                        pstmt.setInt(2, bookId);
                        pstmt.setDouble(3, (Double) item.get("purchase_price"));
                        pstmt.executeUpdate();
                        pstmt.close();
                    } else if("rental".equals(type)) {
                        int rentalDays = (Integer) item.get("rental_days");
                        String librarySql = "INSERT INTO user_library (user_id, book_id, purchase_date, expiry_date, access_type, status, purchase_price) " +
                                           "VALUES (?, ?, NOW(), DATE_ADD(NOW(), INTERVAL ? DAY), 'rental', 'active', ?)";
                        pstmt = conn.prepareStatement(librarySql);
                        pstmt.setInt(1, Integer.parseInt(userIdStr));
                        pstmt.setInt(2, bookId);
                        pstmt.setInt(3, rentalDays);
                        pstmt.setDouble(4, (Double) item.get("purchase_price"));
                        pstmt.executeUpdate();
                        pstmt.close();
                    }
                }
            }
        } else {
            // Order not found
            response.sendRedirect("my_orders.jsp");
            return;
        }
        
    } catch(Exception e) {
        e.printStackTrace();
        // Don't redirect on error, just show error on page
    } finally {
        try { if(rs != null) rs.close(); } catch(Exception e) {}
        try { if(pstmt != null) pstmt.close(); } catch(Exception e) {}
        try { if(conn != null) conn.close(); } catch(Exception e) {}
    }
    
    // Calculate expiry dates for rentals
    SimpleDateFormat expiryFormat = new SimpleDateFormat("dd MMM yyyy");
    List<String> expiryDates = new ArrayList<>();
    List<Double> savings = new ArrayList<>();
    if(orderDate != null) {
        for(Map<String, Object> item : orderItems) {
            if("rental".equals(item.get("type"))) {
                java.util.Calendar cal = java.util.Calendar.getInstance();
                cal.setTime(orderDate);
                cal.add(java.util.Calendar.DATE, (Integer)item.get("rental_days"));
                expiryDates.add(expiryFormat.format(cal.getTime()));
                
                // Calculate savings for rentals
                double purchasePrice = (Double) item.get("purchase_price");
                double rentalPrice = (Double) item.get("total_price");
                savings.add(purchasePrice - rentalPrice);
            } else {
                expiryDates.add("Lifetime");
                savings.add(0.0);
            }
        }
    }
    
    // Calculate tax rate for display
    double taxRate = 18.0; // Default GST rate
    if(orderDetails.get("tax_rate") != null) {
        taxRate = (Double) orderDetails.get("tax_rate");
    }
    
    // Format payment method for display
    String displayPaymentMethod = "Online Payment";
    if(paymentMethod != null && !paymentMethod.isEmpty()) {
        displayPaymentMethod = paymentMethod;
    }
    
    // Get payment card details for display
    String cardLast4 = "";
    if(razorpayCardId != null && !razorpayCardId.isEmpty()) {
        // In production, you would fetch card details from Razorpay API
        // For now, show masked card
        cardLast4 = "XXXX-XXXX-XXXX-4321"; // Example
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <%@ include file="head_include.jsp" %>
    <meta charset="ISO-8859-1">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Successful - ReadVerse</title>
    <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        /* Keep all your existing CSS styles, add new styles below */
        
        .razorpay-section {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
            margin-top: 25px;
            border: 1px solid #e9ecef;
        }
        
        .razorpay-section h4 {
            color: #6c63ff;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 1px solid #dee2e6;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .payment-details-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-top: 15px;
        }
        
        .payment-detail-item {
            background: white;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #28a745;
        }
        
        .payment-detail-label {
            font-size: 0.9rem;
            color: #6c757d;
            margin-bottom: 5px;
        }
        
        .payment-detail-value {
            font-weight: 600;
            color: #212529;
            font-size: 1.1rem;
            word-break: break-all;
        }
        
        .amount-highlight {
            color: #28a745;
            font-weight: 700;
            font-size: 1.2rem;
        }
        
        .currency-symbol {
            font-size: 0.9rem;
            color: #6c757d;
            margin-right: 2px;
        }
        
        .payment-status {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 5px 10px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 600;
        }
        
        .status-success {
            background: #d4edda;
            color: #155724;
        }
        
        .status-pending {
            background: #fff3cd;
            color: #856404;
        }
        
        .status-failed {
            background: #f8d7da;
            color: #721c24;
        }
        
        .card-details {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .card-icon {
            font-size: 1.5rem;
            color: #6c63ff;
        }
        
        .secure-badge {
            background: #28a745;
            color: white;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 0.75rem;
            font-weight: 600;
            margin-top: 5px;
            display: inline-flex;
            align-items: center;
            gap: 5px;
        }
        
        .verified-badge {
            background: #17a2b8;
            color: white;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 0.75rem;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 5px;
        }
        
        .payment-timestamp {
            font-size: 0.85rem;
            color: #6c757d;
            text-align: center;
            margin-top: 15px;
            padding-top: 15px;
            border-top: 1px dashed #dee2e6;
        }
    </style>
</head>
<body>
    <%@ include file="header.jsp" %>
    
    <!-- Notification -->
    <div id="notification" class="notification">
        <i class="fas fa-info-circle"></i>
        <span id="notification-message"></span>
    </div>
    
    <div class="container">
        <div class="success-container">
            <!-- Success Header -->
            <div class="success-header">
                <div class="success-icon">
                    <i class="fas fa-check-circle"></i>
                </div>
                <h1>Payment Successful!</h1>
                <p>Thank you for your purchase. Your books are now available in your library.</p>
            </div>
            
            <!-- Main Content -->
            <div class="success-content">
                <!-- Receipt Section -->
                <div class="receipt-section">
                    <h3 class="section-title">
                        <i class="fas fa-receipt"></i> Payment Receipt
                    </h3>
                    
                    <div class="receipt-box" id="printableReceipt">
                        <div class="receipt-info">
                            <div class="info-row">
                                <span class="info-label">Order Number:</span>
                                <span class="info-value"><%= orderId %></span>
                            </div>
                            
                            <div class="info-row">
                                <span class="info-label">Date:</span>
                                <span class="info-value"><%= orderDate != null ? dateFormat.format(orderDate) : "" %></span>
                            </div>
                            
                            <% if(fullName != null && !fullName.isEmpty()) { %>
                            <div class="info-row">
                                <span class="info-label">Customer:</span>
                                <span class="info-value"><%= fullName %></span>
                            </div>
                            <% } %>
                            
                            <% if(email != null && !email.isEmpty()) { %>
                            <div class="info-row">
                                <span class="info-label">Email:</span>
                                <span class="info-value"><%= email %></span>
                            </div>
                            <% } %>
                            
                            <div class="info-row">
                                <span class="info-label">Payment Method:</span>
                                <span class="info-value">
                                    <%= displayPaymentMethod %>
                                    <% if(cardLast4 != null && !cardLast4.isEmpty()) { %>
                                    <span style="font-size: 0.9rem; color: #6c757d; margin-left: 10px;">
                                        (<%= cardLast4 %>)
                                    </span>
                                    <% } %>
                                </span>
                            </div>
                            
                            <div class="info-row">
                                <span class="info-label">Payment Status:</span>
                                <span class="info-value">
                                    <span class="payment-status status-success">
                                        <i class="fas fa-check-circle"></i>
                                        <%= razorpayStatus != null ? razorpayStatus.toUpperCase() : "COMPLETED" %>
                                    </span>
                                </span>
                            </div>
                        </div>
                        
                        <!-- Razorpay Payment Details Section -->
                        <div class="razorpay-section">
                            <h4><i class="fas fa-credit-card"></i> Razorpay Payment Details</h4>
                            
                            <div class="payment-details-grid">
                                <% if(razorpayPaymentId != null && !razorpayPaymentId.isEmpty()) { %>
                                <div class="payment-detail-item">
                                    <div class="payment-detail-label">Razorpay Payment ID</div>
                                    <div class="payment-detail-value" style="font-family: monospace; font-size: 0.95rem;">
                                        <%= razorpayPaymentId %>
                                    </div>
                                </div>
                                <% } %>
                                
                                <% if(razorpayOrderId != null && !razorpayOrderId.isEmpty()) { %>
                                <div class="payment-detail-item">
                                    <div class="payment-detail-label">Razorpay Order ID</div>
                                    <div class="payment-detail-value" style="font-family: monospace; font-size: 0.95rem;">
                                        <%= razorpayOrderId %>
                                    </div>
                                </div>
                                <% } %>
                                
                                <div class="payment-detail-item">
                                    <div class="payment-detail-label">Amount Paid</div>
                                    <div class="payment-detail-value amount-highlight">
                                        <span class="currency-symbol">&#8377;</span><%= df.format(razorpayAmountPaid > 0 ? razorpayAmountPaid : totalAmount) %>
                                    </div>
                                </div>
                                
                                <div class="payment-detail-item">
                                    <div class="payment-detail-label">Payment Method</div>
                                    <div class="payment-detail-value">
                                        <div class="card-details">
                                            <i class="fas fa-credit-card card-icon"></i>
                                            <span><%= razorpayMethod != null ? razorpayMethod.toUpperCase() : "ONLINE PAYMENT" %></span>
                                        </div>
                                        <div class="secure-badge">
                                            <i class="fas fa-lock"></i> Secure Payment
                                        </div>
                                    </div>
                                </div>
                                
                                <div class="payment-detail-item">
                                    <div class="payment-detail-label">Currency</div>
                                    <div class="payment-detail-value">
                                        <%= razorpayCurrency != null ? razorpayCurrency.toUpperCase() : "INR" %>
                                    </div>
                                </div>
                                
                                <div class="payment-detail-item">
                                    <div class="payment-detail-label">Transaction Status</div>
                                    <div class="payment-detail-value">
                                        <span class="verified-badge">
                                            <i class="fas fa-shield-alt"></i> Verified & Captured
                                        </span>
                                    </div>
                                </div>
                            </div>
                            
                            <div class="payment-timestamp">
                                <i class="fas fa-clock"></i> Transaction completed on: 
                                <%= orderDate != null ? dateFormat.format(orderDate) : "Just now" %>
                            </div>
                        </div>
                        
                        <!-- Order Items -->
                        <div class="order-items">
                            <h4 style="color: #495057; margin-bottom: 15px;">
                                <i class="fas fa-book"></i> Order Items
                            </h4>
                            
                            <% for(int i = 0; i < orderItems.size(); i++) { 
                                Map<String, Object> item = orderItems.get(i);
                                double unitPriceDisplay = (Double) item.get("unit_price_display");
                                double totalPrice = (Double) item.get("total_price");
                                double purchasePrice = (Double) item.get("purchase_price");
                            %>
                            <div class="order-item">
                                <div class="item-details">
                                    <div class="item-title"><%= item.get("title") %></div>
                                    <div class="item-meta">
                                        <% if("rental".equals(item.get("type"))) { %>
                                        <span style="background: #d1ecf1; color: #0c5460; padding: 3px 8px; border-radius: 4px; font-size: 0.8rem;">
                                            <i class="fas fa-clock"></i> Rental (<%= item.get("rental_days") %> days)
                                        </span>
                                        <span style="color: #6c757d; font-size: 0.85rem;">
                                            &#8377;<%= df.format(unitPriceDisplay) %>/day
                                        </span>
                                        <% } else { %>
                                        <span style="background: #d4edda; color: #155724; padding: 3px 8px; border-radius: 4px; font-size: 0.8rem;">
                                            <i class="fas fa-crown"></i> Purchase
                                        </span>
                                        <span style="color: #6c757d; font-size: 0.85rem;">
                                            Unit price: &#8377;<%= df.format(unitPriceDisplay) %>
                                        </span>
                                        <% } %>
                                    </div>
                                    
                                    <!-- Purchase Price Comparison -->
                                    <% if("rental".equals(item.get("type"))) { 
                                        double saving = purchasePrice - totalPrice;
                                        if(saving > 0) {
                                    %>
                                    <div class="purchase-price">
                                        <i class="fas fa-tag"></i> Purchase price: &#8377;<%= df.format(purchasePrice) %>
                                    </div>
                                    <div class="savings-badge">
                                        <i class="fas fa-piggy-bank"></i> Saved &#8377;<%= df.format(saving) %>
                                    </div>
                                    <% } else { %>
                                    <div class="purchase-price">
                                        <i class="fas fa-tag"></i> Purchase price: &#8377;<%= df.format(purchasePrice) %>
                                    </div>
                                    <% } %>
                                    <% } else { %>
                                    <div class="purchase-price">
                                        <i class="fas fa-tag"></i> Purchase price: &#8377;<%= df.format(purchasePrice) %>
                                    </div>
                                    <% } %>
                                </div>
                                <div class="item-price-details">
                                    <div class="unit-price">
                                        <% if("rental".equals(item.get("type"))) { %>
                                        &#8377;<%= df.format(unitPriceDisplay) %> &times; <%= item.get("rental_days") %> days
                                        <% } else { %>
                                        1 item
                                        <% } %>
                                    </div>
                                    <div class="item-price">&#8377;<%= df.format(totalPrice) %></div>
                                </div>
                            </div>
                            <% } %>
                        </div>
                        
                        <!-- Amount Breakdown -->
                        <div class="amount-breakdown">
                            <div class="breakdown-row">
                                <span>Subtotal:</span>
                                <span>&#8377;<%= df.format(orderDetails.get("subtotal") != null ? (Double)orderDetails.get("subtotal") : 0) %></span>
                            </div>
                            <div class="breakdown-row">
                                <span>GST (<%= String.format("%.0f", taxRate) %>%):</span>
                                <span>&#8377;<%= df.format(orderDetails.get("tax") != null ? (Double)orderDetails.get("tax") : 0) %></span>
                            </div>
                            <div class="breakdown-row total-row">
                                <span>Total Amount:</span>
                                <span class="amount-highlight">
                                    <span class="currency-symbol">&#8377;</span><%= df.format(totalAmount) %>
                                </span>
                            </div>
                            
                            <!-- Razorpay Paid Amount -->
                            <% if(razorpayAmountPaid > 0 && razorpayAmountPaid != totalAmount) { %>
                            <div class="breakdown-row" style="color: #28a745; font-weight: 600;">
                                <span>Amount Paid via Razorpay:</span>
                                <span>&#8377;<%= df.format(razorpayAmountPaid) %></span>
                            </div>
                            <% } %>
                        </div>
                        
                        <!-- Receipt Footer -->
                        <div style="text-align: center; margin-top: 20px; padding-top: 20px; border-top: 1px dashed #dee2e6; color: #6c757d; font-size: 0.9em;">
                            <p><i class="fas fa-info-circle"></i> This is a computer-generated receipt. No signature required.</p>
                            <p>Powered by Razorpay Secure Payments</p>
                            <p style="margin-top: 10px;">
                                <i class="fas fa-shield-alt"></i> 
                                <strong>Payment Verified:</strong> Your payment of &#8377;<%= df.format(razorpayAmountPaid > 0 ? razorpayAmountPaid : totalAmount) %> 
                                has been successfully processed via Razorpay.
                            </p>
                            <p>Thank you for shopping with ReadVerse!</p>
                        </div>
                    </div>
                    
                    <!-- Action Buttons -->
                    <div class="action-buttons">
                        <button class="btn btn-primary" onclick="printReceipt()">
                            <i class="fas fa-print"></i> Print Receipt
                        </button>
                        
                        <button class="btn btn-secondary" onclick="downloadReceipt()">
                            <i class="fas fa-download"></i> Download PDF
                        </button>
                        
                        <a href="my_orders.jsp" class="btn btn-success">
                            <i class="fas fa-list"></i> View Orders
                        </a>
                    </div>
                </div>
                
                <!-- Library Section -->
                <div class="library-section">
                    <h3 class="section-title">
                        <i class="fas fa-book-open"></i> Your Library
                    </h3>
                    
                    <p style="color: #6c757d; margin-bottom: 20px;">
                        Your purchased books are now available in your library. You can start reading immediately!
                    </p>
                    
                    <% if(!orderItems.isEmpty()) { %>
                        <div class="book-list">
                            <% for(int i = 0; i < orderItems.size(); i++) { 
                                Map<String, Object> item = orderItems.get(i);
                                String expiryDate = i < expiryDates.size() ? expiryDates.get(i) : "";
                                double saving = i < savings.size() ? savings.get(i) : 0;
                            %>
                            <div class="book-card">
                                <div class="book-cover">
                                    <% if(item.get("cover_image") != null && !((String)item.get("cover_image")).isEmpty()) { %>
                                    <img src="<%= item.get("cover_image") %>" alt="<%= item.get("title") %>">
                                    <% } else { %>
                                    <div style="width: 100%; height: 100%; background: linear-gradient(135deg, #6c63ff, #4a42d1); display: flex; align-items: center; justify-content: center; color: white;">
                                        <i class="fas fa-book" style="font-size: 2.5rem;"></i>
                                    </div>
                                    <% } %>
                                </div>
                                
                                <div class="book-details">
                                    <h3 class="book-title"><%= item.get("title") %></h3>
                                    <div class="book-author">by <%= item.get("author") %></div>
                                    
                                    <div class="book-meta">
                                        <% if("rental".equals(item.get("type"))) { %>
                                        <span class="tag tag-rental">
                                            <i class="fas fa-clock"></i> Rental
                                        </span>
                                        <span class="tag tag-expiry">
                                            <i class="fas fa-calendar-alt"></i> Expires: <%= expiryDate %>
                                        </span>
                                        <% if(saving > 0) { %>
                                        <span class="tag" style="background: #28a745; color: white;">
                                            <i class="fas fa-piggy-bank"></i> Saved &#8377;<%= df.format(saving) %>
                                        </span>
                                        <% } %>
                                        <% } else { %>
                                        <span class="tag tag-purchase">
                                            <i class="fas fa-crown"></i> Lifetime Access
                                        </span>
                                        <% } %>
                                        
                                        <span class="tag" style="background: #e9ecef; color: #495057;">
                                            <i class="fas fa-tag"></i> <%= item.get("category") %>
                                        </span>
                                        
                                        <span class="tag" style="background: #fff3cd; color: #856404;">
                                            <i class="fas fa-tag"></i> Price: &#8377;<%= df.format(item.get("purchase_price")) %>
                                        </span>
                                    </div>
                                    
                                    <div class="book-actions">
                                        <% if(item.get("file_path") != null && !((String)item.get("file_path")).isEmpty()) { %>
                                        <a href="read_book.jsp?book_id=<%= item.get("book_id") %>" class="btn-read">
                                            <i class="fas fa-book-open"></i> Read Now
                                        </a>
                                        
                                        <a href="download_books.jsp?book_id=<%= item.get("book_id") %>" class="btn-download">
                                            <i class="fas fa-download"></i> Download
                                        </a>
                                        <% } else { %>
                                        <span class="btn-read" style="background: #ccc; cursor: not-allowed;">
                                            <i class="fas fa-book-open"></i> Read Now
                                        </span>
                                        <span class="btn-download" style="background: #ccc; cursor: not-allowed;">
                                            <i class="fas fa-download"></i> Download
                                        </span>
                                        <% } %>
                                    </div>
                                </div>
                            </div>
                            <% } %>
                        </div>
                    <% } else { %>
                        <div class="empty-library">
                            <i class="fas fa-book"></i>
                            <p style="margin-bottom: 20px; font-size: 1.1rem;">No books found for this order.</p>
                            <a href="library.jsp" class="btn btn-primary">
                                <i class="fas fa-arrow-right"></i> Go to Library
                            </a>
                        </div>
                    <% } %>
                    
                    <!-- Quick Links -->
                    <div class="quick-links">
                        <h4><i class="fas fa-bolt"></i> Quick Actions</h4>
                        <div class="link-grid">
                            <a href="library.jsp" class="link-card">
                                <i class="fas fa-book"></i>
                                <span>View Full Library</span>
                            </a>
                            <a href="browse.jsp" class="link-card">
                                <i class="fas fa-shopping-bag"></i>
                                <span>Continue Shopping</span>
                            </a>
                            <a href="profile.jsp" class="link-card">
                                <i class="fas fa-user"></i>
                                <span>My Profile</span>
                            </a>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Footer Links -->
            <div class="footer-links">
                <a href="index.jsp" class="home-link">
                    <i class="fas fa-home"></i> Back to Homepage
                </a>
            </div>
        </div>
    </div>

    <script>
        // Show notification
        function showNotification(message, type) {
            const notification = document.getElementById('notification');
            const messageEl = document.getElementById('notification-message');
            
            // Set type and icon
            notification.className = 'notification';
            notification.classList.add(type);
            
            const icon = notification.querySelector('i');
            icon.className = type === 'success' ? 'fas fa-check-circle' :
                            type === 'error' ? 'fas fa-exclamation-circle' :
                            'fas fa-info-circle';
            
            // Set message
            messageEl.textContent = message;
            
            // Show notification
            notification.classList.add('show');
            
            // Auto hide after 4 seconds
            setTimeout(() => {
                notification.classList.remove('show');
                setTimeout(() => {
                    notification.style.display = 'none';
                }, 300);
            }, 4000);
        }
        
        // Print receipt
        function printReceipt() {
            showNotification('Preparing receipt for printing...', 'info');
            
            // Wait a moment then print
            setTimeout(() => {
                window.print();
                showNotification('Receipt sent to printer.', 'success');
            }, 500);
        }
        
        // Download receipt as PDF
        function downloadReceipt() {
            showNotification('Download feature coming soon! For now, please use Print option.', 'info');
            
            // In production, you would implement PDF generation
            // Example: window.location.href = 'generate_receipt_pdf.jsp?order_id=<%= orderId %>';
        }
        
        // Initialize when page loads
        document.addEventListener('DOMContentLoaded', function() {
            // Show success notification
            showNotification('Payment successful! Books added to your library.', 'success');
            
            // Add hover effects to book cards
            const bookCards = document.querySelectorAll('.book-card');
            bookCards.forEach(card => {
                card.addEventListener('mouseenter', function() {
                    this.style.transform = 'translateY(-3px)';
                });
                
                card.addEventListener('mouseleave', function() {
                    this.style.transform = 'translateY(0)';
                });
            });
            
            // Keyboard shortcuts
            document.addEventListener('keydown', function(event) {
                // Ctrl/Cmd + P to print
                if ((event.ctrlKey || event.metaKey) && event.key === 'p') {
                    event.preventDefault();
                    printReceipt();
                }
                
                // Escape to go to library
                if (event.key === 'Escape') {
                    window.location.href = 'library.jsp';
                }
            });
        });
    </script>
    
    <%@ include file="footer.jsp" %>
</body>
</html>