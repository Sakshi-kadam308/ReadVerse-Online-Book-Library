<%@ page isELIgnored="true" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ include file="db_config.jsp" %>

<%
    String username = (String) session.getAttribute("username");
    if(username == null) {
        response.sendRedirect("login.jsp?redirect=purchase.jsp");
        return;
    }

    List<Map<String, Object>> books = new ArrayList<>();
    Connection conn = null;

    try {
        conn = getConnection();
        String sql = "SELECT * FROM books WHERE price > 0 AND available_copies > 0 ORDER BY title";
        PreparedStatement pstmt = conn.prepareStatement(sql);
        ResultSet rs = pstmt.executeQuery();

        while(rs.next()) {
            Map<String, Object> book = new HashMap<>();
            book.put("id", rs.getInt("book_id"));
            book.put("title", rs.getString("title"));
            book.put("author", rs.getString("author"));
            book.put("description", rs.getString("description"));
            book.put("category", rs.getString("category"));
            book.put("price", rs.getDouble("price"));
            book.put("rental_price", rs.getDouble("rental_price_per_day"));
            book.put("rating", rs.getDouble("rating"));
            book.put("pages", rs.getInt("pages"));
            book.put("available", rs.getInt("available_copies"));
            book.put("publisher", rs.getString("publisher"));
            book.put("published_date", rs.getDate("published_date"));
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
    <title>Purchase Books - ReadVerse</title>
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
        
        .purchase-badge {
            position: absolute;
            top: 15px;
            right: 15px;
            background: var(--secondary);
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
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }
        
        .purchase-price {
            font-size: 2rem;
            font-weight: 700;
            color: var(--primary);
        }
        
        .rental-comparison {
            font-size: 0.9rem;
            color: var(--gray);
            margin-top: 10px;
            padding-top: 10px;
            border-top: 1px solid rgba(0,0,0,0.1);
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
        
        .benefits {
            background: #E8F5E9;
            padding: 15px;
            border-radius: 10px;
            margin-top: 15px;
            font-size: 0.9rem;
            color: #2E7D32;
        }
        
        .benefits ul {
            list-style: none;
            padding-left: 0;
            margin: 10px 0 0 0;
        }
        
        .benefits li {
            margin-bottom: 5px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .benefits i {
            color: #4CAF50;
        }
        
        .empty-state {
            grid-column: 1 / -1;
            text-align: center;
            padding: 60px 20px;
            background: white;
            border-radius: var(--border-radius);
            box-shadow: var(--shadow-light);
        }
        
        .book-actions {
            display: flex;
            gap: 10px;
        }
        
        .book-actions .btn {
            flex: 1;
        }
        
        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.8);
            z-index: 2000;
            align-items: center;
            justify-content: center;
            padding: 20px;
            animation: fadeIn 0.3s ease;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        .modal-content {
            background: white;
            width: 90%;
            max-width: 700px;
            border-radius: var(--border-radius);
            position: relative;
            max-height: 90vh;
            overflow-y: auto;
            animation: slideUp 0.3s ease;
        }
        
        @keyframes slideUp {
            from { transform: translateY(50px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }
        
        .modal-header {
            background: var(--gradient-primary);
            padding: 30px;
            color: white;
            border-radius: var(--border-radius) var(--border-radius) 0 0;
        }
        
        .modal-body {
            padding: 30px;
        }
        
        .close-modal {
            position: absolute;
            top: 20px;
            right: 20px;
            background: none;
            border: none;
            font-size: 1.5rem;
            color: white;
            cursor: pointer;
            width: 40px;
            height: 40px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 50%;
            transition: var(--transition);
        }
        
        .close-modal:hover {
            background: rgba(255,255,255,0.2);
        }
        
        @media (max-width: 768px) {
            .books-grid {
                grid-template-columns: 1fr;
            }
            
            .section-title h2 {
                font-size: 2.2rem;
            }
            
            .book-actions {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <%@ include file="header.jsp" %>
    
    <div class="container">
        <div class="section-title" style="margin-top: 50px;">
            <h2>Purchase E-Books</h2>
            <p>Own your favorite books forever with lifetime access</p>
        </div>
        
        <!-- Purchase Books Grid -->
        <div class="books-grid">
            <% 
            for(Map<String, Object> book : books) { 
                String description = (String) book.get("description");
                if(description == null) description = "";
                
                double price = (Double) book.get("price");
                Double rentalPrice = (Double) book.get("rental_price");
                Integer pages = (Integer) book.get("pages");
                Integer available = (Integer) book.get("available");
                
                // Convert price to Rupees (assuming price in database is in INR)
                // If price in database is in dollars, you can convert it:
                // double priceInRupees = price * 83.0; // Assuming 1 USD = 83 INR
                // For now, assuming price is already in INR
                double priceInRupees = price;
                
                // Truncate description for card view
                String shortDescription = description.length() > 150 ? description.substring(0, 150) + "..." : description;
            %>
            <div class="book-card" data-book-id="<%= book.get("id") %>">
                <div style="background: linear-gradient(135deg, var(--primary) 0%, var(--accent) 100%); height: 10px;"></div>
                <div class="purchase-badge">
                    <i class="fas fa-crown"></i> OWN FOREVER
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
                        <%= shortDescription %>
                    </p>
                    
                    <div class="price-section">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                            <div>
                                <div class="purchase-price">
                                    ₹<%= String.format("%.2f", priceInRupees) %>
                                </div>
                                <div style="font-size: 0.9rem; color: var(--gray);">
                                    One-time payment • Lifetime access
                                </div>
                            </div>
                            
                            <div class="availability">
                                <div class="count"><%= available %></div>
                                <div class="label">Available</div>
                            </div>
                        </div>
                        
                        <% if(rentalPrice != null && rentalPrice > 0) { 
                            double rentalPrice30Days = rentalPrice * 30;
                            double saveAmount = priceInRupees - rentalPrice30Days;
                        %>
                        <div class="rental-comparison">
                            <i class="fas fa-calendar-alt"></i> Rental (30 days): ₹<%= String.format("%.2f", rentalPrice30Days) %>
                            • Save ₹<%= String.format("%.2f", saveAmount) %> by purchasing
                        </div>
                        <% } %>
                    </div>
                    
                    <div class="benefits">
                        <strong><i class="fas fa-check-circle"></i> Lifetime Benefits:</strong>
                        <ul>
                            <li><i class="fas fa-check"></i> Download in multiple formats</li>
                            <li><i class="fas fa-check"></i> Access on all devices</li>
                            <li><i class="fas fa-check"></i> Free updates for new editions</li>
                        </ul>
                    </div>
                    
                    <div class="book-actions">
                        <form action="addToCart.jsp" method="post" class="purchase-form" style="flex: 1;">
                            <input type="hidden" name="book_id" value="<%= book.get("id") %>">
                            <input type="hidden" name="type" value="purchase">
                            
                            <button type="submit" class="btn btn-primary">
                                <i class="fas fa-cart-plus"></i> Add to Cart
                            </button>
                        </form>
                        
                        <button type="button" class="btn btn-outline view-details-btn" 
                                data-book-id="<%= book.get("id") %>"
                                data-title="<%= book.get("title") %>"
                                data-author="<%= book.get("author") %>"
                                data-description="<%= description.replace("\"", "\\\"") %>"
                                data-price="<%= priceInRupees %>"
                                data-rating="<%= book.get("rating") %>"
                                data-category="<%= book.get("category") %>"
                                data-pages="<%= pages != null ? pages : 0 %>"
                                data-publisher="<%= book.get("publisher") != null ? book.get("publisher").toString().replace("\"", "\\\"") : "" %>"
                                data-published-date="<%= book.get("published_date") != null ? book.get("published_date") : "" %>">
                            <i class="fas fa-eye"></i> Details
                        </button>
                    </div>
                </div>
            </div>
            <% } %>
            
            <% if(books.isEmpty()) { %>
            <div class="empty-state">
                <div style="font-size: 5rem; color: var(--primary); margin-bottom: 20px;">
                    <i class="fas fa-book"></i>
                </div>
                <h3 style="color: var(--dark); margin-bottom: 15px;">No Books Available for Purchase</h3>
                <p style="color: var(--gray); margin-bottom: 30px; max-width: 500px; margin-left: auto; margin-right: auto;">
                    All purchasable books are currently out of stock. Please check back later or browse our rental collection.
                </p>
                <button class="btn btn-primary" onclick="window.location.href='rental.jsp'">
                    <i class="fas fa-calendar-alt"></i> Browse Rentals Instead
                </button>
            </div>
            <% } %>
        </div>
    </div>

    <!-- Book Details Modal -->
    <div id="bookModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close-modal" onclick="closeModal()">
                    <i class="fas fa-times"></i>
                </button>
                <h2 id="modalTitle" style="margin: 0; font-size: 2rem;"></h2>
                <p id="modalAuthor" style="margin: 10px 0 0 0; opacity: 0.9; font-size: 1.1rem;"></p>
            </div>
            <div class="modal-body">
                <div id="modalContent">
                    <!-- Content will be loaded here -->
                </div>
            </div>
        </div>
    </div>

    <script>
        // Book details modal functionality
        document.querySelectorAll('.view-details-btn').forEach(btn => {
            btn.addEventListener('click', function() {
                const bookId = this.dataset.bookId;
                const title = this.dataset.title;
                const author = this.dataset.author;
                const description = this.dataset.description;
                const price = parseFloat(this.dataset.price);
                const rating = parseFloat(this.dataset.rating);
                const category = this.dataset.category;
                const pages = parseInt(this.dataset.pages);
                const publisher = this.dataset.publisher;
                const publishedDate = this.dataset.publishedDate;
                
                // Format published date
                let formattedDate = '';
                if(publishedDate) {
                    const date = new Date(publishedDate);
                    formattedDate = date.toLocaleDateString('en-US', {
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric'
                    });
                }
                
                // Update modal title and author
                document.getElementById('modalTitle').textContent = title;
                document.getElementById('modalAuthor').textContent = 'by ' + author;
                
                // Build modal content
                let modalContent = `
                    <div style="display: flex; gap: 20px; margin-bottom: 30px; flex-wrap: wrap;">
                        <span class="category-tag" style="background: var(--light); color: var(--primary); padding: 8px 20px; border-radius: 20px; font-size: 1rem;">
                            <i class="fas fa-tag"></i> ${category}
                        </span>
                        <span class="book-rating" style="background: var(--primary); color: white; padding: 8px 20px; border-radius: 20px; font-size: 1rem;">
                            <i class="fas fa-star"></i> ${rating.toFixed(1)}/5.0
                        </span>
                        ${pages > 0 ? `<span style="background: var(--light); color: var(--gray); padding: 8px 20px; border-radius: 20px; font-size: 1rem;">
                            <i class="fas fa-file-alt"></i> ${pages} pages
                        </span>` : ''}
                    </div>
                    
                    <div style="margin-bottom: 30px;">
                        <h3 style="color: var(--dark); margin-bottom: 15px; font-size: 1.3rem;">
                            <i class="fas fa-align-left"></i> Description
                        </h3>
                        <p style="color: var(--dark); line-height: 1.8; font-size: 1.05rem;">
                            ${description}
                        </p>
                    </div>
                    
                    ${publisher || formattedDate ? `
                    <div style="background: var(--light); padding: 20px; border-radius: 10px; margin-bottom: 30px;">
                        <h3 style="color: var(--dark); margin-bottom: 15px; font-size: 1.3rem;">
                            <i class="fas fa-info-circle"></i> Publication Details
                        </h3>
                        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px;">
                            ${publisher ? `
                            <div>
                                <div style="font-size: 0.9rem; color: var(--gray);">Publisher</div>
                                <div style="font-weight: 600; color: var(--dark);">${publisher}</div>
                            </div>
                            ` : ''}
                            ${formattedDate ? `
                            <div>
                                <div style="font-size: 0.9rem; color: var(--gray);">Published Date</div>
                                <div style="font-weight: 600; color: var(--dark);">${formattedDate}</div>
                            </div>
                            ` : ''}
                        </div>
                    </div>
                    ` : ''}
                    
                    <div style="background: linear-gradient(135deg, rgba(108, 99, 255, 0.1) 0%, rgba(54, 209, 220, 0.1) 100%); 
                         padding: 25px; border-radius: 10px; margin-bottom: 30px;">
                        <h3 style="color: var(--primary); margin-bottom: 20px; font-size: 1.3rem;">
                            <i class="fas fa-gift"></i> What You Get
                        </h3>
                        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px;">
                            <div style="display: flex; align-items: start; gap: 10px;">
                                <i class="fas fa-check-circle" style="color: #4CAF50; font-size: 1.2rem; margin-top: 3px;"></i>
                                <div>
                                    <div style="font-weight: 600; color: var(--dark);">Lifetime Access</div>
                                    <div style="color: var(--gray); font-size: 0.9rem;">Own this book forever</div>
                                </div>
                            </div>
                            <div style="display: flex; align-items: start; gap: 10px;">
                                <i class="fas fa-check-circle" style="color: #4CAF50; font-size: 1.2rem; margin-top: 3px;"></i>
                                <div>
                                    <div style="font-weight: 600; color: var(--dark);">Multiple Formats</div>
                                    <div style="color: var(--gray); font-size: 0.9rem;">PDF, EPUB, MOBI included</div>
                                </div>
                            </div>
                            <div style="display: flex; align-items: start; gap: 10px;">
                                <i class="fas fa-check-circle" style="color: #4CAF50; font-size: 1.2rem; margin-top: 3px;"></i>
                                <div>
                                    <div style="font-weight: 600; color: var(--dark);">Free Updates</div>
                                    <div style="color: var(--gray); font-size: 0.9rem;">Get revised editions free</div>
                                </div>
                            </div>
                            <div style="display: flex; align-items: start; gap: 10px;">
                                <i class="fas fa-check-circle" style="color: #4CAF50; font-size: 1.2rem; margin-top: 3px;"></i>
                                <div>
                                    <div style="font-weight: 600; color: var(--dark);">All Devices</div>
                                    <div style="color: var(--gray); font-size: 0.9rem;">Read on phone, tablet, PC</div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div style="display: flex; justify-content: space-between; align-items: center; 
                         background: white; padding: 25px; border-radius: 10px; border: 2px solid var(--primary);">
                        <div>
                            <div style="font-size: 0.9rem; color: var(--gray);">One-time Payment</div>
                            <div style="font-size: 2.5rem; font-weight: 700; color: var(--primary);">
                                ₹${price.toFixed(2)}
                            </div>
                            <div style="font-size: 0.9rem; color: var(--gray); margin-top: 5px;">
                                <i class="fas fa-shield-alt"></i> Secure purchase • 30-day money-back guarantee
                            </div>
                        </div>
                        <div style="display: flex; gap: 10px;">
                            <form action="addToCart.jsp" method="post" style="display: inline;">
                                <input type="hidden" name="book_id" value="${bookId}">
                                <input type="hidden" name="type" value="purchase">
                                <button type="submit" class="btn btn-primary" style="padding: 15px 30px;">
                                    <i class="fas fa-cart-plus"></i> Add to Cart
                                </button>
                            </form>
                            <button type="button" class="btn btn-outline" onclick="closeModal()" style="padding: 15px 30px;">
                                <i class="fas fa-arrow-left"></i> Back
                            </button>
                        </div>
                    </div>
                `;
                
                document.getElementById('modalContent').innerHTML = modalContent;
                document.getElementById('bookModal').style.display = 'flex';
            });
        });
        
        function closeModal() {
            document.getElementById('bookModal').style.display = 'none';
        }
        
        // Close modal when clicking outside
        document.getElementById('bookModal').addEventListener('click', function(e) {
            if(e.target === this) {
                closeModal();
            }
        });
        
        // Close modal with Escape key
        document.addEventListener('keydown', function(e) {
            if(e.key === 'Escape') {
                closeModal();
            }
        });
        
        // Add to Cart form submission feedback
        document.querySelectorAll('.purchase-form').forEach(form => {
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