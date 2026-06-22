<%@ page contentType="text/html;charset=ISO-8859-1" language="java" %>
<%@ page import="java.sql.*" %>
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
    
    String error = request.getParameter("error");
    String paymentId = request.getParameter("payment_id");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <%@ include file="head_include.jsp" %>
    <meta charset="ISO-8859-1">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Failed - ReadVerse</title>
    <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
    <style>
        .error-container {
            max-width: 600px;
            margin: 100px auto;
            text-align: center;
            padding: 40px;
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        
        .error-icon {
            font-size: 80px;
            color: #dc3545;
            margin-bottom: 20px;
        }
        
        .error-container h1 {
            color: #dc3545;
            margin-bottom: 20px;
        }
        
        .error-details {
            background: #f8d7da;
            color: #721c24;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
            text-align: left;
        }
        
        .action-buttons {
            display: flex;
            gap: 15px;
            justify-content: center;
            margin-top: 30px;
            flex-wrap: wrap;
        }
        
        .btn {
            padding: 12px 24px;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            border: none;
            text-decoration: none;
            font-size: 1rem;
        }
        
        .btn-primary {
            background: #6c63ff;
            color: white;
        }
        
        .btn-primary:hover {
            background: #5952d4;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(108, 99, 255, 0.3);
        }
        
        .btn-danger {
            background: #dc3545;
            color: white;
        }
        
        .btn-danger:hover {
            background: #c82333;
            transform: translateY(-2px);
        }
        
        .payment-info {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
            font-family: monospace;
            word-break: break-all;
        }
    </style>
</head>
<body>
    <%@ include file="header.jsp" %>
    
    <div class="container">
        <div class="error-container">
            <div class="error-icon">
                <i class="fas fa-exclamation-circle"></i>
            </div>
            
            <h1>Payment Failed</h1>
            
            <p style="color: #666; margin-bottom: 20px; font-size: 1.1rem;">
                We're sorry, but your payment could not be processed. Please try again.
            </p>
            
            <% if(error != null && !error.isEmpty()) { %>
            <div class="error-details">
                <strong>Error Details:</strong>
                <p><%= error %></p>
            </div>
            <% } %>
            
            <% if(paymentId != null && !paymentId.isEmpty()) { %>
            <div class="payment-info">
                <strong>Payment ID:</strong> <%= paymentId %>
            </div>
            <% } %>
            
            <div class="action-buttons">
                <a href="checkout.jsp" class="btn btn-primary">
                    <i class="fas fa-redo"></i> Try Again
                </a>
                
                <a href="cart.jsp" class="btn">
                    <i class="fas fa-shopping-cart"></i> Back to Cart
                </a>
                
                <a href="contact.jsp" class="btn btn-danger">
                    <i class="fas fa-headset"></i> Contact Support
                </a>
            </div>
            
            <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #dee2e6;">
                <p style="color: #6c757d; font-size: 0.9rem;">
                    <i class="fas fa-info-circle"></i> If the problem persists, please contact our support team.
                </p>
            </div>
        </div>
    </div>
    
    <%@ include file="footer.jsp" %>
    
    <script>
        // Auto-redirect to checkout after 10 seconds
        setTimeout(function() {
            window.location.href = 'checkout.jsp';
        }, 10000);
        
        // Show notification if there's an error in session
        document.addEventListener('DOMContentLoaded', function() {
            <% 
            String sessionError = (String) session.getAttribute("error");
            if(sessionError != null) { 
            %>
                alert('<%= sessionError %>');
                <% session.removeAttribute("error"); %>
            <% } %>
        });
    </script>
</body>
</html>