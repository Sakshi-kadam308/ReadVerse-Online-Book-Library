<%@ page contentType="text/html; charset=ISO-8859-1" %>
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
    if(userIdStr == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    Connection conn = null;
    int userId = 0;
    
    try {
        userId = Integer.parseInt(userIdStr);
    } catch(NumberFormatException e) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    try {
        conn = getConnection();
        
        // Clear all cart items for user
        String sql = "DELETE FROM cart WHERE user_id = ?";
        PreparedStatement pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, userId);
        pstmt.executeUpdate();
        pstmt.close();
        
        // Update cart count in session
        session.setAttribute("cartCount", 0);
        
        // Set success message
        session.setAttribute("cartMessage", "Cart cleared successfully!");
        
    } catch(Exception e) {
        e.printStackTrace();
        session.setAttribute("cartMessage", "Error clearing cart: " + e.getMessage());
    } finally {
        if(conn != null) try { conn.close(); } catch(Exception e) {}
    }
    
    response.sendRedirect("cart.jsp");
%>