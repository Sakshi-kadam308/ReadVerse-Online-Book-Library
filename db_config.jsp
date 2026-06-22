<%@ page import="java.sql.*" %>

<%!
    public Connection getConnection() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/readverse_db5?useSSL=false&serverTimezone=UTC",
            "root",
            "Root@1234"
        );
    }
%>
