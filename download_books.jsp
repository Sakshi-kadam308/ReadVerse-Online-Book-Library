<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.io.*" %>
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
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = getConnection();
        
        // Check if user has access to this book
        String accessSql = "SELECT b.title, b.file_path, ul.access_type, " +
                          "ul.expiry_date, DATEDIFF(ul.expiry_date, NOW()) as days_remaining " +
                          "FROM user_library ul " +
                          "JOIN books b ON ul.book_id = b.book_id " +
                          "WHERE ul.user_id = ? AND ul.book_id = ? AND ul.status = 'active'";
        
        pstmt = conn.prepareStatement(accessSql);
        pstmt.setInt(1, Integer.parseInt(userIdStr));
        pstmt.setInt(2, Integer.parseInt(bookId));
        rs = pstmt.executeQuery();
        
        if(rs.next()) {
            String accessType = rs.getString("access_type");
            boolean canAccess = false;
            
            if("purchase".equals(accessType)) {
                canAccess = true;
            } else if("rental".equals(accessType)) {
                int daysRemaining = rs.getInt("days_remaining");
                canAccess = daysRemaining > 0;
            }
            
            if(canAccess) {
                String filePath = rs.getString("file_path");
                String title = rs.getString("title");
                
                if(filePath != null && !filePath.isEmpty()) {
                    File file = new File(filePath);
                    if(file.exists()) {
                        // Set response headers for download
                        response.setContentType("application/octet-stream");
                        response.setHeader("Content-Disposition", 
                            "attachment; filename=\"" + title.replaceAll("[^a-zA-Z0-9.-]", "_") + 
                            filePath.substring(filePath.lastIndexOf('.')) + "\"");
                        response.setContentLength((int) file.length());
                        
                        // Stream the file
                        FileInputStream in = new FileInputStream(file);
                        OutputStream Out = response.getOutputStream();
                        byte[] buffer = new byte[4096];
                        int length;
                        while ((length = in.read(buffer)) > 0) {
                            Out.write(buffer, 0, length);
                        }
                        in.close();
                        out.flush();
                        return;
                    }
                }
            }
        }
        
    } catch(Exception e) {
        e.printStackTrace();
    } finally {
        try { if(rs != null) rs.close(); } catch(Exception e) {}
        try { if(pstmt != null) pstmt.close(); } catch(Exception e) {}
        try { if(conn != null) conn.close(); } catch(Exception e) {}
    }
    
    // If download fails, redirect to library
    response.sendRedirect("library.jsp?error=download_failed");
%>