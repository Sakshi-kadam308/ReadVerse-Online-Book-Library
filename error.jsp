<%@ page contentType="text/html; charset=ISO-8859-1" %>
<%
    String errorMessage = request.getParameter("message");
    if(errorMessage == null || errorMessage.isEmpty()) {
        errorMessage = "An unexpected error occurred. Please try again.";
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <%@ include file="head_include.jsp" %>
    <title>Error - ReadVerse</title>
    <style>
        .error-page {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, rgba(108, 99, 255, 0.05) 0%, rgba(54, 209, 220, 0.05) 100%);
            padding: 20px;
        }
        
        .error-content {
            text-align: center;
            max-width: 600px;
            padding: 40px;
            background: white;
            border-radius: var(--border-radius);
            box-shadow: var(--shadow);
        }
        
        .error-icon {
            width: 120px;
            height: 120px;
            background: #FF6584;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 30px;
        }
        
        .error-icon i {
            font-size: 4rem;
            color: white;
        }
        
        .error-details {
            background: var(--light);
            padding: 20px;
            border-radius: 10px;
            margin: 30px 0;
            color: var(--dark);
        }
        
        .error-actions {
            display: flex;
            gap: 15px;
            justify-content: center;
            margin-top: 30px;
        }
        
        @media (max-width: 768px) {
            .error-actions {
                flex-direction: column;
            }
            
            .error-content {
                padding: 30px 20px;
            }
        }
    </style>
</head>
<body>
    <div class="error-page">
        <div class="error-content">
            <div class="error-icon">
                <i class="fas fa-exclamation-triangle"></i>
            </div>
            
            <h1 style="color: var(--dark); margin-bottom: 15px; font-size: 2.5rem;">Oops!</h1>
            <h2 style="color: var(--gray); margin-bottom: 20px; font-weight: 400;">Something went wrong</h2>
            
            <div class="error-details">
                <p style="margin: 0; font-size: 1.1rem;">
                    <%= errorMessage %>
                </p>
            </div>
            
            <p style="color: var(--gray); margin-bottom: 30px;">
                Please try again or contact support if the problem persists.
            </p>
            
            <div class="error-actions">
                <button class="btn btn-primary" onclick="window.history.back()">
                    <i class="fas fa-arrow-left"></i> Go Back
                </button>
                <button class="btn btn-outline" onclick="window.location.href='index.jsp'">
                    <i class="fas fa-home"></i> Home Page
                </button>
            </div>
            
            <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid var(--light);">
                <p style="color: var(--gray); font-size: 0.9rem; margin-bottom: 10px;">
                    <i class="fas fa-envelope"></i> support@readverse.com
                </p>
                <p style="color: var(--gray); font-size: 0.9rem;">
                    <i class="fas fa-phone"></i> 1-800-READ-NOW
                </p>
            </div>
        </div>
    </div>
</body>
</html>