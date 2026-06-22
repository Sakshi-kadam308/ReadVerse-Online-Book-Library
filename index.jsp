<%@ page contentType="text/html; charset=ISO-8859-1" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <%@ include file="head_include.jsp" %>
    <title>ReadVerse | Premium E-Book Rental & Purchase</title>
    <style>
        /* Hero Section Styles */
        .hero {
            padding: 120px 0 80px;
            background: linear-gradient(135deg, rgba(108, 99, 255, 0.05) 0%, rgba(54, 209, 220, 0.05) 100%);
            position: relative;
            overflow: hidden;
        }
        
        .hero::before {
            content: '';
            position: absolute;
            top: -50%;
            right: -10%;
            width: 700px;
            height: 700px;
            border-radius: 50%;
            background: linear-gradient(135deg, rgba(108, 99, 255, 0.1) 0%, rgba(54, 209, 220, 0.1) 100%);
            z-index: 0;
        }
        
        .hero-content {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 60px;
            align-items: center;
            position: relative;
            z-index: 1;
        }
        
        .hero-text h1 {
            font-size: 3.8rem;
            margin-bottom: 20px;
            background: linear-gradient(135deg, var(--dark) 0%, var(--primary) 100%);
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
            line-height: 1.1;
        }
        
        .hero-text p {
            font-size: 1.2rem;
            color: var(--gray);
            margin-bottom: 30px;
            max-width: 90%;
        }
        
        .hero-buttons {
            display: flex;
            gap: 20px;
            margin-top: 40px;
        }
        
        .stats {
            display: flex;
            gap: 40px;
            margin-top: 50px;
        }
        
        .stat-item {
            text-align: center;
        }
        
        .stat-number {
            font-size: 2.5rem;
            font-weight: 700;
            background: var(--gradient-primary);
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
            line-height: 1;
        }
        
        .stat-label {
            font-size: 0.9rem;
            color: var(--gray);
            margin-top: 5px;
        }
        
        .hero-image {
            position: relative;
            animation: float 6s ease-in-out infinite;
        }
        
        @keyframes float {
            0% { transform: translateY(0px); }
            50% { transform: translateY(-20px); }
            100% { transform: translateY(0px); }
        }
        
        .book-stack {
            position: relative;
            width: 100%;
            height: 400px;
        }
        
        .book {
            position: absolute;
            width: 250px;
            height: 320px;
            border-radius: 10px;
            box-shadow: var(--shadow);
            overflow: hidden;
            transition: var(--transition);
        }
        
        .book-1 {
            top: 0;
            left: 50%;
            transform: translateX(-50%) rotate(-5deg);
            background: linear-gradient(45deg, #FF9A9E, #FAD0C4);
            z-index: 3;
        }
        
        .book-2 {
            top: 15px;
            left: 30%;
            transform: rotate(3deg);
            background: linear-gradient(45deg, #A1C4FD, #C2E9FB);
            z-index: 2;
        }
        
        .book-3 {
            top: 30px;
            left: 60%;
            transform: rotate(-8deg);
            background: linear-gradient(45deg, #FFECD2, #FCB69F);
            z-index: 1;
        }
        
        .book:hover {
            transform: scale(1.05) rotate(0deg);
            z-index: 10;
        }
        
        /* Features Section */
        .features {
            padding: 120px 0;
            background: white;
        }
        
        .section-title {
            text-align: center;
            margin-bottom: 70px;
        }
        
        .section-title h2 {
            font-size: 3rem;
            margin-bottom: 15px;
            color: var(--dark);
        }
        
        .section-title p {
            font-size: 1.2rem;
            color: var(--gray);
            max-width: 600px;
            margin: 0 auto;
        }
        
        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 40px;
        }
        
        .feature-card {
            background: white;
            padding: 40px 30px;
            border-radius: var(--border-radius);
            box-shadow: var(--shadow-light);
            transition: var(--transition);
            text-align: center;
            position: relative;
            overflow: hidden;
            z-index: 1;
        }
        
        .feature-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 5px;
            background: var(--gradient-primary);
            transition: var(--transition);
        }
        
        .feature-card:hover {
            transform: translateY(-15px);
            box-shadow: var(--shadow);
        }
        
        .feature-card:hover::before {
            height: 100%;
            opacity: 0.05;
        }
        
        .feature-icon {
            width: 80px;
            height: 80px;
            background: var(--gradient-primary);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 25px;
            font-size: 2rem;
            color: white;
            transition: var(--transition);
        }
        
        .feature-card:hover .feature-icon {
            transform: scale(1.1) rotate(5deg);
        }
        
        .feature-card h3 {
            font-size: 1.5rem;
            margin-bottom: 15px;
            color: var(--dark);
        }
        
        /* Responsive */
        @media (max-width: 1100px) {
            .hero-content {
                grid-template-columns: 1fr;
                text-align: center;
            }
            
            .hero-text p {
                max-width: 100%;
            }
            
            .stats {
                justify-content: center;
            }
        }
        
        @media (max-width: 768px) {
            .hero-text h1 {
                font-size: 2.8rem;
            }
            
            .hero-buttons {
                flex-direction: column;
                align-items: center;
            }
            
            .btn {
                width: 100%;
                max-width: 300px;
            }
            
            .stats {
                flex-direction: column;
                gap: 30px;
            }
            
            .section-title h2 {
                font-size: 2.5rem;
            }
            
            .features-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <%@ include file="header.jsp" %>
    
    <!-- Hero Section -->
    <section class="hero">
        <div class="container">
            <div class="hero-content">
                <div class="hero-text">
                    <h1>Unlock Worlds With Every Page Turn</h1>
                    <p>Discover, rent, or own your next literary adventure from our vast collection of e-books. Read anywhere, anytime, on any device with our seamless reading experience.</p>
                    
                    <div class="hero-buttons">
                        
                        <button class="btn btn-outline" onclick="window.location.href='purchase.jsp'">
                            <i class="fas fa-search"></i> Browse Library
                        </button>
                    </div>
                    
                    <div class="stats">
                        <div class="stat-item">
                            <div class="stat-number">75K+</div>
                            <div class="stat-label">E-Books</div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-number">24/7</div>
                            <div class="stat-label">Access</div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-number">80%</div>
                            <div class="stat-label">Save on Rentals</div>
                        </div>
                    </div>
                </div>
                
                <div class="hero-image">
                    <div class="book-stack">
                        <div class="book book-1"></div>
                        <div class="book book-2"></div>
                        <div class="book book-3"></div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Features Section -->
    <section class="features">
        <div class="container">
            <div class="section-title">
                <h2>Why Readers Love ReadVerse</h2>
                <p>Experience the future of reading with our premium features designed for modern book lovers</p>
            </div>
            
            <div class="features-grid">
                <div class="feature-card">
                    <div class="feature-icon">
                        <i class="fas fa-mobile-alt"></i>
                    </div>
                    <h3>Read Anywhere</h3>
                    <p>Seamlessly switch between devices with automatic sync. Pick up where you left off on any phone, tablet, or computer.</p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">
                        <i class="fas fa-calendar-alt"></i>
                    </div>
                    <h3>Flexible Rentals</h3>
                    <p>Choose from 7, 14, or 30-day rentals. Extend or return early with no extra fees. Perfect for vacations or quick reads.</p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">
                        <i class="fas fa-heart"></i>
                    </div>
                    <h3>Personalized Library</h3>
                    <p>Get AI-powered recommendations based on your reading history. Build your own digital bookshelf with favorites.</p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">
                        <i class="fas fa-eye"></i>
                    </div>
                    <h3>Eye Comfort Mode</h3>
                    <p>Customizable reading experience with adjustable fonts, spacing, and dark mode for comfortable reading day or night.</p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">
                        <i class="fas fa-dollar-sign"></i>
                    </div>
                    <h3>Save up to 80%</h3>
                    <p>Rent popular titles at a fraction of the cost, or purchase e-books outright. No hidden fees, cancel anytime.</p>
                </div>
                
                <div class="feature-card">
                    <div class="feature-icon">
                        <i class="fas fa-download"></i>
                    </div>
                    <h3>Offline Reading</h3>
                    <p>Download e-books to read without an internet connection. Perfect for flights, commutes, or remote locations.</p>
                </div>
            </div>
        </div>
    </section>

    <script>
        // Book stack hover effects
        document.addEventListener('DOMContentLoaded', function() {
            const books = document.querySelectorAll('.book');
            books.forEach(book => {
                book.addEventListener('mouseenter', function() {
                    books.forEach(b => {
                        if (b !== this) b.style.zIndex = '1';
                    });
                    this.style.zIndex = '10';
                });
            });
            
            // Check for cart message
            <%
            String cartMessage = (String) session.getAttribute("cartMessage");
            if(cartMessage != null && !cartMessage.isEmpty()) {
            %>
                setTimeout(function() {
                    alert("<%= cartMessage %>");
                    <%
                    session.removeAttribute("cartMessage");
                    %>
                }, 1000);
            <%
            }
            %>
        });
    </script>
    
    <%@ include file="footer.jsp" %>
</body>
</html>