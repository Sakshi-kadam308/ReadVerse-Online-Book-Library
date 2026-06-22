<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ include file="db_config.jsp" %>
<%
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    if(username == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    String userIdStr = (String) session.getAttribute("user_id");
    String bookId = request.getParameter("book_id");
    
    if(bookId == null || bookId.trim().isEmpty()) {
        response.sendRedirect("library.jsp");
        return;
    }
    
    String bookTitle = "";
    String author = "";
    String filePath = "";
    String coverImage = "";
    String accessType = "";
    boolean canAccess = false;
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = getConnection();
        
        // Check if user has access to this book
        String accessSql = "SELECT b.title, b.author, b.file_path, b.cover_image, ul.access_type, " +
                          "ul.expiry_date, DATEDIFF(ul.expiry_date, NOW()) as days_remaining " +
                          "FROM user_library ul " +
                          "JOIN books b ON ul.book_id = b.book_id " +
                          "WHERE ul.user_id = ? AND ul.book_id = ? AND ul.status = 'active'";
        
        pstmt = conn.prepareStatement(accessSql);
        pstmt.setInt(1, Integer.parseInt(userIdStr));
        pstmt.setInt(2, Integer.parseInt(bookId));
        rs = pstmt.executeQuery();
        
        if(rs.next()) {
            bookTitle = rs.getString("title");
            author = rs.getString("author");
            filePath = rs.getString("file_path");
            coverImage = rs.getString("cover_image");
            accessType = rs.getString("access_type");
            
            if("purchase".equals(accessType)) {
                canAccess = true;
            } else if("rental".equals(accessType)) {
                int daysRemaining = rs.getInt("days_remaining");
                canAccess = daysRemaining > 0;
            }
        }
        
    } catch(Exception e) {
        e.printStackTrace();
    } finally {
        try { if(rs != null) rs.close(); } catch(Exception e) {}
        try { if(pstmt != null) pstmt.close(); } catch(Exception e) {}
        try { if(conn != null) conn.close(); } catch(Exception e) {}
    }
    
    if(!canAccess) {
        response.sendRedirect("library.jsp?error=no_access");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <%@ include file="head_include.jsp" %>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= bookTitle %> - ReadVerse</title>
    <style>
        /* Add reading interface styles here */
        body { margin: 0; padding: 0; font-family: Arial, sans-serif; }
        .reader-container { max-width: 1000px; margin: 0 auto; padding: 20px; }
        .book-header { text-align: center; margin-bottom: 30px; }
        .book-content { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    </style>
</head>
<body>
    <div class="reader-container">
        <div class="book-header">
            <h1><%= bookTitle %></h1>
            <p>by <%= author %></p>
        </div>
        
        <div class="book-content">
            <% if(filePath != null && !filePath.isEmpty()) { 
                if(filePath.toLowerCase().endsWith(".pdf")) { 
            %>
                <embed src="<%= filePath %>" type="application/pdf" width="100%" height="600px">
            <% } else { %>
                <p style="text-align: center; padding: 40px;">
                    <i class="fas fa-book" style="font-size: 3rem; color: #6c63ff;"></i><br><br>
                    This book is available for download.<br>
                    <a href="<%= filePath %>" download class="btn">Download Book</a>
                </p>
            <% } } else { %>
                <p style="text-align: center; padding: 40px; color: #666;">
                    <i class="fas fa-exclamation-circle" style="font-size: 3rem;"></i><br><br>
                    Book content not available at the moment.
                </p>
            <% } %>
        </div>
        
        <div style="text-align: center; margin-top: 20px;">
            <a href="library.jsp" class="btn">Back to Library</a>
        </div>
    </div>
    
    <script>
        // Add reading progress tracking
        localStorage.setItem('last_read_<%= bookId %>', new Date().toISOString());
    </script>
</body>
</html>