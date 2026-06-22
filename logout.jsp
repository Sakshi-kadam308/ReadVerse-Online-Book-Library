<%@ page contentType="text/html; charset=ISO-8859-1" %>
<%
    String type = request.getParameter("type");
    
    if("admin".equals(type)) {
        // Clear admin session
        session.removeAttribute("admin_id");
        session.removeAttribute("admin_username");
        session.removeAttribute("admin_email");
        session.removeAttribute("admin_full_name");
        session.removeAttribute("admin_role");
        session.removeAttribute("is_admin");
        
        response.sendRedirect("login.jsp?user_type=admin");
    } else {
        // Clear user session
        session.removeAttribute("user_id");
        session.removeAttribute("username");
        session.removeAttribute("email");
        session.removeAttribute("full_name");
        session.removeAttribute("cartCount");
        
        response.sendRedirect("login.jsp");
    }
%>