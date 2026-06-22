<%@ page contentType="text/html; charset=ISO-8859-1" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ include file="db_config.jsp" %>
<%
    // Set ISO-8859-1 encoding
    response.setContentType("text/html; charset=ISO-8859-1");
    response.setCharacterEncoding("ISO-8859-1");
    
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    if(username == null) {
        response.sendRedirect("login.jsp?redirect=rental.jsp");
        return;
    }
    
    List<Map<String, Object>> books = new ArrayList<>();
    Connection conn = null;
    
    try {
        conn = getConnection();
        String sql = "SELECT * FROM books WHERE rental_price_per_day > 0 AND available_copies > 0 ORDER BY title";
        PreparedStatement pstmt = conn.prepareStatement(sql);
        ResultSet rs = pstmt.executeQuery();
        
        while(rs.next()) {
            Map<String, Object> book = new HashMap<>();
            book.put("id", rs.getInt("book_id"));
            book.put("title", rs.getString("title"));
            book.put("author", rs.getString("author"));
            book.put("description", rs.getString("description"));
            book.put("category", rs.getString("category"));
            book.put("price", rs.getDouble("rental_price_per_day"));
            book.put("rating", rs.getDouble("rating"));
            book.put("available", rs.getInt("available_copies"));
            book.put("pages", rs.getInt("pages"));
            book.put("purchase_price", rs.getDouble("price"));
            books.add(book);
        }
        
        rs.close();
        pstmt.close();
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
    <title>Rent E-Books - ReadVerse</title>
    <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
    <style>
        .section-title {
            text-align: center;
            margin-bottom: 50px;
        }
        
        .section-title h2 {
            font-size: 2.8rem;
            margin-bottom: 15px;
            color: var(--dark);
        }
        
        .section-title p {
            font-size: 1.2rem;
            color: var(--gray);
            max-width: 600px;
            margin: 0 auto;
        }
        
        .duration-selector {
            margin-bottom: 40px;
            background: white;
            padding: 30px;
            border-radius: var(--border-radius);
            box-shadow: var(--shadow-light);
        }
        
        .duration-options {
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
        }
        
        .duration-btn {
            padding: 12px 25px;
            border-radius: 50px;
            font-weight: 600;
            cursor: pointer;
            transition: var(--transition);
            border: 2px solid var(--primary);
            background: transparent;
            color: var(--primary);
        }
        
        .duration-btn:hover {
            background: var(--primary);
            color: white;
            transform: translateY(-3px);
        }
        
        .duration-btn.active {
            background: var(--primary);
            color: white;
        }
        
        .books-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
            gap: 30px;
            margin-bottom: 80px;
        }
        
        .book-card {
            background: white;
            border-radius: var(--border-radius);
            overflow: hidden;
            box-shadow: var(--shadow-light);
            transition: var(--transition);
            position: relative;
        }
        
        .book-card:hover {
            transform: translateY(-10px);
            box-shadow: var(--shadow);
        }
        
        .rental-badge {
            position: absolute;
            top: 15px;
            left: 15px;
            background: var(--primary);
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 600;
            z-index: 2;
        }
        
        .book-card h3 {
            font-size: 1.3rem;
            color: var(--dark);
            margin: 0 0 10px 0;
            line-height: 1.3;
        }
        
        .book-rating {
            background: var(--primary);
            color: white;
            padding: 5px 10px;
            border-radius: 20px;
            font-size: 0.9rem;
            display: inline-flex;
            align-items: center;
            gap: 5px;
        }
        
        .category-tag {
            background: var(--light);
            color: var(--primary);
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9rem;
            display: inline-block;
        }
        
        .pages-tag {
            background: var(--light);
            color: var(--gray);
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9rem;
            display: inline-block;
        }
        
        .price-section {
            background: var(--light);
            padding: 15px;
            border-radius: 10px;
            margin: 20px 0;
        }
        
        .daily-price {
            font-size: 1.8rem;
            font-weight: 700;
            color: var(--primary);
        }
        
        .total-price {
            font-size: 1rem;
            color: var(--gray);
            margin-top: 5px;
        }
        
        .availability {
            text-align: center;
            padding: 10px;
            background: rgba(108, 99, 255, 0.1);
            border-radius: 10px;
        }
        
        .availability .count {
            font-size: 1.5rem;
            font-weight: 700;
            color: var(--primary);
        }
        
        .availability .label {
            font-size: 0.9rem;
            color: var(--gray);
        }
        
        .comparison {
            background: #E8F5E9;
            padding: 10px 15px;
            border-radius: 10px;
            margin-top: 15px;
            font-size: 0.9rem;
            color: #2E7D32;
        }
        
        .empty-state {
            grid-column: 1 / -1;
            text-align: center;
            padding: 60px 20px;
            background: white;
            border-radius: var(--border-radius);
            box-shadow: var(--shadow-light);
        }
        
        @media (max-width: 768px) {
            .books-grid {
                grid-template-columns: 1fr;
            }
            
            .duration-options {
                justify-content: center;
            }
            
            .section-title h2 {
                font-size: 2.2rem;
            }
        }
    </style>
