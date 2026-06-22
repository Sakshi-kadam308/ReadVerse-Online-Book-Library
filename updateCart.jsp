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
    String rentalDays = request.getParameter("rental_days");
    
    if(cartId == null || rentalDays == null) {
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
        
        // Update cart item
        String sql = "UPDATE cart SET rental_days = ? WHERE cart_id = ? AND user_id = ?";
        PreparedStatement pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, Integer.parseInt(rentalDays));
        pstmt.setInt(2, Integer.parseInt(cartId));
        pstmt.setInt(3, userId);
        pstmt.executeUpdate();
        pstmt.close();
        
        // Set success message
        session.setAttribute("cartMessage", "Cart updated successfully!");
        
    } catch(Exception e) {
        e.printStackTrace();
        session.setAttribute("cartMessage", "Error updating cart: " + e.getMessage());
    } finally {
        if(conn != null) try { conn.close(); } catch(Exception e) {}
    }
    
    response.sendRedirect("cart.jsp");
%>