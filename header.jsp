<%@ page import="java.util.*" %>

<header class="site-header">
    <!-- your navbar HTML here -->
</header>

<!DOCTYPE html>
<html lang="en">
<head>
    <%@ include file="head_include.jsp" %>
    <title>ReadVerse | Premium E-Book Rental & Purchase</title>
    <style>
        /* Header Styles */
        header {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            z-index: 1000;
            padding: 20px 0;
            transition: var(--transition);
            background-color: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            box-shadow: 0 5px 20px rgba(0, 0, 0, 0.05);
        }
        
        header.scrolled {
            padding: 15px 0;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
        }
        
        .nav-container {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .logo {
            display: flex;
            align-items: center;
            font-size: 2rem;
            font-weight: 700;
            color: var(--dark);
            text-decoration: none;
            transition: var(--transition);
        }
        
        .logo span {
            background: var(--gradient-primary);
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
            margin-left: 5px;
        }
        
        .logo:hover {
            transform: translateY(-3px);
        }
        
        .nav-links {
            display: flex;
            list-style: none;
            gap: 40px;
        }
        
        .nav-links a {
            text-decoration: none;
            color: var(--dark);
            font-weight: 500;
            font-size: 1.05rem;
            position: relative;
            padding: 5px 0;
            transition: var(--transition);
        }
        
        .nav-links a::after {
            content: '';
            position: absolute;
            bottom: 0;
            left: 0;
            width: 0;
            height: 2px;
            background: var(--gradient-primary);
            transition: var(--transition);
        }
        
        .nav-links a:hover::after {
            width: 100%;
        }
        
        .nav-links a:hover {
            color: var(--primary);
        }
        
        .auth-buttons {
            display: flex;
            gap: 15px;
        }
        
        .btn {
            padding: 12px 25px;
            border-radius: 50px;
            font-weight: 600;
            font-size: 1rem;
            cursor: pointer;
            transition: var(--transition);
            border: none;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }
        
        .btn-outline {
            background: transparent;
            border: 2px solid var(--primary);
            color: var(--primary);
        }
        
        .btn-outline:hover {
            background: var(--primary);
            color: white;
            transform: translateY(-3px);
            box-shadow: var(--shadow);
        }
        
        .btn-primary {
            background: var(--gradient-primary);
            color: white;
            box-shadow: var(--shadow-light);
        }
        
        .btn-primary:hover {
            transform: translateY(-3px) scale(1.05);
            box-shadow: 0 15px 30px rgba(108, 99, 255, 0.3);
        }
        
        .btn-accent {
            background: var(--gradient-accent);
            color: white;
        }
        
        .btn-accent:hover {
            transform: translateY(-3px);
            box-shadow: 0 15px 30px rgba(255, 101, 132, 0.3);
        }
        
        .cart-icon {
            position: relative;
            text-decoration: none;
        }
        
        .cart-count {
            position: absolute;
            top: -8px;
            right: -8px;
            background: var(--secondary);
            color: white;
            border-radius: 50%;
            width: 20px;
            height: 20px;
            font-size: 0.8rem;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <header id="header">
        <div class="container">
            <nav class="nav-container">
                <a href="index.jsp" class="logo">
                    <i class="fas fa-book-open"></i>
                    Read<span>Verse</span>
                </a>
                
                <ul class="nav-links">
                    <li><a href="index.jsp">Home</a></li>
                    <li><a href="rental.jsp">Rentals</a></li>
                    <li><a href="purchase.jsp">Purchases</a></li>
                    <li><a href="category.jsp">Categories</a></li>
                    <li><a href="cart.jsp" class="cart-icon">

                        <i class="fas fa-shopping-cart"></i>
                        <%
                            Integer cartCount = (Integer) session.getAttribute("cartCount");
                            if(cartCount != null && cartCount > 0) {
                        %>
                            <span class="cart-count"><%= cartCount %></span>
                        <% } else { %>
                            <span class="cart-count" style="display: none;">0</span>
                        <% } %>
                    </a></li>
                </ul>
                
                <div class="auth-buttons">
                    <%
                        // Get username from session without redeclaring
                        Object userObj = session.getAttribute("username");
                        String sessionUsername = null;
                        if (userObj != null) {
                            sessionUsername = userObj.toString();
                        }
                        
                        if(sessionUsername != null && !sessionUsername.trim().isEmpty()) {
                    %>
                        <span style="margin-right: 15px; font-weight: 500; color: var(--primary); display: flex; align-items: center; gap: 8px;">
                            <i class="fas fa-user-circle"></i> <%= sessionUsername %>
                        </span>
                        <button class="btn btn-outline" onclick="window.location.href='logout.jsp'">
                            <i class="fas fa-sign-out-alt"></i> Logout
                        </button>
                    <% } else { %>
                        <button class="btn btn-outline" onclick="window.location.href='login.jsp'">
                            <i class="fas fa-sign-in-alt"></i> Log In
                        </button>
                        <button class="btn btn-primary" onclick="window.location.href='register.jsp'">
                            <i class="fas fa-user-plus"></i> Sign Up
                        </button>
                    <% } %>
                </div>
            </nav>
        </div>
    </header>

    <main>