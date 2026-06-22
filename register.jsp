<%@ page contentType="text/html; charset=ISO-8859-1" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.security.MessageDigest" %>
<%
    // Database configuration
    String dbURL = "jdbc:mysql://localhost:3306/readverse_db5?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
    String dbUser = "root";
    String dbPassword = "Root@1234";
    
    // Handle registration form submission
    if("POST".equals(request.getMethod())) {
        String username = request.getParameter("username");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirm_password");
        String fullName = request.getParameter("full_name");
        String phone = request.getParameter("phone");
        String address = request.getParameter("address");
        String terms = request.getParameter("terms");
        
        // Validation
        boolean hasError = false;
        StringBuilder errorMessage = new StringBuilder();
        
        if(username == null || username.trim().isEmpty()) {
            hasError = true;
            errorMessage.append("Username is required. ");
        } else if(username.length() < 3 || username.length() > 20) {
            hasError = true;
            errorMessage.append("Username must be 3-20 characters. ");
        }
        
        if(email == null || email.trim().isEmpty()) {
            hasError = true;
            errorMessage.append("Email is required. ");
        } else if(!email.matches("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$")) {
            hasError = true;
            errorMessage.append("Invalid email format. ");
        }
        
        if(password == null || password.trim().isEmpty()) {
            hasError = true;
            errorMessage.append("Password is required. ");
        } else if(password.length() < 6) {
            hasError = true;
            errorMessage.append("Password must be at least 6 characters. ");
        }
        
        if(!password.equals(confirmPassword)) {
            hasError = true;
            errorMessage.append("Passwords do not match. ");
        }
        
        if(fullName == null || fullName.trim().isEmpty()) {
            hasError = true;
            errorMessage.append("Full name is required. ");
        }
        
        if(terms == null) {
            hasError = true;
            errorMessage.append("You must accept the terms and conditions. ");
        }
        
        if(!hasError) {
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            
            try {
                // Load MySQL driver
                Class.forName("com.mysql.cj.jdbc.Driver");
                
                // Create connection with public key retrieval enabled
                conn = DriverManager.getConnection(dbURL, dbUser, dbPassword);
                
                // Check if username already exists
                String checkUserSql = "SELECT user_id FROM users WHERE username = ? OR email = ?";
                pstmt = conn.prepareStatement(checkUserSql);
                pstmt.setString(1, username);
                pstmt.setString(2, email);
                rs = pstmt.executeQuery();
                
                if(rs.next()) {
                    hasError = true;
                    errorMessage.append("Username or email already exists. ");
                } else {
                    // Close previous result set and statement
                    if(rs != null) rs.close();
                    if(pstmt != null) pstmt.close();
                    
                    // Hash the password for security
                    String hashedPassword = "";
                    try {
                        MessageDigest md = MessageDigest.getInstance("SHA-256");
                        byte[] hash = md.digest(password.getBytes("UTF-8"));
                        StringBuilder hexString = new StringBuilder();
                        for (byte b : hash) {
                            String hex = Integer.toHexString(0xff & b);
                            if (hex.length() == 1) hexString.append('0');
                            hexString.append(hex);
                        }
                        hashedPassword = hexString.toString();
                    } catch(Exception e) {
                        hashedPassword = password; // Fallback to plain text if hashing fails
                    }
                    
                    // Insert new user WITHOUT status column
                    String insertSql = "INSERT INTO users (username, email, password, full_name, phone, address, created_at) VALUES (?, ?, ?, ?, ?, ?, NOW())";
                    pstmt = conn.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS);
                    pstmt.setString(1, username);
                    pstmt.setString(2, email);
                    pstmt.setString(3, hashedPassword);
                    pstmt.setString(4, fullName);
                    pstmt.setString(5, phone);
                    pstmt.setString(6, address);
                    
                    int rowsAffected = pstmt.executeUpdate();
                    
                    if(rowsAffected > 0) {
                        // Get the generated user ID
                        rs = pstmt.getGeneratedKeys();
                        if(rs.next()) {
                            int userId = rs.getInt(1);
                            
                            // Auto-login after registration
                            session.setAttribute("user_id", String.valueOf(userId));
                            session.setAttribute("username", username);
                            session.setAttribute("email", email);
                            session.setAttribute("full_name", fullName);
                            session.setAttribute("cartCount", 0);
                            
                            // Redirect to home page
                            response.sendRedirect("index.jsp");
                            return;
                        }
                    } else {
                        hasError = true;
                        errorMessage.append("Registration failed. Please try again. ");
                    }
                }
                
            } catch(ClassNotFoundException e) {
                e.printStackTrace();
                hasError = true;
                errorMessage.append("Database driver error. Please contact administrator. ");
            } catch(SQLException e) {
                e.printStackTrace();
                hasError = true;
                if(e.getMessage().contains("Public Key Retrieval")) {
                    errorMessage.append("Database connection error. Please check database configuration. ");
                } else if(e.getMessage().contains("Unknown column")) {
                    // Handle missing column error
                    errorMessage.append("Database structure error. Please check if the users table exists with correct columns. ");
                } else {
                    errorMessage.append("Database error: ").append(e.getMessage());
                }
            } catch(Exception e) {
                e.printStackTrace();
                hasError = true;
                errorMessage.append("Error: ").append(e.getMessage());
            } finally {
                if(rs != null) try { rs.close(); } catch(Exception e) {}
                if(pstmt != null) try { pstmt.close(); } catch(Exception e) {}
                if(conn != null) try { conn.close(); } catch(Exception e) {}
            }
        }
        
        if(hasError) {
            request.setAttribute("error", errorMessage.toString());
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="ISO-8859-1">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <title>Register - ReadVerse</title>
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
        
        .register-container {
            width: 100%;
            max-width: 550px;
            animation: fadeIn 0.5s ease-out;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .register-box {
            background: white;
            border-radius: var(--border-radius);
            box-shadow: var(--shadow);
            overflow: hidden;
            transition: var(--transition);
        }
        
        .register-box:hover {
            box-shadow: var(--shadow-hover);
            transform: translateY(-5px);
        }
        
        .register-header {
            background: var(--gradient-secondary);
            padding: 50px 30px;
            text-align: center;
            color: white;
            position: relative;
            overflow: hidden;
        }
        
        .register-header::before {
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
        
        .register-header h1 {
            font-size: 2.8rem;
            margin-bottom: 15px;
            font-weight: 800;
            letter-spacing: -0.5px;
            position: relative;
            z-index: 1;
        }
        
        .register-header p {
            font-size: 1.1rem;
            opacity: 0.9;
            font-weight: 300;
            position: relative;
            z-index: 1;
        }
        
        .register-body {
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
        
        .alert-success {
            background: linear-gradient(135deg, #e8f5e9 0%, #f1f8e9 100%);
            color: #2e7d32;
            border-color: #4caf50;
        }
        
        .form-row {
            display: flex;
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .form-group {
            flex: 1;
            margin-bottom: 25px;
            position: relative;
        }
        
        .form-group.full-width {
            width: 100%;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 10px;
            color: var(--dark);
            font-weight: 600;
            font-size: 0.95rem;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .required::after {
            content: '*';
            color: var(--danger);
            margin-left: 4px;
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
        
        .form-control.error {
            border-color: var(--danger);
            background: #fff5f5;
        }
        
        .form-control.success {
            border-color: var(--success);
            background: #f8fff8;
        }
        
        .form-icon {
            position: absolute;
            right: 20px;
            top: 50px;
            color: var(--gray);
            pointer-events: none;
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
        
        .password-strength {
            height: 6px;
            margin-top: 8px;
            border-radius: 3px;
            overflow: hidden;
            background: #e1e5f1;
            position: relative;
        }
        
        .password-strength-bar {
            height: 100%;
            width: 0%;
            transition: var(--transition);
            border-radius: 3px;
        }
        
        .strength-weak {
            background: var(--danger);
        }
        
        .strength-fair {
            background: var(--warning);
        }
        
        .strength-good {
            background: #17a2b8;
        }
        
        .strength-strong {
            background: var(--success);
        }
        
        .strength-text {
            font-size: 0.85rem;
            margin-top: 5px;
            text-align: right;
            color: var(--gray);
        }
        
        .form-hint {
            font-size: 0.85rem;
            color: var(--gray);
            margin-top: 5px;
            display: flex;
            align-items: center;
            gap: 5px;
        }
        
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
        
        .terms-checkbox {
            display: flex;
            align-items: flex-start;
            gap: 12px;
            margin: 30px 0;
            padding: 20px;
            background: #f8fafc;
            border-radius: 12px;
            border: 2px solid #e1e5f1;
            transition: var(--transition);
        }
        
        .terms-checkbox:hover {
            border-color: var(--primary);
            background: #f0f4ff;
        }
        
        .terms-checkbox input[type="checkbox"] {
            margin-top: 4px;
            width: 18px;
            height: 18px;
            cursor: pointer;
            accent-color: var(--primary);
        }
        
        .terms-checkbox label {
            font-size: 0.95rem;
            color: var(--dark);
            line-height: 1.5;
            cursor: pointer;
        }
        
        .terms-checkbox a {
            color: var(--primary);
            text-decoration: none;
            font-weight: 600;
            transition: var(--transition);
        }
        
        .terms-checkbox a:hover {
            text-decoration: underline;
            color: var(--primary-dark);
        }
        
        .login-link {
            text-align: center;
            margin-top: 35px;
            padding-top: 25px;
            border-top: 1px solid #e1e5f1;
        }
        
        .login-link p {
            color: var(--gray);
            margin-bottom: 20px;
            font-size: 1rem;
        }
        
        .register-footer {
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
        
        .progress-steps {
            display: flex;
            justify-content: space-between;
            margin-bottom: 40px;
            position: relative;
        }
        
        .progress-steps::before {
            content: '';
            position: absolute;
            top: 20px;
            left: 20px;
            right: 20px;
            height: 3px;
            background: #e1e5f1;
            z-index: 1;
        }
        
        .progress-bar {
            position: absolute;
            top: 20px;
            left: 20px;
            height: 3px;
            background: var(--primary);
            z-index: 2;
            transition: width 0.5s ease;
            width: 0%;
        }
        
        .step {
            display: flex;
            flex-direction: column;
            align-items: center;
            position: relative;
            z-index: 3;
            flex: 1;
        }
        
        .step-icon {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: white;
            border: 3px solid #e1e5f1;
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--gray);
            font-weight: bold;
            margin-bottom: 10px;
            transition: var(--transition);
        }
        
        .step.active .step-icon {
            background: var(--primary);
            border-color: var(--primary);
            color: white;
            transform: scale(1.1);
            box-shadow: 0 5px 15px rgba(108, 99, 255, 0.3);
        }
        
        .step.completed .step-icon {
            background: var(--success);
            border-color: var(--success);
            color: white;
        }
        
        .step-label {
            font-size: 0.9rem;
            color: var(--gray);
            font-weight: 500;
            transition: var(--transition);
        }
        
        .step.active .step-label {
            color: var(--primary);
            font-weight: 600;
        }
        
        @media (max-width: 576px) {
            .register-container {
                max-width: 100%;
            }
            
            .register-body {
                padding: 30px 25px;
            }
            
            .form-row {
                flex-direction: column;
                gap: 0;
            }
            
            .register-header h1 {
                font-size: 2.3rem;
            }
            
            .progress-steps {
                margin-bottom: 30px;
            }
            
            .step-label {
                font-size: 0.8rem;
            }
        }
    </style>
</head>
<body>
    <div class="register-container">
        <div class="register-box">
            <div class="register-header">
                <h1><i class="fas fa-user-plus"></i> ReadVerse</h1>
                <p>Join our reading community today</p>
            </div>
            
            <div class="register-body">
                <% if(request.getAttribute("error") != null) { %>
                <div class="alert alert-danger">
                    <i class="fas fa-exclamation-circle"></i> 
                    <div><strong>Registration Error:</strong> <%= request.getAttribute("error") %></div>
                </div>
                <% } %>
                
                <div class="alert alert-info">
                    <i class="fas fa-info-circle"></i> 
                    <div><strong>Welcome!</strong> Fill in your details to create an account. All fields marked with * are required.</div>
                </div>
                
                <!-- Progress Steps -->
                <div class="progress-steps">
                    <div class="progress-bar" id="progressBar"></div>
                    <div class="step active" id="step1">
                        <div class="step-icon">1</div>
                        <div class="step-label">Account</div>
                    </div>
                    <div class="step" id="step2">
                        <div class="step-icon">2</div>
                        <div class="step-label">Personal</div>
                    </div>
                    <div class="step" id="step3">
                        <div class="step-icon">3</div>
                        <div class="step-label">Complete</div>
                    </div>
                </div>
                
                <form method="POST" action="register.jsp" id="registerForm">
                    <input type="hidden" name="terms" id="termsHidden" value="">
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label for="username" class="required">
                                <i class="fas fa-user-circle"></i> Username
                            </label>
                            <input type="text" id="username" name="username" class="form-control" required 
                                   placeholder="Choose a username" autocomplete="username"
                                   value="<%= request.getParameter("username") != null ? request.getParameter("username") : "" %>">
                            <i class="fas fa-user form-icon"></i>
                            <div class="form-hint">
                                <i class="fas fa-lightbulb"></i> 3-20 characters, letters and numbers only
                            </div>
                        </div>
                        
                        <div class="form-group">
                            <label for="email" class="required">
                                <i class="fas fa-envelope"></i> Email
                            </label>
                            <input type="email" id="email" name="email" class="form-control" required 
                                   placeholder="Enter your email" autocomplete="email"
                                   value="<%= request.getParameter("email") != null ? request.getParameter("email") : "" %>">
                            <i class="fas fa-at form-icon"></i>
                        </div>
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label for="password" class="required">
                                <i class="fas fa-lock"></i> Password
                            </label>
                            <input type="password" id="password" name="password" class="form-control" required 
                                   placeholder="Create a password" autocomplete="new-password">
                            <button type="button" class="password-toggle" id="togglePassword">
                                <i class="fas fa-eye"></i>
                            </button>
                            <div class="password-strength">
                                <div class="password-strength-bar" id="passwordStrengthBar"></div>
                            </div>
                            <div class="strength-text" id="strengthText">Password strength</div>
                            <div class="form-hint">
                                <i class="fas fa-lightbulb"></i> Minimum 6 characters
                            </div>
                        </div>
                        
                        <div class="form-group">
                            <label for="confirm_password" class="required">
                                <i class="fas fa-lock"></i> Confirm Password
                            </label>
                            <input type="password" id="confirm_password" name="confirm_password" class="form-control" required 
                                   placeholder="Confirm your password" autocomplete="new-password">
                            <button type="button" class="password-toggle" id="toggleConfirmPassword">
                                <i class="fas fa-eye"></i>
                            </button>
                            <div class="form-hint" id="passwordMatchHint">
                                <i class="fas fa-check-circle"></i> Passwords must match
                            </div>
                        </div>
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label for="full_name" class="required">
                                <i class="fas fa-user"></i> Full Name
                            </label>
                            <input type="text" id="full_name" name="full_name" class="form-control" required 
                                   placeholder="Enter your full name" autocomplete="name"
                                   value="<%= request.getParameter("full_name") != null ? request.getParameter("full_name") : "" %>">
                            <i class="fas fa-signature form-icon"></i>
                        </div>
                        
                        <div class="form-group">
                            <label for="phone">
                                <i class="fas fa-phone"></i> Phone Number
                            </label>
                            <input type="tel" id="phone" name="phone" class="form-control" 
                                   placeholder="Enter your phone number" autocomplete="tel"
                                   value="<%= request.getParameter("phone") != null ? request.getParameter("phone") : "" %>">
                            <i class="fas fa-mobile-alt form-icon"></i>
                        </div>
                    </div>
                    
                    <div class="form-group full-width">
                        <label for="address">
                            <i class="fas fa-map-marker-alt"></i> Address
                        </label>
                        <textarea id="address" name="address" class="form-control" rows="3" 
                                  placeholder="Enter your address (optional)"><%= request.getParameter("address") != null ? request.getParameter("address") : "" %></textarea>
                        <i class="fas fa-home form-icon" style="top: 40px;"></i>
                    </div>
                    
                    <div class="terms-checkbox">
                        <input type="checkbox" id="terms" name="termsCheckbox" required>
                        <label for="terms">
                            I agree to the <a href="terms.jsp" target="_blank">Terms of Service</a> and <a href="privacy.jsp" target="_blank">Privacy Policy</a>. 
                            I understand that ReadVerse will process my information in accordance with these policies.
                        </label>
                    </div>
                    
                    <button type="submit" class="btn btn-primary pulse" id="registerButton">
                        <i class="fas fa-user-plus"></i> Create Account
                        <span class="btn-loader" id="btnLoader" style="display: none;">
                            <i class="fas fa-spinner fa-spin"></i>
                        </span>
                    </button>
                </form>
                
                <div class="login-link">
                    <p>Already have an account? Welcome back!</p>
                    <a href="login.jsp" class="btn btn-outline">
                        <i class="fas fa-sign-in-alt"></i> Sign In to Your Account
                    </a>
                    
                    <div class="register-footer">
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
            // Password visibility toggle
            const togglePassword = document.getElementById('togglePassword');
            const toggleConfirmPassword = document.getElementById('toggleConfirmPassword');
            const passwordInput = document.getElementById('password');
            const confirmPasswordInput = document.getElementById('confirm_password');
            const termsCheckbox = document.getElementById('terms');
            const termsHidden = document.getElementById('termsHidden');
            
            // Update hidden terms field when checkbox changes
            termsCheckbox.addEventListener('change', function() {
                termsHidden.value = this.checked ? 'accepted' : '';
            });
            
            togglePassword.addEventListener('click', function() {
                const type = passwordInput.getAttribute('type') === 'password' ? 'text' : 'password';
                passwordInput.setAttribute('type', type);
                this.innerHTML = type === 'password' ? '<i class="fas fa-eye"></i>' : '<i class="fas fa-eye-slash"></i>';
                this.style.transform = 'scale(1.3)';
                setTimeout(() => this.style.transform = 'scale(1)', 200);
            });
            
            toggleConfirmPassword.addEventListener('click', function() {
                const type = confirmPasswordInput.getAttribute('type') === 'password' ? 'text' : 'password';
                confirmPasswordInput.setAttribute('type', type);
                this.innerHTML = type === 'password' ? '<i class="fas fa-eye"></i>' : '<i class="fas fa-eye-slash"></i>';
                this.style.transform = 'scale(1.3)';
                setTimeout(() => this.style.transform = 'scale(1)', 200);
            });
            
            // Password strength meter
            passwordInput.addEventListener('input', function() {
                const password = this.value;
                const strengthBar = document.getElementById('passwordStrengthBar');
                const strengthText = document.getElementById('strengthText');
                
                // Calculate strength
                let strength = 0;
                let text = 'Weak';
                let colorClass = 'strength-weak';
                
                if (password.length >= 6) strength += 25;
                if (password.length >= 8) strength += 15;
                if (/[A-Z]/.test(password)) strength += 20;
                if (/[0-9]/.test(password)) strength += 20;
                if (/[^A-Za-z0-9]/.test(password)) strength += 20;
                
                // Cap at 100
                strength = Math.min(strength, 100);
                
                // Set strength level
                if (strength >= 80) {
                    text = 'Strong';
                    colorClass = 'strength-strong';
                } else if (strength >= 60) {
                    text = 'Good';
                    colorClass = 'strength-good';
                } else if (strength >= 40) {
                    text = 'Fair';
                    colorClass = 'strength-fair';
                } else {
                    text = 'Weak';
                    colorClass = 'strength-weak';
                }
                
                // Update UI
                strengthBar.style.width = strength + '%';
                strengthBar.className = 'password-strength-bar ' + colorClass;
                strengthText.textContent = text + ' (' + strength + '%)';
                strengthText.style.color = getComputedStyle(document.documentElement).getPropertyValue('--' + colorClass.split('-')[1]);
            });
            
            // Password confirmation check
            confirmPasswordInput.addEventListener('input', function() {
                const password = passwordInput.value;
                const confirm = this.value;
                const hint = document.getElementById('passwordMatchHint');
                
                if (confirm.length === 0) {
                    hint.innerHTML = '<i class="fas fa-check-circle"></i> Passwords must match';
                    hint.style.color = '';
                    this.classList.remove('error', 'success');
                } else if (password === confirm) {
                    hint.innerHTML = '<i class="fas fa-check-circle"></i> Passwords match!';
                    hint.style.color = 'var(--success)';
                    this.classList.remove('error');
                    this.classList.add('success');
                } else {
                    hint.innerHTML = '<i class="fas fa-times-circle"></i> Passwords do not match';
                    hint.style.color = 'var(--danger)';
                    this.classList.remove('success');
                    this.classList.add('error');
                }
            });
            
            // Form submission with validation
            const registerForm = document.getElementById('registerForm');
            const registerButton = document.getElementById('registerButton');
            
            registerForm.addEventListener('submit', function(e) {
                let isValid = true;
                
                // Check required fields
                const requiredFields = registerForm.querySelectorAll('[required]');
                requiredFields.forEach(field => {
                    if (!field.value.trim()) {
                        isValid = false;
                        field.classList.add('error');
                        field.style.animation = 'shake 0.5s';
                        setTimeout(() => field.style.animation = '', 500);
                    } else {
                        field.classList.remove('error');
                    }
                });
                
                // Check password match
                if (passwordInput.value !== confirmPasswordInput.value) {
                    isValid = false;
                    confirmPasswordInput.classList.add('error');
                    confirmPasswordInput.style.animation = 'shake 0.5s';
                    setTimeout(() => confirmPasswordInput.style.animation = '', 500);
                    
                    // Show error message
                    const hint = document.getElementById('passwordMatchHint');
                    hint.innerHTML = '<i class="fas fa-times-circle"></i> Passwords do not match!';
                    hint.style.color = 'var(--danger)';
                    hint.style.animation = 'shake 0.5s';
                    setTimeout(() => hint.style.animation = '', 500);
                }
                
                // Check terms agreement
                if (!termsCheckbox.checked) {
                    isValid = false;
                    termsCheckbox.parentElement.style.borderColor = 'var(--danger)';
                    termsCheckbox.parentElement.style.background = '#ffebee';
                    termsCheckbox.parentElement.style.animation = 'shake 0.5s';
                    setTimeout(() => termsCheckbox.parentElement.style.animation = '', 500);
                } else {
                    termsCheckbox.parentElement.style.borderColor = '';
                    termsCheckbox.parentElement.style.background = '';
                }
                
                if (!isValid) {
                    e.preventDefault();
                    
                    // Show error message
                    if (!document.querySelector('.alert-danger')) {
                        const alert = document.createElement('div');
                        alert.className = 'alert alert-danger';
                        alert.innerHTML = '<i class="fas fa-exclamation-circle"></i> <div><strong>Validation Error:</strong> Please fill all required fields correctly.</div>';
                        alert.style.animation = 'slideIn 0.4s ease-out';
                        
                        const firstAlert = document.querySelector('.alert');
                        if (firstAlert) {
                            firstAlert.parentNode.insertBefore(alert, firstAlert.nextSibling);
                        }
                        
                        setTimeout(() => {
                            alert.style.opacity = '0';
                            setTimeout(() => alert.remove(), 300);
                        }, 5000);
                    }
                    
                    return;
                }
                
                // Show loading animation
                registerButton.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Creating Account...';
                registerButton.style.cursor = 'wait';
                registerButton.disabled = true;
                
                // Update progress steps
                document.getElementById('step1').classList.add('completed');
                document.getElementById('step2').classList.add('completed');
                document.getElementById('step3').classList.add('active');
                document.getElementById('progressBar').style.width = '100%';
            });
            
            // Real-time validation on blur
            const inputs = registerForm.querySelectorAll('input, textarea');
            inputs.forEach(input => {
                input.addEventListener('blur', function() {
                    if (this.hasAttribute('required') && !this.value.trim()) {
                        this.classList.add('error');
                    } else {
                        this.classList.remove('error');
                        if (this.type === 'email' && this.value) {
                            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                            if (!emailRegex.test(this.value)) {
                                this.classList.add('error');
                            }
                        }
                    }
                    
                    // Update progress steps based on filled sections
                    updateProgressSteps();
                });
            });
            
            // Update progress steps
            function updateProgressSteps() {
                const step1Fields = ['username', 'email', 'password', 'confirm_password'];
                const step2Fields = ['full_name', 'phone', 'address'];
                
                let step1Filled = true;
                step1Fields.forEach(field => {
                    const element = document.getElementById(field);
                    if (element && element.hasAttribute('required') && !element.value.trim()) {
                        step1Filled = false;
                    }
                });
                
                let step2Filled = true;
                step2Fields.forEach(field => {
                    const element = document.getElementById(field);
                    if (element && element.hasAttribute('required') && !element.value.trim()) {
                        step2Filled = false;
                    }
                });
                
                // Update step 2
                if (step1Filled) {
                    document.getElementById('step1').classList.add('completed');
                    document.getElementById('step2').classList.add('active');
                    document.getElementById('progressBar').style.width = '50%';
                } else {
                    document.getElementById('step1').classList.remove('completed');
                    document.getElementById('step2').classList.remove('active');
                    document.getElementById('progressBar').style.width = '0%';
                }
                
                // Step 3 will be activated on form submission
            }
            
            // Terms checkbox styling
            termsCheckbox.addEventListener('change', function() {
                if (this.checked) {
                    this.parentElement.style.borderColor = 'var(--success)';
                    this.parentElement.style.background = '#e8f5e9';
                } else {
                    this.parentElement.style.borderColor = '';
                    this.parentElement.style.background = '';
                }
            });
            
            // Input field animations
            inputs.forEach(input => {
                input.addEventListener('focus', function() {
                    this.parentElement.style.transform = 'translateY(-3px)';
                });
                
                input.addEventListener('blur', function() {
                    this.parentElement.style.transform = '';
                });
            });
            
            // Add hover effect to register box
            const registerBox = document.querySelector('.register-box');
            registerBox.addEventListener('mouseenter', function() {
                this.style.transform = 'translateY(-8px)';
            });
            
            registerBox.addEventListener('mouseleave', function() {
                this.style.transform = 'translateY(0)';
            });
            
            // Auto-format phone number
            const phoneInput = document.getElementById('phone');
            phoneInput.addEventListener('input', function(e) {
                let value = e.target.value.replace(/\D/g, '');
                if (value.length > 0) {
                    value = value.match(new RegExp('.{1,3}', 'g')).join('-');
                }
                e.target.value = value;
            });
            
            // Initialize progress steps
            updateProgressSteps();
            
            // Demo auto-fill for testing
            const demoFillBtn = document.createElement('button');
            demoFillBtn.innerHTML = '<i class="fas fa-magic"></i> Demo Fill';
            demoFillBtn.style.position = 'fixed';
            demoFillBtn.style.bottom = '20px';
            demoFillBtn.style.right = '20px';
            demoFillBtn.style.zIndex = '1000';
            demoFillBtn.style.padding = '10px 15px';
            demoFillBtn.style.background = 'var(--primary)';
            demoFillBtn.style.color = 'white';
            demoFillBtn.style.border = 'none';
            demoFillBtn.style.borderRadius = '8px';
            demoFillBtn.style.cursor = 'pointer';
            demoFillBtn.style.boxShadow = '0 4px 15px rgba(108, 99, 255, 0.3)';
            
            demoFillBtn.addEventListener('click', function() {
                document.getElementById('username').value = 'testuser_' + Math.floor(Math.random() * 1000);
                document.getElementById('email').value = 'test' + Math.floor(Math.random() * 1000) + '@example.com';
                document.getElementById('password').value = 'Test123!';
                document.getElementById('confirm_password').value = 'Test123!';
                document.getElementById('full_name').value = 'Test User';
                document.getElementById('phone').value = '123-456-7890';
                document.getElementById('address').value = '123 Test Street, Test City';
                document.getElementById('terms').checked = true;
                document.getElementById('termsHidden').value = 'accepted';
                
                // Trigger events to update UI
                passwordInput.dispatchEvent(new Event('input'));
                confirmPasswordInput.dispatchEvent(new Event('input'));
                termsCheckbox.dispatchEvent(new Event('change'));
                updateProgressSteps();
                
                // Show success message
                const alert = document.createElement('div');
                alert.className = 'alert alert-success';
                alert.innerHTML = '<i class="fas fa-check-circle"></i> <div><strong>Demo Data Loaded!</strong> You can now submit the form or modify the data.</div>';
                alert.style.animation = 'slideIn 0.4s ease-out';
                alert.style.position = 'fixed';
                alert.style.top = '20px';
                alert.style.left = '50%';
                alert.style.transform = 'translateX(-50%)';
                alert.style.width = '90%';
                alert.style.maxWidth = '500px';
                alert.style.zIndex = '1000';
                
                document.body.appendChild(alert);
                
                setTimeout(() => {
                    alert.style.opacity = '0';
                    setTimeout(() => alert.remove(), 300);
                }, 3000);
            });
            
            document.body.appendChild(demoFillBtn);
        });
    </script>
</body>
</html>