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
    
    String bookId = request.getParameter("book_id");
    String type = request.getParameter("type");
    String rentalDays = request.getParameter("rental_days");
    
    if(bookId == null || type == null) {
        response.sendRedirect("index.jsp");
        return;
    }
    
    Connection conn = null;
    boolean success = false;
    String message = "";
    int userId = 0;
    
    try {
        userId = Integer.parseInt(userIdStr);
    } catch(NumberFormatException e) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    try {
        conn = getConnection();
        
        int bookIdInt = Integer.parseInt(bookId);
        int rentalDaysInt = (rentalDays != null && !rentalDays.isEmpty()) ? Integer.parseInt(rentalDays) : 
                           (type.equals("rental") ? 30 : 0);
        
        // Check if book exists and is available
        String checkBookSql = "SELECT available_copies FROM books WHERE book_id = ?";
        PreparedStatement checkBookStmt = conn.prepareStatement(checkBookSql);
        checkBookStmt.setInt(1, bookIdInt);
        ResultSet bookRs = checkBookStmt.executeQuery();
        
        if(!bookRs.next()) {
            message = "Book not found!";
            bookRs.close();
            checkBookStmt.close();
            response.sendRedirect("error.jsp?message=" + java.net.URLEncoder.encode(message, "ISO-8859-1"));
            return;
        }
        
        int availableCopies = bookRs.getInt("available_copies");
        bookRs.close();
        checkBookStmt.close();
        
        if(availableCopies <= 0) {
            message = "Sorry, this book is out of stock!";
            response.sendRedirect("error.jsp?message=" + java.net.URLEncoder.encode(message, "ISO-8859-1"));
            return;
        }
        
        // Check if book already in cart
        String checkSql = "SELECT * FROM cart WHERE user_id = ? AND book_id = ? AND type = ?";
        PreparedStatement checkStmt = conn.prepareStatement(checkSql);
        checkStmt.setInt(1, userId);
        checkStmt.setInt(2, bookIdInt);
        checkStmt.setString(3, type);
        ResultSet rs = checkStmt.executeQuery();
        
        if(rs.next()) {
            // Update existing cart item
            String updateSql = "UPDATE cart SET rental_days = ? WHERE cart_id = ?";
            PreparedStatement updateStmt = conn.prepareStatement(updateSql);
            updateStmt.setInt(1, rentalDaysInt);
            updateStmt.setInt(2, rs.getInt("cart_id"));
            updateStmt.executeUpdate();
            updateStmt.close();
            message = "Cart item updated successfully!";
        } else {
            // Add new cart item
            String insertSql = "INSERT INTO cart (user_id, book_id, type, rental_days) VALUES (?, ?, ?, ?)";
            PreparedStatement insertStmt = conn.prepareStatement(insertSql);
            insertStmt.setInt(1, userId);
            insertStmt.setInt(2, bookIdInt);
            insertStmt.setString(3, type);
            insertStmt.setInt(4, rentalDaysInt);
            insertStmt.executeUpdate();
            insertStmt.close();
            message = "Added to cart successfully!";
        }
        
        rs.close();
        checkStmt.close();
        
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
        
        success = true;
        
    } catch(Exception e) {
        e.printStackTrace();
        message = "Error: " + e.getMessage();
    } finally {
        if(conn != null) try { conn.close(); } catch(Exception e) {}
    }
    
    // Show success message and redirect
    if(success) {
        session.setAttribute("cartMessage", message);
        String referer = request.getHeader("Referer");
        if(referer != null && !referer.contains("login.jsp")) {
            response.sendRedirect(referer);
        } else {
            response.sendRedirect(type.equals("rental") ? "rental.jsp" : "purchase.jsp");
        }
    } else {
        response.sendRedirect("error.jsp?message=" + java.net.URLEncoder.encode(message, "ISO-8859-1"));
    }
%>