</head>
<body>
    <%@ include file="header.jsp" %>
    
    <div class="container">
        <div class="section-title" style="margin-top: 50px;">
            <h2>Rent E-Books</h2>
            <p>Choose your reading duration and enjoy unlimited access</p>
        </div>
        
        <!-- Duration Selector -->
        <div class="duration-selector">
            <h3 style="margin-bottom: 20px; color: var(--dark);">
                <i class="fas fa-calendar-alt"></i> Select Rental Duration
            </h3>
            <div class="duration-options">
                <button type="button" class="duration-btn btn-outline" data-days="7">7 Days</button>
                <button type="button" class="duration-btn btn-outline" data-days="14">14 Days</button>
                <button type="button" class="duration-btn btn-outline active" data-days="30">30 Days</button>
                <button type="button" class="duration-btn btn-outline" data-days="60">60 Days</button>
                <button type="button" class="duration-btn btn-outline" data-days="90">90 Days</button>
            </div>
            <div style="margin-top: 20px; padding: 15px; background: var(--light); border-radius: 10px;">
                <p style="margin: 0; color: var(--primary); font-weight: 500;">
                    <i class="fas fa-info-circle"></i> Selected Duration: <span id="selected-duration">30</span> days
                </p>
            </div>
        </div>
        
        <!-- Rental Books Grid -->
        <div class="books-grid">
            <% 
            for(Map<String, Object> book : books) { 
                String description = (String) book.get("description");
                if(description == null) description = "";
                if(description.length() > 150) {
                    description = description.substring(0, 150) + "...";
                }
                
                // Assuming daily price is already in INR, if not convert:
                // double dailyPriceInDollars = rs.getDouble("rental_price_per_day");
                // double dailyPrice = dailyPriceInDollars * 83.0; // Convert to INR
                double dailyPrice = (Double) book.get("price");
                double initialTotal = dailyPrice * 30;
                
                // Assuming purchase price is already in INR, if not convert:
                // double purchasePriceInDollars = rs.getDouble("price");
                // double purchasePrice = purchasePriceInDollars * 83.0; // Convert to INR
                double purchasePrice = (Double) book.get("purchase_price");
                double savings = purchasePrice - initialTotal;
                Integer pages = (Integer) book.get("pages");
            %>
            <div class="book-card">
                <div style="background: var(--gradient-primary); height: 10px;"></div>
                <div class="rental-badge">
                    <i class="fas fa-clock"></i> RENTAL
                </div>
                <div style="padding: 25px;">
                    <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 15px;">
                        <h3><%= book.get("title") %></h3>
                        <span class="book-rating">
                            <i class="fas fa-star"></i> <%= String.format("%.1f", book.get("rating")) %>
                        </span>
                    </div>
                    
                    <p style="color: var(--gray); margin-bottom: 15px; font-size: 0.95rem;">
                        <i class="fas fa-user-pen"></i> <%= book.get("author") %>
                    </p>
                    
                    <div style="display: flex; gap: 10px; margin-bottom: 20px; flex-wrap: wrap;">
                        <span class="category-tag">
                            <i class="fas fa-tag"></i> <%= book.get("category") %>
                        </span>
                        <% if(pages != null && pages > 0) { %>
                        <span class="pages-tag">
                            <i class="fas fa-file-alt"></i> <%= pages %> pages
                        </span>
                        <% } %>
                    </div>
                    
                    <p style="color: var(--dark); margin-bottom: 20px; font-size: 0.95rem; line-height: 1.6;">
                        <%= description %>
                    </p>
                    
                    <div class="price-section">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                            <div>
                                <div class="daily-price">
                                    &#8377;<span class="daily-price-value"><%= String.format("%.2f", dailyPrice) %></span>/day
                                </div>
                                <div class="total-price">
                                    Total for <span class="duration-days-display">30</span> days: 
                                    &#8377;<span class="calculated-price"><%= String.format("%.2f", initialTotal) %></span>
                                </div>
                            </div>
                            
                            <div class="availability">
                                <div class="count"><%= book.get("available") %></div>
                                <div class="label">Available</div>
                            </div>
                        </div>
                        
                        <% if(savings > 0) { %>
                        <div class="comparison">
                            <i class="fas fa-piggy-bank"></i> Save &#8377;<%= String.format("%.2f", savings) %> vs buying
                        </div>
                        <% } %>
                    </div>
                    
                    <form action="addToCart.jsp" method="post" class="rental-form">
                        <input type="hidden" name="book_id" value="<%= book.get("id") %>">
                        <input type="hidden" name="type" value="rental">
                        <input type="hidden" name="rental_days" value="30" class="rental-days-input">
                        
                        <button type="submit" class="btn btn-primary" style="width: 100%;">
                            <i class="fas fa-cart-plus"></i> Add to Cart
                        </button>
                    </form>
                </div>
            </div>
            <% } %>
            
            <% if(books.isEmpty()) { %>
            <div class="empty-state">
                <div style="font-size: 5rem; color: var(--primary); margin-bottom: 20px;">
                    <i class="fas fa-book-open"></i>
                </div>
                <h3 style="color: var(--dark); margin-bottom: 15px;">No Books Available for Rental</h3>
                <p style="color: var(--gray); margin-bottom: 30px; max-width: 500px; margin-left: auto; margin-right: auto;">
                    All rental books are currently checked out. Please check back later or browse our purchase collection.
                </p>
                <button class="btn btn-primary" onclick="window.location.href='purchase.jsp'">
                    <i class="fas fa-shopping-bag"></i> Browse Purchases Instead
                </button>
            </div>
            <% } %>
        </div>
    </div>

    <script>
        // Duration selection
        document.querySelectorAll('.duration-btn').forEach(btn => {
            btn.addEventListener('click', function() {
                // Remove active class from all buttons
                document.querySelectorAll('.duration-btn').forEach(b => {
                    b.classList.remove('active');
                    b.classList.remove('btn-primary');
                    b.classList.add('btn-outline');
                });
                
                // Add active class to clicked button
                this.classList.remove('btn-outline');
                this.classList.add('btn-primary');
                this.classList.add('active');
                
                const days = this.dataset.days;
                document.getElementById('selected-duration').textContent = days;
                
                // Update all rental forms
                document.querySelectorAll('.rental-days-input').forEach(input => {
                    input.value = days;
                });
                
                // Update all duration displays
                document.querySelectorAll('.duration-days-display').forEach(display => {
                    display.textContent = days;
                });
                
                // Update calculated prices
                document.querySelectorAll('.book-card').forEach(card => {
                    const dailyPriceText = card.querySelector('.daily-price-value').textContent;
                    const dailyPrice = parseFloat(dailyPriceText);
                    const totalPrice = dailyPrice * days;
                    card.querySelector('.calculated-price').textContent = totalPrice.toFixed(2);
                });
            });
        });
        
        // Initialize with 30 days active
        document.addEventListener('DOMContentLoaded', function() {
            const thirtyDayBtn = document.querySelector('[data-days="30"]');
            if(thirtyDayBtn) {
                thirtyDayBtn.classList.add('active');
                thirtyDayBtn.classList.add('btn-primary');
                thirtyDayBtn.classList.remove('btn-outline');
            }
        });
        
        // Add to Cart form submission feedback
        document.querySelectorAll('.rental-form').forEach(form => {
            form.addEventListener('submit', function(e) {
                const button = this.querySelector('button');
                const originalText = button.innerHTML;
                const originalBg = button.style.background;
                
                button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Adding...';
                button.disabled = true;
                button.style.background = 'var(--gray)';
                
                setTimeout(() => {
                    button.innerHTML = originalText;
                    button.disabled = false;
                    button.style.background = originalBg;
                }, 2000);
            });
        });
    </script>
    
    <%@ include file="footer.jsp" %>
</body>
</html>