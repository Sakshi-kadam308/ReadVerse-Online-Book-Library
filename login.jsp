<%@ page contentType="text/html; charset=ISO-8859-1" %>
<%@ page import="java.sql.*" %>
<%@ include file="db_config.jsp" %>
<%
    // Handle login form submission
    if("POST".equals(request.getMethod())) {
        String loginUsername = request.getParameter("username");
        String password = request.getParameter("password");
        String userType = request.getParameter("user_type");
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            
            // Check if it's admin login
            if("admin".equals(userType)) {
                String sql = "SELECT admin_id, username, email, full_name, role FROM admin_users WHERE username = ? AND password = ? AND status = 'active'";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, loginUsername);
                pstmt.setString(2, password);
                
                rs = pstmt.executeQuery();
                
                if(rs.next()) {
                    // Successful admin login
                    session.setAttribute("admin_id", String.valueOf(rs.getInt("admin_id")));
                    session.setAttribute("admin_username", rs.getString("username"));
                    session.setAttribute("admin_email", rs.getString("email"));
                    session.setAttribute("admin_full_name", rs.getString("full_name"));
                    session.setAttribute("admin_role", rs.getString("role"));
                    session.setAttribute("is_admin", "true");
                    
                    response.sendRedirect("admin-dashboard.jsp");
                    return;
                }
            } else {
                // Regular user login
                String sql = "SELECT user_id, username, email, full_name FROM users WHERE username = ? AND password = ?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, loginUsername);
                pstmt.setString(2, password);
                
                rs = pstmt.executeQuery();
                
                if(rs.next()) {
                    // Successful user login
                    session.setAttribute("user_id", String.valueOf(rs.getInt("user_id")));
                    session.setAttribute("username", rs.getString("username"));
                    session.setAttribute("email", rs.getString("email"));
                    session.setAttribute("full_name", rs.getString("full_name"));
                    
                    // Get cart count
                    String cartSql = "SELECT COUNT(*) as count FROM cart WHERE user_id = ?";
                    PreparedStatement cartStmt = conn.prepareStatement(cartSql);
                    cartStmt.setInt(1, rs.getInt("user_id"));
                    ResultSet cartRs = cartStmt.executeQuery();
                    if(cartRs.next()) {
                        session.setAttribute("cartCount", cartRs.getInt("count"));
                    } else {
                        session.setAttribute("cartCount", 0);
                    }
                    cartRs.close();
                    cartStmt.close();
                    
                    // Redirect to requested page or home
                    String redirect = request.getParameter("redirect");
                    if(redirect != null && !redirect.isEmpty()) {
                        response.sendRedirect(redirect);
                    } else {
                        response.sendRedirect("index.jsp");
                    }
                    return;
                }
            }
            
            // Demo login for testing (remove in production)
            if("user".equals(userType)) {
                session.setAttribute("user_id", "1");
                session.setAttribute("username", "demo_user");
                session.setAttribute("email", "demo@readverse.com");
                session.setAttribute("full_name", "Demo User");
                session.setAttribute("cartCount", 0);
                
                String redirect = request.getParameter("redirect");
                if(redirect != null && !redirect.isEmpty()) {
                    response.sendRedirect(redirect);
                } else {
                    response.sendRedirect("index.jsp");
                }
            } else if("admin".equals(userType)) {
                session.setAttribute("admin_id", "1");
                session.setAttribute("admin_username", "admin");
                session.setAttribute("admin_email", "admin@readverse.com");
                session.setAttribute("admin_full_name", "Administrator");
                session.setAttribute("admin_role", "super_admin");
                session.setAttribute("is_admin", "true");
                
                response.sendRedirect("admin-dashboard.jsp");
            }
            return;
            
        } catch(Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Login failed: " + e.getMessage());
        } finally {
            if(rs != null) try { rs.close(); } catch(Exception e) {}
            if(pstmt != null) try { pstmt.close(); } catch(Exception e) {}
            if(conn != null) try { conn.close(); } catch(Exception e) {}
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <%@ include file="head_include.jsp" %>
    <title>Login - ReadVerse</title>
    <style>
        :root {
            --primary: #6c63ff;
            --primary-dark: #554fd8;
            --secondary: #36d1dc;
            --secondary-dark: #2aaeb8;
            --success: #28a745;
            --warning: #ffc107;
            --danger: #dc3545;
            --dark: #2a2a3c;
            --light: #f8f9fa;
            --gray: #6c757d;
            --border-radius: 15px;
            --transition: all 0.3s ease;
            --shadow: 0 10px 30px rgba(0, 0, 0, 0.08);
            --shadow-hover: 0 15px 40px rgba(108, 99, 255, 0.15);
            --gradient-primary: linear-gradient(135deg, #6c63ff 0%, #36d1dc 100%);
            --gradient-secondary: linear-gradient(135deg, #ff6b6b 0%, #ffd93d 100%);
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        
        body {
            background: linear-gradient(135deg, #f5f7ff 0%, #eef5ff 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        
        .login-container {
            width: 100%;
            max-width: 480px;
            animation: fadeIn 0.5s ease-out;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .login-box {
            background: white;
            border-radius: var(--border-radius);
            box-shadow: var(--shadow);
            overflow: hidden;
            transition: var(--transition);
        }
        
        .login-box:hover {
            box-shadow: var(--shadow-hover);
            transform: translateY(-5px);
        }
        
        .login-header {
            background: var(--gradient-primary);
            padding: 50px 30px;
            text-align: center;
            color: white;
            position: relative;
            overflow: hidden;
        }
        
        .login-header::before {
            content: '';
            position: absolute;
            top: -50%;
            left: -50%;
            width: 200%;
            height: 200%;
            background: radial-gradient(circle, rgba(255,255,255,0.1) 1px, transparent 1px);
            background-size: 20px 20px;
            animation: float 20s linear infinite;
            opacity: 0.3;
        }
        
        @keyframes float {
            0% { transform: translate(0, 0) rotate(0deg); }
            100% { transform: translate(-20px, -20px) rotate(360deg); }
        }
        
        .login-header h1 {
            font-size: 2.8rem;
            margin-bottom: 15px;
            font-weight: 800;
            letter-spacing: -0.5px;
            position: relative;
            z-index: 1;
        }
        
        .login-header p {
            font-size: 1.1rem;
            opacity: 0.9;
            font-weight: 300;
            position: relative;
            z-index: 1;
        }
        
        .login-body {
            padding: 45px 40px;
        }
        
        .alert {
            padding: 18px;
            border-radius: 12px;
            margin-bottom: 30px;
            font-size: 0.95rem;
            display: flex;
            align-items: center;
            gap: 12px;
            border-left: 5px solid;
            animation: slideIn 0.4s ease-out;
        }
        
        @keyframes slideIn {
            from { opacity: 0; transform: translateX(-20px); }
            to { opacity: 1; transform: translateX(0); }
        }
        
        .alert-info {
            background: linear-gradient(135deg, #e3f2fd 0%, #f0f8ff 100%);
            color: #1565c0;
            border-color: #2196f3;
        }
        
        .alert-danger {
            background: linear-gradient(135deg, #ffebee 0%, #fff5f5 100%);
            color: #c62828;
            border-color: #f44336;
        }
        
        .user-type-selector {
            display: flex;
            margin-bottom: 30px;
            border-radius: 12px;
            overflow: hidden;
            border: 2px solid #e1e5f1;
            background: #f8fafc;
            position: relative;
        }
        
        .user-type-option {
            flex: 1;
            text-align: center;
            padding: 20px 15px;
            cursor: pointer;
            transition: var(--transition);
            position: relative;
            z-index: 1;
        }
        
        .user-type-option input[type="radio"] {
            display: none;
        }
        
        .user-type-option label {
            margin: 0;
            cursor: pointer;
            font-weight: 600;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            font-size: 1rem;
            transition: var(--transition);
        }
        
        .user-type-option:hover {
            background: rgba(108, 99, 255, 0.05);
        }
        
        .user-type-option.active {
            background: var(--primary);
            color: white;
        }
        
        .user-type-option.active label {
            color: white;
        }
        
        .form-group {
            margin-bottom: 28px;
            position: relative;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 10px;
            color: var(--dark);
            font-weight: 600;
            font-size: 0.95rem;
        }
        
        .form-control {
            width: 100%;
            padding: 18px 20px;
            border: 2px solid #e1e5f1;
            border-radius: 12px;
            font-size: 1rem;
            color: var(--dark);
            transition: var(--transition);
            background: #f8fafc;
            font-weight: 500;
        }
        
        .form-control:focus {
            outline: none;
            border-color: var(--primary);
            background: white;
            box-shadow: 0 0 0 4px rgba(108, 99, 255, 0.15);
            transform: translateY(-2px);
        }
        
        .form-control:hover {
            border-color: #b8c1e0;
        }
        
        .password-toggle {
            position: absolute;
            right: 20px;
            top: 50px;
            background: none;
            border: none;
            color: var(--gray);
            cursor: pointer;
            font-size: 1.1rem;
            transition: var(--transition);
            padding: 5px;
        }
        
        .password-toggle:hover {
            color: var(--primary);
            transform: scale(1.1);
        }
        
        /* Enhanced Button Styles */
        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 12px;
            padding: 18px 30px;
            border-radius: 12px;
            font-size: 1.1rem;
            font-weight: 600;
            text-decoration: none;
            cursor: pointer;
            transition: var(--transition);
            border: none;
            position: relative;
            overflow: hidden;
            letter-spacing: 0.5px;
        }
        
        .btn::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 50%;
            width: 0;
            height: 0;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.3);
            transform: translate(-50%, -50%);
            transition: width 0.6s, height 0.6s;
        }
        
        .btn:hover::before {
            width: 300px;
            height: 300px;
        }
        
        .btn-primary {
            background: var(--gradient-primary);
            color: white;
            width: 100%;
            box-shadow: 0 6px 20px rgba(108, 99, 255, 0.3);
        }
        
        .btn-primary:hover {
            transform: translateY(-4px);
            box-shadow: 0 12px 25px rgba(108, 99, 255, 0.4);
            background: linear-gradient(135deg, #5a52e0 0%, #2dc5d0 100%);
        }
        
        .btn-primary:active {
            transform: translateY(-1px);
            box-shadow: 0 4px 15px rgba(108, 99, 255, 0.3);
        }
        
        .btn-outline {
            background: transparent;
            color: var(--primary);
            border: 2px solid var(--primary);
            width: 100%;
        }
        
        .btn-outline:hover {
            background: var(--primary);
            color: white;
            transform: translateY(-3px);
            box-shadow: 0 8px 20px rgba(108, 99, 255, 0.2);
        }
        
        .demo-credentials {
            background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
            padding: 25px;
            border-radius: 12px;
            margin-top: 35px;
            border: 2px dashed #cbd5e1;
            transition: var(--transition);
        }
        
        .demo-credentials:hover {
            border-color: var(--primary);
            transform: translateY(-3px);
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.05);
        }
        
        .demo-credentials h4 {
            color: var(--dark);
            margin-bottom: 15px;
            font-size: 1.1rem;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .demo-section {
            display: flex;
            gap: 20px;
            margin-top: 20px;
        }
        
        .demo-user-type {
            flex: 1;
            padding: 20px;
            background: white;
            border-radius: 10px;
            text-align: center;
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.03);
            transition: var(--transition);
            border: 1px solid #e2e8f0;
        }
        
        .demo-user-type:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.08);
            border-color: var(--primary);
        }
        
        .demo-user-type h5 {
            color: var(--dark);
            margin-bottom: 12px;
            font-size: 1rem;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }
        
        .demo-user-type p {
            color: var(--gray);
            font-size: 0.9rem;
            margin: 8px 0;
            text-align: left;
            display: flex;
            justify-content: space-between;
        }
        
        .demo-user-type p strong {
            color: var(--dark);
        }
        
        .footer-links {
            text-align: center;
            margin-top: 35px;
            padding-top: 25px;
            border-top: 1px solid #e1e5f1;
        }
        
        .footer-links p {
            color: var(--gray);
            margin-bottom: 20px;
            font-size: 1rem;
        }
        
        .login-footer {
            display: flex;
            justify-content: center;
            gap: 20px;
            margin-top: 25px;
        }
        
        .footer-icon {
            width: 45px;
            height: 45px;
            border-radius: 50%;
            background: #f1f5f9;
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--dark);
            font-size: 1.2rem;
            transition: var(--transition);
            text-decoration: none;
        }
        
        .footer-icon:hover {
            background: var(--primary);
            color: white;
            transform: translateY(-5px) rotate(10deg);
        }
        
        .pulse {
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0% { box-shadow: 0 0 0 0 rgba(108, 99, 255, 0.4); }
            70% { box-shadow: 0 0 0 10px rgba(108, 99, 255, 0); }
            100% { box-shadow: 0 0 0 0 rgba(108, 99, 255, 0); }
        }
        
        .shake {
            animation: shake 0.5s;
        }
        
        @keyframes shake {
            0%, 100% { transform: translateX(0); }
            10%, 30%, 50%, 70%, 90% { transform: translateX(-5px); }
            20%, 40%, 60%, 80% { transform: translateX(5px); }
        }
        
        @media (max-width: 576px) {
            .login-container {
                max-width: 100%;
            }
            
            .login-body {
                padding: 30px 25px;
            }
            
            .demo-section {
                flex-direction: column;
            }
            
            .login-header h1 {
                font-size: 2.3rem;
            }
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="login-box">
            <div class="login-header">
                <h1><i class="fas fa-book-open"></i> ReadVerse</h1>
                <p>Sign in to your account</p>
            </div>
            
            <div class="login-body">
                <% if(request.getAttribute("error") != null) { %>
                <div class="alert alert-danger">
                    <i class="fas fa-exclamation-circle"></i> 
                    <div><strong>Login Failed:</strong> <%= request.getAttribute("error") %></div>
                </div>
                <% } %>
                
                <div class="alert alert-info">
                    <i class="fas fa-info-circle"></i> 
                    <div><strong>Demo Mode:</strong> Use any credentials or the demo accounts below</div>
                </div>
                
                <form method="POST" action="login.jsp" id="loginForm">
                    <input type="hidden" name="redirect" value="<%= request.getParameter("redirect") != null ? request.getParameter("redirect") : "" %>">
                    
                    <div class="user-type-selector">
                        <div class="user-type-option active" id="userOption">
                            <input type="radio" id="user_type_user" name="user_type" value="user" checked>
                            <label for="user_type_user">
                                <i class="fas fa-user"></i> User Login
                            </label>
                        </div>
                        <div class="user-type-option" id="adminOption">
                            <input type="radio" id="user_type_admin" name="user_type" value="admin">
                            <label for="user_type_admin">
                                <i class="fas fa-user-shield"></i> Admin Login
                            </label>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label for="username"><i class="fas fa-user-circle"></i> Username</label>
                        <input type="text" id="username" name="username" class="form-control" required 
                               placeholder="Enter your username" autocomplete="username">
                        <i class="fas fa-user form-icon"></i>
                    </div>
                    
                    <div class="form-group">
                        <label for="password"><i class="fas fa-lock"></i> Password</label>
                        <input type="password" id="password" name="password" class="form-control" required 
                               placeholder="Enter your password" autocomplete="current-password">
                        <button type="button" class="password-toggle" id="togglePassword">
                            <i class="fas fa-eye"></i>
                        </button>
                    </div>
                    
                    <button type="submit" class="btn btn-primary pulse" id="loginButton">
                        <i class="fas fa-sign-in-alt"></i> Sign In
                        <span class="btn-loader" id="btnLoader" style="display: none;">
                            <i class="fas fa-spinner fa-spin"></i>
                        </span>
                    </button>
                </form>
                
                <div class="demo-credentials">
                    <h4><i class="fas fa-vial"></i> Quick Test Accounts</h4>
                    <div class="demo-section">
                        <div class="demo-user-type">
                            <h5><i class="fas fa-user-tie"></i> User Account</h5>
                            <p><strong>Username:</strong> demo_user</p>
                            <p><strong>Password:</strong> any password</p>
                            <button class="btn-test-account" data-username="demo_user" data-type="user" style="margin-top: 10px; background: #e3f2fd; color: #1565c0; border: none; padding: 8px 15px; border-radius: 8px; cursor: pointer; font-size: 0.9rem; transition: all 0.3s;">
                                <i class="fas fa-mouse-pointer"></i> Auto-fill
                            </button>
                        </div>
                        <div class="demo-user-type">
                            <h5><i class="fas fa-user-cog"></i> Admin Account</h5>
                            <p><strong>Username:</strong> admin</p>
                            <p><strong>Password:</strong> any password</p>
                            <button class="btn-test-account" data-username="admin" data-type="admin" style="margin-top: 10px; background: #e3f2fd; color: #1565c0; border: none; padding: 8px 15px; border-radius: 8px; cursor: pointer; font-size: 0.9rem; transition: all 0.3s;">
                                <i class="fas fa-mouse-pointer"></i> Auto-fill
                            </button>
                        </div>
                    </div>
                </div>
                
                <div class="footer-links">
                    <p>Don't have an account? Join our community today!</p>
                    <a href="register.jsp" class="btn btn-outline">
                        <i class="fas fa-user-plus"></i> Create New Account
                    </a>
                    
                    <div class="login-footer">
                        <a href="index.jsp" class="footer-icon" title="Home">
                            <i class="fas fa-home"></i>
                        </a>
                        <a href="#" class="footer-icon" title="Help">
                            <i class="fas fa-question-circle"></i>
                        </a>
                        <a href="#" class="footer-icon" title="Contact">
                            <i class="fas fa-envelope"></i>
                        </a>
                        <a href="#" class="footer-icon" title="About">
                            <i class="fas fa-info-circle"></i>
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // User type selector
            const userOption = document.getElementById('userOption');
            const adminOption = document.getElementById('adminOption');
            const userRadio = document.getElementById('user_type_user');
            const adminRadio = document.getElementById('user_type_admin');
            
            userOption.addEventListener('click', function() {
                userRadio.checked = true;
                userOption.classList.add('active');
                adminOption.classList.remove('active');
                animateUserTypeChange('user');
            });
            
            adminOption.addEventListener('click', function() {
                adminRadio.checked = true;
                adminOption.classList.add('active');
                userOption.classList.remove('active');
                animateUserTypeChange('admin');
            });
            
            function animateUserTypeChange(type) {
                const selector = document.querySelector('.user-type-selector');
                selector.style.transform = 'scale(0.98)';
                setTimeout(() => {
                    selector.style.transform = 'scale(1)';
                }, 200);
                
                // Update demo account highlight
                document.querySelectorAll('.demo-user-type').forEach(el => {
                    el.style.borderColor = '#e2e8f0';
                });
                document.querySelector(`.btn-test-account[data-type="${type}"]`).closest('.demo-user-type').style.borderColor = '#6c63ff';
            }
            
            // Password visibility toggle
            const togglePassword = document.getElementById('togglePassword');
            const passwordInput = document.getElementById('password');
            
            togglePassword.addEventListener('click', function() {
                const type = passwordInput.getAttribute('type') === 'password' ? 'text' : 'password';
                passwordInput.setAttribute('type', type);
                this.innerHTML = type === 'password' ? '<i class="fas fa-eye"></i>' : '<i class="fas fa-eye-slash"></i>';
                
                // Animation
                this.style.transform = 'scale(1.3)';
                setTimeout(() => {
                    this.style.transform = 'scale(1)';
                }, 200);
            });
            
            // Demo account auto-fill buttons
            document.querySelectorAll('.btn-test-account').forEach(button => {
                button.addEventListener('click', function() {
                    const username = this.getAttribute('data-username');
                    const type = this.getAttribute('data-type');
                    
                    // Fill the form
                    document.getElementById('username').value = username;
                    document.getElementById('password').value = 'demo123';
                    
                    // Select the right user type
                    if (type === 'admin') {
                        adminRadio.checked = true;
                        adminOption.classList.add('active');
                        userOption.classList.remove('active');
                    } else {
                        userRadio.checked = true;
                        userOption.classList.add('active');
                        adminOption.classList.remove('active');
                    }
                    
                    // Animate the button
                    this.innerHTML = '<i class="fas fa-check"></i> Filled!';
                    this.style.background = '#28a745';
                    this.style.color = 'white';
                    
                    setTimeout(() => {
                        this.innerHTML = '<i class="fas fa-mouse-pointer"></i> Auto-fill';
                        this.style.background = '#e3f2fd';
                        this.style.color = '#1565c0';
                    }, 1500);
                    
                    // Focus on password field
                    passwordInput.focus();
                    
                    // Highlight the demo card
                    const demoCard = this.closest('.demo-user-type');
                    demoCard.style.transform = 'scale(1.05)';
                    demoCard.style.boxShadow = '0 15px 30px rgba(108, 99, 255, 0.2)';
                    
                    setTimeout(() => {
                        demoCard.style.transform = '';
                        demoCard.style.boxShadow = '';
                    }, 1000);
                });
            });
            
            // Form submission animation
            const loginForm = document.getElementById('loginForm');
            const loginButton = document.getElementById('loginButton');
            const btnLoader = document.getElementById('btnLoader');
            
            loginForm.addEventListener('submit', function(e) {
                // Show loading animation
                loginButton.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Signing In...';
                loginButton.classList.add('pulse');
                loginButton.style.cursor = 'wait';
                
                // Add a small delay to show the animation
                setTimeout(() => {
                    loginButton.innerHTML = '<i class="fas fa-sign-in-alt"></i> Sign In';
                    loginButton.classList.remove('pulse');
                    loginButton.style.cursor = 'pointer';
                }, 2000);
            });
            
            // Input field animations
            const inputs = document.querySelectorAll('.form-control');
            inputs.forEach(input => {
                // Add focus animation
                input.addEventListener('focus', function() {
                    this.parentElement.style.transform = 'translateY(-3px)';
                });
                
                input.addEventListener('blur', function() {
                    this.parentElement.style.transform = '';
                });
                
                // Add validation styling
                input.addEventListener('input', function() {
                    if (this.value.length > 0) {
                        this.style.borderColor = '#36d1dc';
                    } else {
                        this.style.borderColor = '#e1e5f1';
                    }
                });
            });
            
            // Add hover effect to login box
            const loginBox = document.querySelector('.login-box');
            loginBox.addEventListener('mouseenter', function() {
                this.style.transform = 'translateY(-8px)';
            });
            
            loginBox.addEventListener('mouseleave', function() {
                this.style.transform = 'translateY(0)';
            });
            
            // Random color pulse effect on header icons
            const headerIcon = document.querySelector('.login-header i');
            setInterval(() => {
                headerIcon.style.color = getRandomColor();
            }, 3000);
            
            function getRandomColor() {
                const colors = ['#ff6b6b', '#4ecdc4', '#ffd166', '#06d6a0', '#118ab2', '#ef476f'];
                return colors[Math.floor(Math.random() * colors.length)];
            }
            
            // Initialize with user type
            animateUserTypeChange('user');
        });
    </script>
</body>
</html>

