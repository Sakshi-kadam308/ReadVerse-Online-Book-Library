<%@ page contentType="text/html;charset=ISO-8859-1" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.text.DecimalFormat" %>
<%@ include file="db_config.jsp" %>
<%
    // Set ISO-8859-1 encoding
    response.setContentType("text/html; charset=ISO-8859-1");
    response.setCharacterEncoding("ISO-8859-1");
    
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    if(username == null) {
        response.sendRedirect("login.jsp?redirect=checkout.jsp");
        return;
    }
    
    String userIdStr = (String) session.getAttribute("user_id");
    String userEmail = (String) session.getAttribute("email");
    String userPhone = (String) session.getAttribute("phone");
    String fullName = (String) session.getAttribute("full_name");
    
    if(fullName == null) fullName = username;
    if(userEmail == null) userEmail = "";
    if(userPhone == null) userPhone = "";
    
    List<Map<String, Object>> cartItems = new ArrayList<>();
    double subtotal = 0;
    double tax = 0;
    double total = 0;
    DecimalFormat df = new DecimalFormat("#0.00");
    
    Connection conn = null;
    
    try {
        conn = getConnection();
        
        String sql = "SELECT c.*, b.title, b.author, b.price, b.rental_price_per_day " +
                     "FROM cart c JOIN books b ON c.book_id = b.book_id " +
                     "WHERE c.user_id = ? ORDER BY c.added_at DESC";
        PreparedStatement pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, Integer.parseInt(userIdStr));
        ResultSet rs = pstmt.executeQuery();
        
        while(rs.next()) {
            Map<String, Object> item = new HashMap<>();
            item.put("cart_id", rs.getInt("cart_id"));
            item.put("book_id", rs.getInt("book_id"));
            item.put("title", rs.getString("title"));
            item.put("author", rs.getString("author"));
            item.put("type", rs.getString("type"));
            item.put("rental_days", rs.getInt("rental_days"));
            
            if(rs.getString("type").equals("purchase")) {
                // Assuming price is in INR, if not convert:
                // double priceInDollars = rs.getDouble("price");
                // double price = priceInDollars * 83.0; // Convert to INR
                double price = rs.getDouble("price");
                item.put("price", price);
                subtotal += price;
            } else {
                // Assuming rental price is in INR, if not convert:
                // double dailyPriceInDollars = rs.getDouble("rental_price_per_day");
                // double dailyPrice = dailyPriceInDollars * 83.0; // Convert to INR
                double dailyPrice = rs.getDouble("rental_price_per_day");
                int rentalDays = rs.getInt("rental_days");
                double rentalPrice = dailyPrice * rentalDays;
                item.put("daily_price", dailyPrice);
                item.put("price", rentalPrice);
                subtotal += rentalPrice;
            }
            
            cartItems.add(item);
        }
        
        rs.close();
        pstmt.close();
        
        // Calculate totals - Using Indian GST rate (18%)
        tax = subtotal * 0.18;
        total = subtotal + tax;
        
        // Store in session for payment processing
        session.setAttribute("checkout_items", cartItems);
        session.setAttribute("checkout_subtotal", subtotal);
        session.setAttribute("checkout_tax", tax);
        session.setAttribute("checkout_total", total);
        
    } catch(Exception e) {
        e.printStackTrace();
        response.sendRedirect("error.jsp?msg=Error loading cart items");
        return;
    } finally {
        if(conn != null) try { conn.close(); } catch(Exception e) {}
    }
    
    if(cartItems.isEmpty()) {
        response.sendRedirect("cart.jsp");
        return;
    }
    
    // Generate order ID
    String orderId = "ORD_" + System.currentTimeMillis() + "_" + userIdStr;
    session.setAttribute("order_id", orderId);
    
    // Razorpay configuration - Use test key
    String razorpayKeyId = "rzp_test_S9nu7nJrIp5cZA"; // Replace with your test key
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <%@ include file="head_include.jsp" %>
    <meta charset="ISO-8859-1">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Checkout - ReadVerse</title>
    <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
    <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
    <style>
        :root {
            --primary: #6c63ff;
            --primary-dark: #5952d4;
            --secondary: #ff6584;
            --success: #4CAF50;
            --danger: #F44336;
            --warning: #FF9800;
            --dark: #333;
            --light: #f8f9fa;
            --gray: #666;
            --border: #e0e0e0;
            --shadow-sm: 0 2px 8px rgba(0,0,0,0.1);
            --shadow-md: 0 4px 12px rgba(0,0,0,0.15);
            --shadow-lg: 0 8px 24px rgba(0,0,0,0.2);
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            color: var(--dark);
            line-height: 1.6;
            min-height: 100vh;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        /* Checkout Steps */
        .checkout-steps {
            display: flex;
            justify-content: space-between;
            margin-bottom: 40px;
            position: relative;
        }
        
        .checkout-steps::before {
            content: '';
            position: absolute;
            top: 30px;
            left: 0;
            right: 0;
            height: 3px;
            background: var(--border);
            z-index: 1;
        }
        
        .step {
            position: relative;
            text-align: center;
            z-index: 2;
            cursor: pointer;
        }
        
        .step-icon {
            width: 60px;
            height: 60px;
            background: white;
            border: 3px solid var(--border);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            color: var(--gray);
            margin: 0 auto 10px;
            transition: all 0.3s ease;
        }
        
        .step-label {
            font-weight: 600;
            color: var(--gray);
        }
        
        .step.active .step-icon {
            background: var(--primary);
            border-color: var(--primary);
            color: white;
        }
        
        .step.active .step-label {
            color: var(--primary);
        }
        
        .step.completed .step-icon {
            background: var(--success);
            border-color: var(--success);
            color: white;
        }
        
        /* Checkout Box */
        .checkout-box {
            background: white;
            border-radius: 15px;
            box-shadow: var(--shadow-lg);
            overflow: hidden;
        }
        
        .checkout-header {
            background: linear-gradient(135deg, var(--primary), var(--primary-dark));
            color: white;
            padding: 25px 30px;
        }
        
        .checkout-header h2 {
            font-size: 28px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .checkout-header p {
            opacity: 0.9;
            margin-top: 5px;
        }
        
        .checkout-content {
            padding: 30px;
        }
        
        /* Order Summary */
        .order-summary {
            background: var(--light);
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 30px;
            border: 1px solid var(--border);
        }
        
        .order-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 15px 0;
            border-bottom: 1px solid var(--border);
        }
        
        .order-item:last-child {
            border-bottom: none;
        }
        
        .book-info h4 {
            margin-bottom: 5px;
        }
        
        .book-info p {
            color: var(--gray);
            font-size: 14px;
        }
        
        .book-type {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 15px;
            font-size: 12px;
            font-weight: 600;
            margin-top: 5px;
        }
        
        .type-purchase {
            background: #e3f2fd;
            color: #1976d2;
        }
        
        .type-rental {
            background: #fff3e0;
            color: #f57c00;
        }
        
        .order-total {
            background: white;
            border-radius: 10px;
            padding: 20px;
            margin-top: 20px;
            border: 2px solid var(--border);
        }
        
        .order-total .order-item {
            border-bottom: none;
            padding: 10px 0;
        }
        
        .total-amount {
            font-size: 24px;
            font-weight: 700;
            color: var(--primary);
        }
        
        /* Payment Section */
        .payment-section {
            background: white;
            border-radius: 10px;
            padding: 25px;
            border: 1px solid var(--border);
        }
        
        .payment-section h3 {
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .payment-tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 25px;
        }
        
        .payment-tab {
            flex: 1;
            padding: 15px;
            border: 2px solid var(--border);
            background: var(--light);
            border-radius: 8px;
            cursor: pointer;
            font-weight: 600;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            transition: all 0.3s ease;
        }
        
        .payment-tab:hover {
            border-color: var(--primary);
            transform: translateY(-2px);
        }
        
        .payment-tab.active {
            background: var(--primary);
            color: white;
            border-color: var(--primary);
        }
        
        .payment-form {
            display: none;
        }
        
        .payment-form.active {
            display: block;
            animation: fadeIn 0.3s ease;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        .razorpay-info {
            text-align: center;
            padding: 20px;
        }
        
        .razorpay-features {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        
        .feature {
            background: var(--light);
            padding: 15px;
            border-radius: 8px;
            text-align: center;
            transition: all 0.3s ease;
        }
        
        .feature:hover {
            transform: translateY(-3px);
            box-shadow: var(--shadow-sm);
        }
        
        .feature i {
            font-size: 24px;
            margin-bottom: 10px;
            display: block;
        }
        
        .feature-security i { color: var(--success); }
        .feature-fast i { color: var(--warning); }
        .feature-secure i { color: var(--primary); }
        
        /* Terms Checkbox */
        .terms-container {
            background: var(--light);
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
        }
        
        .terms-checkbox {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .terms-checkbox input[type="checkbox"] {
            width: 18px;
            height: 18px;
        }
        
        .terms-checkbox label {
            font-size: 14px;
        }
        
        .terms-checkbox a {
            color: var(--primary);
            text-decoration: none;
            font-weight: 600;
        }
        
        .terms-checkbox a:hover {
            text-decoration: underline;
        }
        
        /* Buttons */
        .btn-pay {
            width: 100%;
            padding: 18px;
            background: linear-gradient(135deg, var(--primary), var(--primary-dark));
            color: white;
            border: none;
            border-radius: 10px;
            font-size: 18px;
            font-weight: 700;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            transition: all 0.3s ease;
        }
        
        .btn-pay:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 20px rgba(108, 99, 255, 0.3);
        }
        
        .btn-pay:active {
            transform: translateY(0);
        }
        
        .btn-pay:disabled {
            opacity: 0.6;
            cursor: not-allowed;
            transform: none !important;
        }
        
        .btn-back {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 10px 20px;
            color: var(--primary);
            text-decoration: none;
            font-weight: 600;
            border-radius: 8px;
            transition: all 0.3s ease;
        }
        
        .btn-back:hover {
            background: var(--light);
            transform: translateX(-5px);
        }
        
        /* Loading Spinner */
        .loading-spinner {
            width: 20px;
            height: 20px;
            border: 3px solid rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            border-top-color: white;
            animation: spin 1s linear infinite;
        }
        
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        
        /* Order ID Badge */
        .order-id-badge {
            display: inline-block;
            background: linear-gradient(135deg, var(--primary), var(--primary-dark));
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-family: monospace;
            font-size: 14px;
            font-weight: 600;
            margin-top: 10px;
        }
        
        /* Notification */
        .notification {
            position: fixed;
            top: 20px;
            right: 20px;
            background: white;
            padding: 15px 20px;
            border-radius: 8px;
            box-shadow: var(--shadow-lg);
            display: none;
            align-items: center;
            gap: 10px;
            z-index: 1000;
            max-width: 350px;
        }
        
        .notification.show {
            display: flex;
            animation: slideIn 0.3s ease;
        }
        
        @keyframes slideIn {
            from { transform: translateX(100%); }
            to { transform: translateX(0); }
        }
        
        .notification.success {
            border-left: 4px solid var(--success);
        }
        
        .notification.error {
            border-left: 4px solid var(--danger);
        }
        
        .notification.info {
            border-left: 4px solid var(--primary);
        }
        
        /* Modal */
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            z-index: 2000;
            align-items: center;
            justify-content: center;
        }
        
        .modal-content {
            background: white;
            border-radius: 15px;
            padding: 30px;
            max-width: 400px;
            width: 90%;
            text-align: center;
            box-shadow: var(--shadow-lg);
        }
        
        .modal-icon {
            font-size: 48px;
            margin-bottom: 20px;
        }
        
        .modal-icon.success {
            color: var(--success);
        }
        
        .modal-icon.error {
            color: var(--danger);
        }
        
        /* Responsive Design */
        @media (max-width: 768px) {
            .checkout-steps {
                flex-wrap: wrap;
                gap: 20px;
            }
            
            .step {
                flex: 1 0 calc(50% - 20px);
            }
            
            .checkout-steps::before {
                display: none;
            }
            
            .payment-tabs {
                flex-direction: column;
            }
            
            .razorpay-features {
                grid-template-columns: 1fr;
            }
            
            .checkout-content {
                padding: 20px;
            }
        }
        
        @media (max-width: 480px) {
            .container {
                padding: 10px;
            }
            
            .step {
                flex: 1 0 100%;
            }
        }
    </style>
</head>
<body>
    <%@ include file="header.jsp" %>
    
    <!-- Success Modal -->
    <div id="successModal" class="modal">
        <div class="modal-content">
            <div class="modal-icon success">
                <i class="fas fa-check-circle"></i>
            </div>
            <h2>Payment Successful!</h2>
            <p id="successMessage">Your order has been placed successfully.</p>
            <div class="order-id-badge">
                <i class="fas fa-hashtag"></i> <%= orderId %>
            </div>
            <button onclick="redirectToSuccess()" class="btn-pay" style="margin-top: 20px;">
                <i class="fas fa-receipt"></i> View Receipt
            </button>
        </div>
    </div>
    
    <!-- Error Modal -->
    <div id="errorModal" class="modal">
        <div class="modal-content">
            <div class="modal-icon error">
                <i class="fas fa-exclamation-circle"></i>
            </div>
            <h2>Payment Failed</h2>
            <p id="errorMessage"></p>
            <button onclick="closeModal()" class="btn-pay" style="background: var(--danger); margin-top: 20px;">
                <i class="fas fa-times"></i> Close
            </button>
        </div>
    </div>
    
    <!-- Notification -->
    <div id="notification" class="notification">
        <i class="fas fa-info-circle"></i>
        <span id="notification-message"></span>
    </div>
    
    <div class="container">
        <!-- Checkout Steps -->
        <div class="checkout-steps">
            <div class="step completed" onclick="window.location.href='cart.jsp'">
                <div class="step-icon">
                    <i class="fas fa-shopping-cart"></i>
                </div>
                <div class="step-label">Cart</div>
            </div>
            
            <div class="step active">
                <div class="step-icon">
                    <i class="fas fa-user"></i>
                </div>
                <div class="step-label">Checkout</div>
            </div>
            
            <div class="step" id="payment-step">
                <div class="step-icon">
                    <i class="fas fa-credit-card"></i>
                </div>
                <div class="step-label">Payment</div>
            </div>
            
            <div class="step" id="complete-step">
                <div class="step-icon">
                    <i class="fas fa-check"></i>
                </div>
                <div class="step-label">Complete</div>
            </div>
        </div>
        
        <!-- Checkout Box -->
        <div class="checkout-box">
            <div class="checkout-header">
                <h2>
                    <i class="fas fa-shopping-bag"></i> Secure Checkout
                </h2>
                <p>Complete your payment securely</p>
            </div>
            
            <div class="checkout-content">
                <!-- Order Summary -->
                <div class="order-summary">
                    <h3 style="margin-bottom: 20px;">
                        <i class="fas fa-receipt"></i> Order Summary
                    </h3>
                    
                    <div>
                        <% for(Map<String, Object> item : cartItems) { %>
                        <div class="order-item">
                            <div class="book-info">
                                <h4><%= item.get("title") %></h4>
                                <p>by <%= item.get("author") %></p>
                                <% if(item.get("type").equals("rental")) { %>
                                <div class="book-type type-rental">
                                    <i class="fas fa-clock"></i> Rental (<%= item.get("rental_days") %> days)
                                </div>
                                <% } else { %>
                                <div class="book-type type-purchase">
                                    <i class="fas fa-crown"></i> Purchase
                                </div>
                                <% } %>
                            </div>
                            <div style="font-weight: 700; color: var(--primary);">
                                &#8377;<%= df.format((Double)item.get("price")) %>
                            </div>
                        </div>
                        <% } %>
                    </div>
                    
                    <div class="order-total">
                        <div class="order-item">
                            <div>Subtotal</div>
                            <div>&#8377;<%= df.format(subtotal) %></div>
                        </div>
                        <div class="order-item">
                            <div>GST (18%)</div>
                            <div>&#8377;<%= df.format(tax) %></div>
                        </div>
                        <div class="order-item" style="padding: 15px 0; border-top: 2px solid var(--border);">
                            <div>Total Amount</div>
                            <div class="total-amount">&#8377;<%= df.format(total) %></div>
                        </div>
                    </div>
                    
                    <div style="text-align: center; margin-top: 20px;">
                        <div class="order-id-badge">
                            <i class="fas fa-hashtag"></i> Order ID: <%= orderId %>
                        </div>
                    </div>
                </div>
                
                <!-- Payment Section -->
                <div class="payment-section">
                    <h3><i class="fas fa-credit-card"></i> Payment Method</h3>
                    
                    <div class="payment-tabs">
                        <button type="button" class="payment-tab active" data-tab="razorpay">
                            <i class="fas fa-university"></i> Razorpay
                        </button>
                        <button type="button" class="payment-tab" data-tab="credit-card">
                            <i class="fas fa-credit-card"></i> Credit Card
                        </button>
                        <button type="button" class="payment-tab" data-tab="paypal">
                            <i class="fab fa-paypal"></i> PayPal
                        </button>
                    </div>
                    
                    <!-- Razorpay Form -->
                    <div id="razorpay-form" class="payment-form active">
                        <div class="razorpay-info">
                            <div style="font-size: 40px; color: var(--primary); margin-bottom: 10px;">
                                <i class="fas fa-lock"></i>
                            </div>
                            <p style="color: var(--gray); margin-bottom: 20px;">
                                Secure payment via Razorpay. Supports all major Indian payment methods.
                            </p>
                            
                            <div class="razorpay-features">
                                <div class="feature feature-security">
                                    <i class="fas fa-shield-alt"></i>
                                    <span>Secure Payment</span>
                                </div>
                                <div class="feature feature-fast">
                                    <i class="fas fa-bolt"></i>
                                    <span>Instant Processing</span>
                                </div>
                                <div class="feature feature-secure">
                                    <i class="fas fa-lock"></i>
                                    <span>PCI DSS Compliant</span>
                                </div>
                            </div>
                            
                            <div class="terms-container">
                                <div class="terms-checkbox">
                                    <input type="checkbox" id="terms" required>
                                    <label for="terms">
                                        I agree to the <a href="#" onclick="showTerms()">Terms of Service</a> and 
                                        <a href="#" onclick="showPrivacy()">Privacy Policy</a>
                                    </label>
                                </div>
                            </div>
                            
                            <button type="button" class="btn-pay" id="razorpay-btn" onclick="processRazorpayPayment()">
                                <i class="fas fa-lock"></i> Pay &#8377;<%= df.format(total) %> via Razorpay
                            </button>
                            
                            <p style="font-size: 12px; color: var(--gray); margin-top: 15px;">
                                <i class="fas fa-info-circle"></i> You'll be redirected to Razorpay's secure payment page
                            </p>
                        </div>
                    </div>
                    
                    <!-- Credit Card Form -->
                    <div id="credit-card-form" class="payment-form">
                        <div style="text-align: center; padding: 30px;">
                            <i class="fas fa-credit-card" style="font-size: 40px; color: var(--primary); margin-bottom: 15px;"></i>
                            <p style="color: var(--gray); margin-bottom: 20px;">
                                Credit card payment integration coming soon.
                            </p>
                            <button type="button" class="payment-tab active" onclick="selectPaymentTab('razorpay')">
                                <i class="fas fa-exchange-alt"></i> Switch to Razorpay
                            </button>
                        </div>
                    </div>
                    
                    <!-- PayPal Form -->
                    <div id="paypal-form" class="payment-form">
                        <div style="text-align: center; padding: 30px;">
                            <i class="fab fa-paypal" style="font-size: 40px; color: #003087; margin-bottom: 15px;"></i>
                            <p style="color: var(--gray); margin-bottom: 20px;">
                                PayPal integration coming soon.
                            </p>
                            <button type="button" class="payment-tab active" onclick="selectPaymentTab('razorpay')">
                                <i class="fas fa-exchange-alt"></i> Switch to Razorpay
                            </button>
                        </div>
                    </div>
                </div>
                
                <div style="text-align: center; margin-top: 30px;">
                    <a href="cart.jsp" class="btn-back">
                        <i class="fas fa-arrow-left"></i> Back to Cart
                    </a>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Initialize notification
        function showNotification(message, type = 'info') {
            const notification = document.getElementById('notification');
            const messageEl = document.getElementById('notification-message');
            
            // Reset classes
            notification.className = 'notification';
            
            // Add type class
            notification.classList.add(type);
            
            // Set icon
            const icon = notification.querySelector('i');
            icon.className = type === 'success' ? 'fas fa-check-circle' :
                            type === 'error' ? 'fas fa-exclamation-circle' :
                            'fas fa-info-circle';
            
            messageEl.textContent = message;
            notification.classList.add('show');
            
            // Auto hide
            setTimeout(() => {
                notification.classList.remove('show');
            }, 4000);
        }
        
        // Show modal
        function showModal(modalId, message = null) {
            const modal = document.getElementById(modalId);
            if (message) {
                const messageEl = modal.querySelector('p');
                if (messageEl) messageEl.textContent = message;
            }
            modal.style.display = 'flex';
            document.body.style.overflow = 'hidden';
        }
        
        // Close modal
        function closeModal() {
            const modals = document.querySelectorAll('.modal');
            modals.forEach(modal => {
                modal.style.display = 'none';
            });
            document.body.style.overflow = 'auto';
        }
        
        // Select payment tab
        function selectPaymentTab(tabId) {
            // Update tabs
            const tabs = document.querySelectorAll('.payment-tab');
            tabs.forEach(tab => tab.classList.remove('active'));
            document.querySelector(`[data-tab="${tabId}"]`).classList.add('active');
            
            // Update forms
            const forms = document.querySelectorAll('.payment-form');
            forms.forEach(form => form.classList.remove('active'));
            document.getElementById(`${tabId}-form`).classList.add('active');
            
            showNotification(`Selected ${tabId.replace('-', ' ')} payment`, 'info');
        }
        
        // Show terms
        function showTerms() {
            alert('Terms of Service:\n\n1. Rental books are accessible for selected duration\n2. Purchased books are lifetime access\n3. Payments are non-refundable\n4. You agree to our privacy policy');
        }
        
        // Show privacy
        function showPrivacy() {
            alert('Privacy Policy:\n\n1. We protect your personal information\n2. We do not share payment details\n3. Your reading history is private\n4. Account deletion available anytime');
        }
        
        // Process Razorpay payment
        function processRazorpayPayment() {
            // Validate terms
            if (!document.getElementById('terms').checked) {
                showNotification('Please accept the terms and conditions', 'error');
                return;
            }
            
            const btn = document.getElementById('razorpay-btn');
            const originalText = btn.innerHTML;
            btn.innerHTML = '<span class="loading-spinner"></span> Processing...';
            btn.disabled = true;
            
            // Update step
            document.getElementById('payment-step').classList.add('completed');
            
            // Calculate amount in paise
            const totalAmount = <%= total %>;
            const amountInPaise = Math.round(totalAmount * 100);
            
            showNotification('Creating payment order...', 'info');
            
            try {
                const options = {
                    "key": "<%= razorpayKeyId %>",
                    "amount": amountInPaise.toString(),
                    "currency": "INR",
                    "name": "ReadVerse Book Store",
                    "description": "Books Order #<%= orderId %>",
                    "image": "",
                    "order_id": "",
                    "handler": function (response) {
                        handleRazorpaySuccess(response);
                    },
                    "prefill": {
                        "name": "<%= fullName %>",
                        "email": "<%= userEmail %>",
                        "contact": "<%= userPhone %>"
                    },
                    "notes": {
                        "order_id": "<%= orderId %>",
                        "user_id": "<%= userIdStr %>"
                    },
                    "theme": {
                        "color": "#6c63ff"
                    },
                    "modal": {
                        "ondismiss": function() {
                            closeModal();
                            btn.innerHTML = originalText;
                            btn.disabled = false;
                            showNotification('Payment cancelled', 'info');
                        }
                    }
                };
                
                const rzp = new Razorpay(options);
                rzp.open();
                
                rzp.on('payment.failed', function(response) {
                    console.error('Payment failed:', response.error);
                    closeModal();
                    btn.innerHTML = originalText;
                    btn.disabled = false;
                    
                    const errorMsg = response.error?.description || 'Payment failed. Please try again.';
                    showModal('errorModal', errorMsg);
                    showNotification('Payment failed', 'error');
                });
                
            } catch (error) {
                console.error('Razorpay error:', error);
                closeModal();
                btn.innerHTML = originalText;
                btn.disabled = false;
                showNotification('Error: ' + error.message, 'error');
                showModal('errorModal', 'Error initializing payment');
            }
        }
        
        // Handle successful payment
        function handleRazorpaySuccess(response) {
            console.log('Payment success:', response);
            
            // Update UI
            document.getElementById('complete-step').classList.add('completed');
            
            // Show success modal
            showModal('successModal');
            
            // Process on server
            processPaymentOnServer(response);
        }
        
        // Process payment on server
        function processPaymentOnServer(response) {
            // Simulate server processing
            setTimeout(() => {
                // In real app, make AJAX call to process_payment.jsp
                // For demo, simulate success
                const success = true;
                
                if (success) {
                    // Redirect to success page after 2 seconds
                    setTimeout(() => {
                        window.location.href = 'payment_success.jsp?order_id=' + 
                            encodeURIComponent('<%= orderId %>') + 
                            '&payment_id=' + encodeURIComponent(response.razorpay_payment_id);
                    }, 2000);
                } else {
                    showModal('errorModal', 'Payment verification failed');
                }
            }, 1000);
        }
        
        // Redirect to success page
        function redirectToSuccess() {
            window.location.href = 'payment_success.jsp?order_id=' + 
                encodeURIComponent('<%= orderId %>');
        }
        
        // Initialize
        document.addEventListener('DOMContentLoaded', function() {
            // Payment tab click handlers
            document.querySelectorAll('.payment-tab').forEach(tab => {
                tab.addEventListener('click', function() {
                    const tabId = this.getAttribute('data-tab');
                    selectPaymentTab(tabId);
                });
            });
            
            // Welcome message
            setTimeout(() => {
                showNotification('Welcome, <%= fullName %>! Ready to complete your purchase?', 'info');
            }, 1000);
            
            // Close modal on outside click
            window.addEventListener('click', (e) => {
                if (e.target.classList.contains('modal')) {
                    closeModal();
                }
            });
            
            // Close modal with ESC key
            document.addEventListener('keydown', (e) => {
                if (e.key === 'Escape') closeModal();
            });
        });
    </script>
    
    <%@ include file="footer.jsp" %>
</body>
</html>