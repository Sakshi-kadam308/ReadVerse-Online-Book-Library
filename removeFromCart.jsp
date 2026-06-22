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
    
    String cartId = request.getParameter("cart_id");
    
    if(cartId == null) {
        response.sendRedirect("cart.jsp");
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
        
        // Delete cart item
        String sql = "DELETE FROM cart WHERE cart_id = ? AND user_id = ?";
        PreparedStatement pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, Integer.parseInt(cartId));
        pstmt.setInt(2, userId);
        pstmt.executeUpdate();
        pstmt.close();
        
        // Update cart count in session
        String countSql = "SELECT COUNT(*) as count FROM cart WHERE user_id = ?";
        PreparedStatement countStmt = conn.prepareStatement(countSql);
        countStmt.setInt(1, userId);
        ResultSet countRs = countStmt.executeQuery();
        
        if(countRs.next()) {
            session.setAttribute("cartCount", countRs.getInt("count"));
        }
        
        countRs.close();
        countStmt.close();
        
        // Set success message
        session.setAttribute("cartMessage", "Item removed from cart successfully!");
        
    } catch(Exception e) {
        e.printStackTrace();
        session.setAttribute("cartMessage", "Error removing item: " + e.getMessage());
    } finally {
        if(conn != null) try { conn.close(); } catch(Exception e) {}
    }
    
    response.sendRedirect("cart.jsp");
%>