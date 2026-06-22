<%@ page contentType="text/html; charset=ISO-8859-1" %>
<%@ page import="java.sql.*, java.util.*, java.text.DecimalFormat" %>
<%@ include file="db_config.jsp" %>
<%
    // Set content type for ISO-8859-1 encoding
    response.setContentType("text/html; charset=ISO-8859-1");
    response.setCharacterEncoding("ISO-8859-1");
    
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    if(username == null) {
        response.sendRedirect("login.jsp?redirect=cart.jsp");
        return;
    }
    
    String userIdStr = (String) session.getAttribute("user_id");
    List<Map<String, Object>> cartItems = new ArrayList<>();
    double subtotal = 0;
    double tax = 0;
    double total = 0;
    DecimalFormat df = new DecimalFormat("#0.00");
    
    Connection conn = null;
    
    try {
        conn = getConnection();
        
        String sql = "SELECT c.*, b.title, b.author, b.price, b.rental_price_per_day, b.category, b.available_copies " +
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
            item.put("category", rs.getString("category"));
            item.put("available", rs.getInt("available_copies"));
            
            if(rs.getString("type").equals("purchase")) {
                double price = rs.getDouble("price");
                // Assuming price is already in INR, if not, convert here:
                // double priceInRupees = price * 83.0; // if price is in USD
                item.put("price", price);
                item.put("display_price", price);
                subtotal += price;
            } else {
                double dailyPrice = rs.getDouble("rental_price_per_day");
                // Assuming rental price is already in INR, if not, convert here:
                // double dailyPriceInRupees = dailyPrice * 83.0; // if price is in USD
                double rentalPrice = dailyPrice * rs.getInt("rental_days");
                item.put("daily_price", dailyPrice);
                item.put("price", rentalPrice);
                item.put("display_price", dailyPrice);
                subtotal += rentalPrice;
            }
            
            cartItems.add(item);
        }
        
        rs.close();
        pstmt.close();
        
        // Calculate totals
        tax = subtotal * 0.18; // 18% GST (Indian tax rate)
        total = subtotal + tax;
        
    } catch(Exception e) {
        e.printStackTrace();
    } finally {
        if(conn != null) try { conn.close(); } catch(Exception e) {}
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <%@ include file="head_include.jsp" %>
    <title>Shopping Cart - ReadVerse</title>
    <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
    <style>
        .cart-container {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 40px;
            margin: 40px 0 80px;
        }
        
        .cart-section {
            background: white;
            border-radius: var(--border-radius);
            padding: 30px;
            box-shadow: var(--shadow-light);
        }
        
        .cart-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
            padding-bottom: 20px;
            border-bottom: 1px solid var(--light);
        }
        
        .cart-header h2 {
            color: var(--dark);
            font-size: 1.8rem;
        }
        
        .cart-item {
            display: flex;
            gap: 20px;
            padding: 25px 0;
            border-bottom: 1px solid var(--light);
            transition: all 0.3s ease;
        }
        
        .cart-item:hover {
            background-color: rgba(108, 99, 255, 0.02);
        }
        
        .cart-item:last-child {
            border-bottom: none;
        }
        
        .item-details {
            flex: 1;
        }
        
        .item-title {
            font-size: 1.2rem;
            font-weight: 600;
            color: var(--dark);
            margin-bottom: 8px;
        }
        
        .item-author {
            color: var(--gray);
            font-size: 0.95rem;
            margin-bottom: 12px;
        }
        
        .item-meta {
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
            margin-bottom: 15px;
        }
        
        .item-type {
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 600;
            color: white;
            transition: transform 0.2s ease;
        }
        
        .item-type:hover {
            transform: scale(1.05);
        }
        
        .item-type.rental {
            background: var(--primary);
        }
        
        .item-type.purchase {
            background: var(--secondary);
        }
        
        .item-category {
            background: var(--light);
            color: var(--primary);
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.8rem;
            transition: all 0.2s ease;
        }
        
        .item-category:hover {
            background: var(--primary);
            color: white;
        }
        
        .item-availability {
            display: flex;
            align-items: center;
            gap: 5px;
            color: var(--gray);
            font-size: 0.9rem;
            transition: all 0.2s ease;
        }
        
        .item-availability.available {
            color: #4CAF50;
        }
        
        .item-availability.available:hover {
            color: #2E7D32;
        }
        
        .item-availability.low {
            color: #FF9800;
        }
        
        .item-availability.low:hover {
            color: #EF6C00;
        }
        
        .item-availability.unavailable {
            color: #F44336;
        }
        
        .item-availability.unavailable:hover {
            color: #C62828;
        }
        
        .item-price-section {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 15px;
        }
        
        .item-price {
            font-size: 1.4rem;
            font-weight: 700;
            color: var(--primary);
            transition: transform 0.2s ease;
        }
        
        .item-price:hover {
            transform: scale(1.05);
        }
        
        .item-daily-price {
            font-size: 0.9rem;
            color: var(--gray);
        }
        
        .item-actions {
            display: flex;
            gap: 15px;
            margin-top: 15px;
            flex-wrap: wrap;
        }
        
        .duration-selector {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .duration-selector select {
            padding: 8px 15px;
            border-radius: 20px;
            border: 1px solid var(--primary);
            color: var(--dark);
            background: white;
            cursor: pointer;
            transition: all 0.2s ease;
            font-weight: 500;
        }
        
        .duration-selector select:hover {
            border-color: var(--accent);
            box-shadow: 0 0 0 2px rgba(108, 99, 255, 0.1);
        }
        
        .duration-selector select:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(108, 99, 255, 0.2);
        }
        
        .btn-action {
            padding: 10px 20px;
            border-radius: 50px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            border: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-size: 0.9rem;
        }
        
        .btn-remove {
            background: linear-gradient(135deg, #FF5252, #F44336);
            color: white;
            box-shadow: 0 4px 12px rgba(244, 67, 54, 0.2);
        }
        
        .btn-remove:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 20px rgba(244, 67, 54, 0.3);
            background: linear-gradient(135deg, #F44336, #D32F2F);
        }
        
        .btn-remove:active {
            transform: translateY(-1px);
        }
        
        .btn-clear {
            background: linear-gradient(135deg, #FF9800, #F57C00);
            color: white;
            box-shadow: 0 4px 12px rgba(255, 152, 0, 0.2);
        }
        
        .btn-clear:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 20px rgba(255, 152, 0, 0.3);
            background: linear-gradient(135deg, #F57C00, #EF6C00);
        }
        
        .btn-add-more {
            background: var(--light);
            color: var(--primary);
            border: 2px solid var(--primary);
        }
        
        .btn-add-more:hover {
            background: var(--primary);
            color: white;
            transform: translateY(-3px);
            box-shadow: var(--shadow);
        }
        
        .order-summary {
            background: white;
            border-radius: var(--border-radius);
            padding: 30px;
            box-shadow: var(--shadow-light);
            position: sticky;
            top: 120px;
            transition: transform 0.3s ease;
        }
        
        .order-summary:hover {
            transform: translateY(-5px);
        }
        
        .summary-title {
            font-size: 1.5rem;
            color: var(--dark);
            margin-bottom: 25px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .summary-title i {
            color: var(--primary);
        }
        
        .summary-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 15px;
            color: var(--dark);
            padding: 10px 0;
            border-bottom: 1px dashed var(--light);
        }
        
        .summary-row:hover {
            color: var(--primary);
        }
        
        .summary-total {
            display: flex;
            justify-content: space-between;
            margin-top: 20px;
            padding-top: 20px;
            border-top: 2px solid var(--primary);
            font-weight: 700;
            font-size: 1.2rem;
            color: var(--primary);
        }
        
        .summary-total:hover {
            color: var(--dark);
        }
        
        .cart-empty {
            text-align: center;
            padding: 80px 20px;
            background: white;
            border-radius: var(--border-radius);
            box-shadow: var(--shadow-light);
            animation: fadeIn 0.5s ease;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .cart-empty-icon {
            font-size: 5rem;
            color: var(--primary);
            margin-bottom: 20px;
            animation: bounce 2s infinite;
        }
        
        @keyframes bounce {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-10px); }
        }
        
        .cart-actions {
            display: flex;
            gap: 15px;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid var(--light);
        }
        
        .btn-checkout {
            background: linear-gradient(135deg, var(--primary), var(--accent));
            color: white;
            padding: 18px 30px;
            border-radius: 50px;
            font-weight: 600;
            font-size: 1.1rem;
            cursor: pointer;
            transition: all 0.3s ease;
            border: none;
            width: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            box-shadow: 0 6px 20px rgba(108, 99, 255, 0.3);
        }
        
        .btn-checkout:hover:not(:disabled) {
            transform: translateY(-5px) scale(1.02);
            box-shadow: 0 12px 30px rgba(108, 99, 255, 0.4);
        }
        
        .btn-checkout:active:not(:disabled) {
            transform: translateY(-2px);
        }
        
        .btn-checkout:disabled {
            opacity: 0.5;
            cursor: not-allowed;
            background: linear-gradient(135deg, #9E9E9E, #757575);
        }
        
        .pulse-animation {
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0% { box-shadow: 0 0 0 0 rgba(108, 99, 255, 0.7); }
            70% { box-shadow: 0 0 0 10px rgba(108, 99, 255, 0); }
            100% { box-shadow: 0 0 0 0 rgba(108, 99, 255, 0); }
        }
        
        .loading-spinner {
            display: inline-block;
            width: 16px;
            height: 16px;
            border: 2px solid rgba(255,255,255,0.3);
            border-radius: 50%;
            border-top-color: white;
            animation: spin 1s ease-in-out infinite;
        }
        
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        
        .notification {
            position: fixed;
            top: 100px;
            right: 20px;
            padding: 15px 25px;
            background: white;
            border-radius: 10px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.15);
            display: flex;
            align-items: center;
            gap: 10px;
            z-index: 1000;
            transform: translateX(400px);
            transition: transform 0.3s ease;
        }
        
        .notification.show {
            transform: translateX(0);
        }
        
        .notification.success {
            border-left: 4px solid #4CAF50;
        }
        
        .notification.error {
            border-left: 4px solid #F44336;
        }
        
        .notification.info {
            border-left: 4px solid #2196F3;
        }
        
        @media (max-width: 1100px) {
            .cart-container {
                grid-template-columns: 1fr;
            }
            
            .order-summary {
                position: static;
            }
        }
        
        @media (max-width: 768px) {
            .cart-item {
                flex-direction: column;
            }
            
            .item-actions {
                flex-direction: column;
            }
            
            .btn-checkout {
                padding: 15px 20px;
                font-size: 1rem;
            }
        }
    </style>
</head>
<body>
    <%@ include file="header.jsp" %>
    
    <!-- Notification Toast -->
    <div id="notification" class="notification" style="display: none;">
        <i class="fas fa-info-circle"></i>
        <span id="notification-message"></span>
    </div>
    
    <div class="container">
        <% if(cartItems.isEmpty()) { %>
        <div class="cart-empty">
            <div class="cart-empty-icon">
                <i class="fas fa-shopping-cart"></i>
            </div>
            <h2 style="color: var(--dark); margin-bottom: 15px;">Your cart is empty</h2>
            <p style="color: var(--gray); margin-bottom: 30px; max-width: 500px; margin-left: auto; margin-right: auto;">
                Add some books to your cart from our rental or purchase sections.
            </p>
            <div style="display: flex; gap: 15px; justify-content: center; flex-wrap: wrap;">
                <button class="btn btn-primary" onclick="window.location.href='rental.jsp'">
                    <i class="fas fa-calendar-alt"></i> Browse Rentals
                </button>
                <button class="btn btn-outline" onclick="window.location.href='purchase.jsp'">
                    <i class="fas fa-shopping-bag"></i> Browse Purchases
                </button>
            </div>
        </div>
        <% } else { %>
        
        <h1 style="margin-top: 50px; color: var(--dark);">Shopping Cart</h1>
        <p style="color: var(--gray); margin-bottom: 30px;">Review your selected books before checkout</p>
        
        <div class="cart-container">
            <!-- Cart Items -->
            <div class="cart-section">
                <div class="cart-header">
                    <h2>Items (<span id="cart-count"><%= cartItems.size() %></span>)</h2>
                    <button type="button" class="btn-action btn-clear" onclick="clearCart()" id="clear-cart-btn">
                        <i class="fas fa-trash-alt"></i> Clear Cart
                    </button>
                </div>
                
                <div class="items-list" id="cart-items-container">
                    <% 
                    for(Map<String, Object> item : cartItems) { 
                        String type = (String) item.get("type");
                        double price = (Double) item.get("price");
                        double displayPrice = (Double) item.get("display_price");
                        int rentalDays = (Integer) item.get("rental_days");
                        int available = (Integer) item.get("available");
                        
                        String availabilityClass = "available";
                        String availabilityText = "In stock";
                        if(available <= 0) {
                            availabilityClass = "unavailable";
                            availabilityText = "Out of stock";
                        } else if(available <= 2) {
                            availabilityClass = "low";
                            availabilityText = "Only " + available + " left";
                        }
                    %>
                    <div class="cart-item" id="cart-item-<%= item.get("cart_id") %>" data-cart-id="<%= item.get("cart_id") %>">
                        <div class="item-details">
                            <div class="item-title"><%= item.get("title") %></div>
                            <div class="item-author">by <%= item.get("author") %></div>
                            
                            <div class="item-meta">
                                <span class="item-type <%= type %>">
                                    <i class="fas fa-<%= type.equals("rental") ? "clock" : "crown" %>"></i>
                                    <%= type.equals("rental") ? "RENTAL" : "PURCHASE" %>
                                </span>
                                <span class="item-category"><%= item.get("category") %></span>
                                <span class="item-availability <%= availabilityClass %>">
                                    <i class="fas fa-<%= availabilityClass.equals("available") ? "check-circle" : 
                                                         availabilityClass.equals("low") ? "exclamation-triangle" : "times-circle" %>"></i>
                                    <%= availabilityText %>
                                </span>
                            </div>
                            
                            <div class="item-price-section">
                                <div>
                                    <div class="item-price" id="price-<%= item.get("cart_id") %>">&#8377;<%= df.format(price) %></div>
                                    <% if(type.equals("rental")) { %>
                                    <div class="item-daily-price">
                                        &#8377;<%= df.format(displayPrice) %>/day &times; 
                                        <span id="days-<%= item.get("cart_id") %>"><%= rentalDays %></span> days
                                    </div>
                                    <% } else { %>
                                    <div class="item-daily-price">
                                        One-time purchase
                                    </div>
                                    <% } %>
                                </div>
                            </div>
                            
                            <div class="item-actions">
                                <% if(type.equals("rental")) { %>
                                <div class="duration-selector">
                                    <label style="color: var(--gray); font-size: 0.9rem;">Duration:</label>
                                    <select id="duration-<%= item.get("cart_id") %>" onchange="updateRentalDays(<%= item.get("cart_id") %>, this.value)">
                                        <option value="7" <%= rentalDays == 7 ? "selected" : "" %>>7 days</option>
                                        <option value="14" <%= rentalDays == 14 ? "selected" : "" %>>14 days</option>
                                        <option value="30" <%= rentalDays == 30 ? "selected" : "" %>>30 days</option>
                                        <option value="60" <%= rentalDays == 60 ? "selected" : "" %>>60 days</option>
                                        <option value="90" <%= rentalDays == 90 ? "selected" : "" %>>90 days</option>
                                    </select>
                                </div>
                                <% } %>
                                
                                <button type="button" class="btn-action btn-remove" onclick="removeCartItem(<%= item.get("cart_id") %>)">
                                    <i class="fas fa-trash"></i> Remove
                                </button>
                            </div>
                        </div>
                    </div>
                    <% } %>
                </div>
                
                <div class="cart-actions">
                    <button class="btn-action btn-add-more" onclick="window.location.href='rental.jsp'" style="flex: 1;">
                        <i class="fas fa-plus"></i> Add More Books
                    </button>
                </div>
            </div>
            
            <!-- Order Summary -->
            <div class="order-summary">
                <h3 class="summary-title">
                    <i class="fas fa-receipt"></i> Order Summary
                </h3>
                
                <div class="summary-details">
                    <div class="summary-row">
                        <span>Subtotal (<span id="item-count"><%= cartItems.size() %></span> items)</span>
                        <span id="subtotal-display">&#8377;<%= df.format(subtotal) %></span>
                    </div>
                    <div class="summary-row">
                        <span>GST (18%)</span>
                        <span id="tax-display">&#8377;<%= df.format(tax) %></span>
                    </div>
                    <div class="summary-total">
                        <span>Total</span>
                        <span id="total-display">&#8377;<%= df.format(total) %></span>
                    </div>
                </div>
                
                <div style="margin: 30px 0;">
                    <div style="font-size: 0.9rem; color: var(--gray); margin-bottom: 10px; display: flex; align-items: center; gap: 8px;">
                        <i class="fas fa-lock" style="color: #4CAF50;"></i> Secure checkout
                    </div>
                    <div style="font-size: 0.9rem; color: var(--gray); display: flex; align-items: center; gap: 8px;">
                        <i class="fas fa-sync-alt" style="color: #2196F3;"></i> 30-day money-back guarantee
                    </div>
                </div>
                
                <% 
                boolean allAvailable = true;
                for(Map<String, Object> item : cartItems) {
                    if((Integer)item.get("available") <= 0) {
                        allAvailable = false;
                        break;
                    }
                }
                
                if(allAvailable) {
                %>
                <button class="btn-checkout pulse-animation" id="checkout-btn" onclick="proceedToCheckout()">
                    <i class="fas fa-shopping-bag"></i> Proceed to Checkout
                </button>
                <% } else { %>
                <div style="background: #FFF3E0; padding: 15px; border-radius: 10px; margin-bottom: 20px; border: 1px solid #FFB74D; animation: shake 0.5s;">
                    <div style="display: flex; align-items: center; gap: 10px; color: #EF6C00;">
                        <i class="fas fa-exclamation-triangle"></i>
                        <span style="font-size: 0.9rem;">Some items are out of stock. Please remove them to continue.</span>
                    </div>
                </div>
                <button class="btn-checkout" disabled id="checkout-btn">
                    <i class="fas fa-exclamation-circle"></i> Cannot Checkout
                </button>
                <% } %>
                
                <div style="text-align: center; margin-top: 20px;">
                    <a href="index.jsp" style="color: var(--primary); text-decoration: none; font-size: 0.9rem; display: flex; align-items: center; justify-content: center; gap: 8px;">
                        <i class="fas fa-arrow-left"></i> Continue Shopping
                    </a>
                </div>
            </div>
        </div>
        <% } %>
    </div>

    <script>
        // Show notification
        function showNotification(message, type = 'info') {
            const notification = document.getElementById('notification');
            const messageEl = document.getElementById('notification-message');
            
            notification.className = `notification ${type}`;
            notification.querySelector('i').className = type === 'success' ? 'fas fa-check-circle' :
                                                       type === 'error' ? 'fas fa-exclamation-circle' :
                                                       'fas fa-info-circle';
            messageEl.textContent = message;
            notification.style.display = 'flex';
            
            setTimeout(() => notification.classList.add('show'), 10);
            
            setTimeout(() => {
                notification.classList.remove('show');
                setTimeout(() => notification.style.display = 'none', 300);
            }, 3000);
        }
        
        // Update rental days with animation
        async function updateRentalDays(cartId, days) {
            const select = document.getElementById(`duration-${cartId}`);
            const daysEl = document.getElementById(`days-${cartId}`);
            const priceEl = document.getElementById(`price-${cartId}`);
            
            // Disable select during update
            select.disabled = true;
            select.innerHTML = `<option>Updating...</option>`;
            
            try {
                const response = await fetch('updateCart.jsp', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    body: `cart_id=${cartId}&rental_days=${days}`
                });
                
                if (response.ok) {
                    // Update UI immediately
                    daysEl.textContent = days;
                    
                    // Calculate new price (simulate - in real app, get from server)
                    const priceText = priceEl.textContent;
                    const price = parseFloat(priceText.replace(/\u20B9/, '')); // Remove rupee symbol
                    const dailyPrice = price / parseInt(daysEl.textContent);
                    const newPrice = dailyPrice * days;
                    priceEl.textContent = `\u20B9${newPrice.toFixed(2)}`;
                    
                    // Update summary
                    updateCartSummary();
                    
                    // Show success
                    showNotification('Rental duration updated successfully!', 'success');
                    
                    // Re-enable select with original options
                    setTimeout(() => {
                        select.disabled = false;
                        select.innerHTML = `
                            <option value="7" ${days == 7 ? 'selected' : ''}>7 days</option>
                            <option value="14" ${days == 14 ? 'selected' : ''}>14 days</option>
                            <option value="30" ${days == 30 ? 'selected' : ''}>30 days</option>
                            <option value="60" ${days == 60 ? 'selected' : ''}>60 days</option>
                            <option value="90" ${days == 90 ? 'selected' : ''}>90 days</option>
                        `;
                        select.value = days;
                    }, 1000);
                    
                } else {
                    throw new Error('Update failed');
                }
            } catch (error) {
                // Show error
                showNotification('Failed to update rental duration', 'error');
                console.error('Error:', error);
                
                // Re-enable select
                select.disabled = false;
                select.innerHTML = `
                    <option value="7">7 days</option>
                    <option value="14">14 days</option>
                    <option value="30">30 days</option>
                    <option value="60">60 days</option>
                    <option value="90">90 days</option>
                `;
                select.value = days;
            }
        }
        
        // Remove cart item with animation
        async function removeCartItem(cartId) {
            if (!confirm('Are you sure you want to remove this item from your cart?')) {
                return;
            }
            
            const cartItem = document.getElementById(`cart-item-${cartId}`);
            const removeBtn = cartItem.querySelector('.btn-remove');
            const originalText = removeBtn.innerHTML;
            
            // Show loading
            removeBtn.disabled = true;
            removeBtn.innerHTML = '<span class="loading-spinner"></span> Removing...';
            
            try {
                const response = await fetch('removeFromCart.jsp', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    body: `cart_id=${cartId}`
                });
                
                if (response.ok) {
                    // Animate removal
                    cartItem.style.opacity = '0.5';
                    cartItem.style.transform = 'translateX(-20px)';
                    
                    setTimeout(() => {
                        cartItem.style.height = cartItem.offsetHeight + 'px';
                        cartItem.style.overflow = 'hidden';
                        
                        setTimeout(() => {
                            cartItem.style.height = '0';
                            cartItem.style.padding = '0';
                            cartItem.style.margin = '0';
                            cartItem.style.border = 'none';
                            
                            setTimeout(() => {
                                cartItem.remove();
                                updateCartSummary();
                                showNotification('Item removed from cart', 'success');
                            }, 300);
                        }, 100);
                    }, 200);
                    
                } else {
                    throw new Error('Removal failed');
                }
            } catch (error) {
                // Show error
                showNotification('Failed to remove item', 'error');
                console.error('Error:', error);
                
                // Reset button
                removeBtn.disabled = false;
                removeBtn.innerHTML = originalText;
            }
        }
        
        // Clear entire cart
        async function clearCart() {
            if (!confirm('Are you sure you want to clear your entire cart?')) {
                return;
            }
            
            const clearBtn = document.getElementById('clear-cart-btn');
            const originalText = clearBtn.innerHTML;
            
            // Show loading
            clearBtn.disabled = true;
            clearBtn.innerHTML = '<span class="loading-spinner"></span> Clearing...';
            
            try {
                const response = await fetch('clearCart.jsp', {
                    method: 'POST'
                });
                
                if (response.ok) {
                    // Animate all items removal
                    const cartItems = document.querySelectorAll('.cart-item');
                    cartItems.forEach((item, index) => {
                        setTimeout(() => {
                            item.style.opacity = '0';
                            item.style.transform = 'translateX(-100px)';
                            item.style.height = '0';
                            item.style.padding = '0';
                            item.style.margin = '0';
                            item.style.border = 'none';
                        }, index * 100);
                    });
                    
                    // Reload page after animation
                    setTimeout(() => {
                        window.location.reload();
                    }, cartItems.length * 100 + 500);
                    
                } else {
                    throw new Error('Clear cart failed');
                }
            } catch (error) {
                // Show error
                showNotification('Failed to clear cart', 'error');
                console.error('Error:', error);
                
                // Reset button
                clearBtn.disabled = false;
                clearBtn.innerHTML = originalText;
            }
        }
        
        // Update cart summary (simulated - in real app, get from server)
        function updateCartSummary() {
            const cartItems = document.querySelectorAll('.cart-item');
            const itemCount = cartItems.length;
            
            // Update counts
            document.getElementById('cart-count').textContent = itemCount;
            document.getElementById('item-count').textContent = itemCount;
            
            // Recalculate totals (simulated)
            let subtotal = 0;
            cartItems.forEach(item => {
                const priceEl = item.querySelector('.item-price');
                if (priceEl) {
                    const priceText = priceEl.textContent;
                    const price = parseFloat(priceText.replace(/\u20B9/, '')); // Remove rupee symbol
                    subtotal += price;
                }
            });
            
            const tax = subtotal * 0.18; // 18% GST
            const total = subtotal + tax;
            
            // Update display
            document.getElementById('subtotal-display').textContent = `\u20B9${subtotal.toFixed(2)}`;
            document.getElementById('tax-display').textContent = `\u20B9${tax.toFixed(2)}`;
            document.getElementById('total-display').textContent = `\u20B9${total.toFixed(2)}`;
            
            // Check if all items are available
            let allAvailable = true;
            cartItems.forEach(item => {
                const availability = item.querySelector('.item-availability');
                if (availability && availability.classList.contains('unavailable')) {
                    allAvailable = false;
                }
            });
            
            // Update checkout button
            const checkoutBtn = document.getElementById('checkout-btn');
            if (allAvailable && itemCount > 0) {
                checkoutBtn.disabled = false;
                checkoutBtn.classList.add('pulse-animation');
                checkoutBtn.innerHTML = '<i class="fas fa-shopping-bag"></i> Proceed to Checkout';
            } else {
                checkoutBtn.disabled = true;
                checkoutBtn.classList.remove('pulse-animation');
                checkoutBtn.innerHTML = '<i class="fas fa-exclamation-circle"></i> Cannot Checkout';
            }
            
            // Show empty cart if no items
            if (itemCount === 0) {
                setTimeout(() => {
                    window.location.reload();
                }, 1000);
            }
        }
        
        // Proceed to checkout
        function proceedToCheckout() {
            const checkoutBtn = document.getElementById('checkout-btn');
            const originalText = checkoutBtn.innerHTML;
            
            // Show loading
            checkoutBtn.disabled = true;
            checkoutBtn.innerHTML = '<span class="loading-spinner"></span> Processing...';
            
            // Simulate processing delay
            setTimeout(() => {
                window.location.href = 'checkout.jsp';
            }, 1500);
        }
        
        // Initialize cart interactions
        document.addEventListener('DOMContentLoaded', function() {
            // Add hover effects
            const cartItems = document.querySelectorAll('.cart-item');
            cartItems.forEach(item => {
                item.addEventListener('mouseenter', function() {
                    this.style.transform = 'translateY(-5px)';
                    this.style.boxShadow = '0 10px 30px rgba(0,0,0,0.1)';
                });
                
                item.addEventListener('mouseleave', function() {
                    this.style.transform = 'translateY(0)';
                    this.style.boxShadow = 'none';
                });
            });
            
            // Check for messages from session
            <% 
            String cartMessage = (String) session.getAttribute("cartMessage");
            if(cartMessage != null && !cartMessage.isEmpty()) { 
            %>
                showNotification("<%= cartMessage %>", 'success');
                <% session.removeAttribute("cartMessage"); %>
            <% } %>
        });
        
        // Keypress shortcuts
        document.addEventListener('keydown', function(e) {
            // Ctrl/Cmd + Enter to checkout
            if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
                const checkoutBtn = document.getElementById('checkout-btn');
                if (checkoutBtn && !checkoutBtn.disabled) {
                    e.preventDefault();
                    proceedToCheckout();
                }
            }
            
            // Escape to continue shopping
            if (e.key === 'Escape') {
                window.location.href = 'index.jsp';
            }
        });
        
        // Add shake animation for unavailable items
        function shakeElement(element) {
            element.style.animation = 'shake 0.5s';
            setTimeout(() => element.style.animation = '', 500);
        }
    </script>
    
    <%@ include file="footer.jsp" %>
</body>
</html>