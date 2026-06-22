<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*, java.util.*, java.text.SimpleDateFormat, java.io.File, 
                 java.io.FileInputStream, java.io.OutputStream" %>
<%@ include file="db_config.jsp" %>
<%
    // Check if user is logged in
    String username = (String) session.getAttribute("username");
    if(username == null) {
        response.sendRedirect("login.jsp?redirect=library.jsp");
        return;
    }
    
    String userIdStr = (String) session.getAttribute("user_id");
    if(userIdStr == null || userIdStr.trim().isEmpty()) {
        response.sendRedirect("login.jsp?redirect=library.jsp");
        return;
    }
    
    List<Map<String, Object>> libraryItems = new ArrayList<>();
    Connection conn = null;
    
    // Set upload directory path - Use relative path for better portability
    String uploadDir = application.getRealPath("/") + "uploads/books/";
    // Ensure directory exists
    File uploadDirFile = new File(uploadDir);
    if(!uploadDirFile.exists()) {
        uploadDirFile.mkdirs();
    }
    
    // Check if download is requested
    String downloadBookId = request.getParameter("download");
    if(downloadBookId != null && !downloadBookId.trim().isEmpty()) {
        try {
            conn = getConnection();
            
            // Verify user owns the book and get file info
            String verifySql = "SELECT b.book_id, b.title, b.pdf_file, b.author, oi.type, oi.rental_end_date " +
                             "FROM books b " +
                             "INNER JOIN order_items oi ON b.book_id = oi.book_id " +
                             "INNER JOIN orders o ON oi.order_id = o.order_id " +
                             "WHERE b.book_id = ? AND o.user_id = ? AND o.payment_status = 'completed' " +
                             "AND (oi.type = 'purchase' OR (oi.type = 'rental' AND (oi.rental_end_date IS NULL OR oi.rental_end_date >= CURDATE())))";
            
            PreparedStatement verifyStmt = conn.prepareStatement(verifySql);
            verifyStmt.setInt(1, Integer.parseInt(downloadBookId));
            verifyStmt.setInt(2, Integer.parseInt(userIdStr));
            ResultSet verifyRs = verifyStmt.executeQuery();
            
            if(verifyRs.next()) {
                String pdfFile = verifyRs.getString("pdf_file");
                String type = verifyRs.getString("type");
                String title = verifyRs.getString("title");
                String author = verifyRs.getString("author");
                java.sql.Date rentalEndDate = verifyRs.getDate("rental_end_date");
                
                if(pdfFile != null && !pdfFile.trim().isEmpty()) {
                    // Check if file exists
                    File file = new File(uploadDir + File.separator + pdfFile);
                    
                    if(file.exists() && file.isFile()) {
                        // Get client IP address
                        String ipAddress = request.getRemoteAddr();
                        if(ipAddress == null || ipAddress.equals("0:0:0:0:0:0:0:1")) {
                            ipAddress = "127.0.0.1";
                        }
                        
                        // Get user agent
                        String userAgent = request.getHeader("User-Agent");
                        if(userAgent == null) userAgent = "Unknown";
                        
                        // Log download activity first
                        String logSql = "INSERT INTO download_logs (user_id, book_id, downloaded_at, ip_address, user_agent, download_type) VALUES (?, ?, NOW(), ?, ?, ?)";
                        PreparedStatement logStmt = conn.prepareStatement(logSql);
                        logStmt.setInt(1, Integer.parseInt(userIdStr));
                        logStmt.setInt(2, Integer.parseInt(downloadBookId));
                        logStmt.setString(3, ipAddress);
                        logStmt.setString(4, userAgent);
                        logStmt.setString(5, type); // 'purchase' or 'rental'
                        logStmt.executeUpdate();
                        logStmt.close();
                        
                        // Also update book download count
                        String updateSql = "UPDATE books SET download_count = COALESCE(download_count, 0) + 1 WHERE book_id = ?";
                        PreparedStatement updateStmt = conn.prepareStatement(updateSql);
                        updateStmt.setInt(1, Integer.parseInt(downloadBookId));
                        updateStmt.executeUpdate();
                        updateStmt.close();
                        
                        // Store download history for user
                        String historySql = "INSERT INTO download_history (user_id, book_id, download_date, download_count) " +
                                          "VALUES (?, ?, NOW(), 1) " +
                                          "ON DUPLICATE KEY UPDATE download_count = download_count + 1, last_download = NOW()";
                        PreparedStatement historyStmt = conn.prepareStatement(historySql);
                        historyStmt.setInt(1, Integer.parseInt(userIdStr));
                        historyStmt.setInt(2, Integer.parseInt(downloadBookId));
                        historyStmt.executeUpdate();
                        historyStmt.close();
                        
                        // Set response headers for file download
                        response.setContentType("application/pdf");
                        
                        // Sanitize filename for download
                        String safeFileName = (title + "_" + author).replaceAll("[^a-zA-Z0-9\\s]", "").replaceAll("\\s+", "_") + ".pdf";
                        safeFileName = safeFileName.substring(0, Math.min(safeFileName.length(), 100)); // Limit filename length
                        response.setHeader("Content-Disposition", 
                            "attachment; filename=\"" + safeFileName + "\"");
                        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
                        response.setHeader("Pragma", "no-cache");
                        response.setHeader("Expires", "0");
                        response.setContentLength((int) file.length());
                        
                        // Clear any existing output
                        out.clear();
                        out = pageContext.pushBody();
                        
                        // Stream file to response
                        FileInputStream fileInputStream = null;
                        OutputStream responseOutputStream = null;
                        
                        try {
                            fileInputStream = new FileInputStream(file);
                            responseOutputStream = response.getOutputStream();
                            
                            byte[] buffer = new byte[4096];
                            int bytesRead = -1;
                            
                            while ((bytesRead = fileInputStream.read(buffer)) != -1) {
                                responseOutputStream.write(buffer, 0, bytesRead);
                            }
                            
                            responseOutputStream.flush();
                            
                            // Store success message in session for when user returns
                            session.setAttribute("success", "Download started for: " + title);
                            
                        } catch(Exception e) {
                            // Log error
                            System.err.println("Error streaming file: " + e.getMessage());
                            session.setAttribute("error", "Error downloading file. Please try again.");
                        } finally {
                            if(fileInputStream != null) {
                                try { fileInputStream.close(); } catch(Exception e) {}
                            }
                            if(responseOutputStream != null) {
                                try { responseOutputStream.close(); } catch(Exception e) {}
                            }
                        }
                        
                        verifyRs.close();
                        verifyStmt.close();
                        conn.close();
                        return; // Important: return to stop further processing
                        
                    } else {
                        session.setAttribute("error", "PDF file not found on server.");
                    }
                } else {
                    session.setAttribute("error", "No PDF available for this book.");
                }
            } else {
                session.setAttribute("error", "You don't have permission to download this book or rental period has expired.");
            }
            
            verifyRs.close();
            verifyStmt.close();
        } catch(NumberFormatException e) {
            session.setAttribute("error", "Invalid book ID format.");
        } catch(SQLException e) {
            e.printStackTrace();
            session.setAttribute("error", "Database error: " + e.getMessage());
        } catch(Exception e) {
            e.printStackTrace();
            session.setAttribute("error", "Error downloading file: " + e.getMessage());
        } finally {
            if(conn != null) {
                try { conn.close(); } catch(Exception e) {}
            }
        }
        
        // Redirect to remove download parameter from URL
        response.sendRedirect("library.jsp");
        return;
    }
    
    // Main library data fetching - Modified to get download counts
    int downloadableCount = 0;
    int totalDownloads = 0; // Add total downloads counter
    try {
        conn = getConnection();
        
        // Get user's orders with order items and download counts
        String sql = "SELECT oi.*, b.book_id, b.title, b.author, b.category, b.pages, b.pdf_file, " +
                     "b.download_count as book_downloads, " +
                     "o.order_date, o.payment_status, " +
                     "COALESCE(dh.download_count, 0) as user_download_count " +
                     "FROM order_items oi " +
                     "INNER JOIN books b ON oi.book_id = b.book_id " +
                     "INNER JOIN orders o ON oi.order_id = o.order_id " +
                     "LEFT JOIN download_history dh ON b.book_id = dh.book_id AND dh.user_id = o.user_id " +
                     "WHERE o.user_id = ? AND o.payment_status = 'completed' " +
                     "ORDER BY o.order_date DESC";
        
        PreparedStatement pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, Integer.parseInt(userIdStr));
        ResultSet rs = pstmt.executeQuery();
        
        SimpleDateFormat displayFormat = new SimpleDateFormat("MMM dd, yyyy");
        
        while(rs.next()) {
            Map<String, Object> item = new HashMap<>();
            item.put("book_id", rs.getInt("book_id"));
            item.put("type", rs.getString("type"));
            item.put("title", rs.getString("title"));
            item.put("author", rs.getString("author"));
            item.put("category", rs.getString("category"));
            item.put("pages", rs.getInt("pages"));
            item.put("pdf_file", rs.getString("pdf_file"));
            item.put("price", rs.getDouble("price"));
            item.put("rental_days", rs.getInt("rental_days"));
            item.put("rental_start_date", rs.getDate("rental_start_date"));
            item.put("rental_end_date", rs.getDate("rental_end_date"));
            item.put("order_date", rs.getTimestamp("order_date"));
            item.put("book_downloads", rs.getInt("book_downloads"));
            item.put("user_download_count", rs.getInt("user_download_count"));
            
            // Check if rental is still valid
            boolean isRental = "rental".equals(rs.getString("type"));
            boolean canDownload = false;
            
            if(isRental) {
                java.sql.Date rentalEndDate = rs.getDate("rental_end_date");
                if(rentalEndDate != null) {
                    java.util.Date currentDate = new java.util.Date();
                    canDownload = !currentDate.after(rentalEndDate);
                }
            } else {
                canDownload = true; // Purchased books can always be downloaded
            }
            item.put("can_download", canDownload);
            
            // Check if PDF file exists
            String pdfFile = rs.getString("pdf_file");
            boolean hasPDF = false;
            if(pdfFile != null && !pdfFile.trim().isEmpty()) {
                File pdf = new File(uploadDir + File.separator + pdfFile);
                hasPDF = pdf.exists() && pdf.isFile();
            }
            item.put("has_pdf", hasPDF);
            
            // Count downloadable books
            if(hasPDF && canDownload) {
                downloadableCount++;
            }
            
            // Add to total downloads
            totalDownloads += rs.getInt("user_download_count");
            
            // Format dates
            if(rs.getDate("rental_start_date") != null) {
                item.put("formatted_start_date", displayFormat.format(rs.getDate("rental_start_date")));
            }
            if(rs.getDate("rental_end_date") != null) {
                item.put("formatted_end_date", displayFormat.format(rs.getDate("rental_end_date")));
            }
            if(rs.getTimestamp("order_date") != null) {
                item.put("formatted_order_date", displayFormat.format(rs.getTimestamp("order_date")));
            }
            
            libraryItems.add(item);
        }
        
        rs.close();
        pstmt.close();
        
        // Get total download statistics for the user
        String statsSql = "SELECT COUNT(DISTINCT book_id) as unique_books_downloaded, " +
                         "SUM(download_count) as total_downloads " +
                         "FROM download_history " +
                         "WHERE user_id = ?";
        PreparedStatement statsStmt = conn.prepareStatement(statsSql);
        statsStmt.setInt(1, Integer.parseInt(userIdStr));
        ResultSet statsRs = statsStmt.executeQuery();
        
        if(statsRs.next()) {
            int uniqueBooksDownloaded = statsRs.getInt("unique_books_downloaded");
            int totalUserDownloads = statsRs.getInt("total_downloads");
            // Store in session for potential display
            session.setAttribute("unique_books_downloaded", uniqueBooksDownloaded);
            session.setAttribute("total_user_downloads", totalUserDownloads);
        }
        
        statsRs.close();
        statsStmt.close();
        
    } catch(NumberFormatException e) {
        session.setAttribute("error", "Invalid user ID in session.");
    } catch(SQLException e) {
        e.printStackTrace();
        session.setAttribute("error", "Database error while loading library: " + e.getMessage());
    } catch(Exception e) {
        e.printStackTrace();
        session.setAttribute("error", "Error loading library: " + e.getMessage());
    } finally {
        if(conn != null) {
            try { conn.close(); } catch(Exception e) {}
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <%@ include file="head_include.jsp" %>
    <title>My Library - ReadVerse</title>
    <style>
        .library-container {
            margin: 50px 0 80px;
        }
        
        .library-header {
            text-align: center;
            margin-bottom: 50px;
        }
        
        .library-header h1 {
            font-size: 2.8rem;
            color: var(--dark);
            margin-bottom: 15px;
        }
        
        .download-stats {
            background: linear-gradient(135deg, #6c63ff 0%, #667eea 100%);
            color: white;
            border-radius: var(--border-radius);
            padding: 25px;
            margin-bottom: 30px;
            display: flex;
            justify-content: space-around;
            flex-wrap: wrap;
            gap: 20px;
            box-shadow: var(--shadow);
        }
        
        .stat-item {
            text-align: center;
            flex: 1;
            min-width: 200px;
        }
        
        .stat-number {
            font-size: 2.5rem;
            font-weight: 700;
            margin-bottom: 5px;
        }
        
        .stat-label {
            font-size: 1rem;
            opacity: 0.9;
        }
        
        .library-tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 30px;
            border-bottom: 1px solid var(--light);
            padding-bottom: 20px;
            flex-wrap: wrap;
        }
        
        .library-tab {
            padding: 12px 25px;
            border: none;
            background: none;
            color: var(--gray);
            font-weight: 600;
            cursor: pointer;
            border-radius: 50px;
            transition: var(--transition);
            white-space: nowrap;
        }
        
        .library-tab:hover {
            color: var(--primary);
            background: rgba(108, 99, 255, 0.1);
        }
        
        .library-tab.active {
            color: var(--primary);
            background: rgba(108, 99, 255, 0.1);
        }
        
        .library-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 30px;
        }
        
        .library-empty {
            grid-column: 1 / -1;
            text-align: center;
            padding: 60px 20px;
            background: white;
            border-radius: var(--border-radius);
            box-shadow: var(--shadow-light);
        }
        
        .book-item {
            background: white;
            border-radius: var(--border-radius);
            padding: 25px;
            box-shadow: var(--shadow-light);
            transition: var(--transition);
            position: relative;
            display: flex;
            flex-direction: column;
        }
        
        .book-item:hover {
            transform: translateY(-5px);
            box-shadow: var(--shadow);
        }
        
        .book-badge {
            position: absolute;
            top: 15px;
            right: 15px;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 600;
            color: white;
            z-index: 1;
        }
        
        .book-badge.rental {
            background: var(--primary);
        }
        
        .book-badge.purchase {
            background: var(--secondary);
        }
        
        .pdf-badge {
            position: absolute;
            top: 15px;
            left: 15px;
            padding: 5px 10px;
            border-radius: 20px;
            font-size: 0.7rem;
            font-weight: 600;
            background: #4CAF50;
            color: white;
            z-index: 1;
        }
        
        .book-title {
            font-size: 1.3rem;
            color: var(--dark);
            margin-bottom: 10px;
            margin-top: 30px;
            line-height: 1.3;
        }
        
        .book-author {
            color: var(--gray);
            font-size: 0.95rem;
            margin-bottom: 15px;
        }
        
        .book-meta {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            margin-bottom: 20px;
        }
        
        .book-category {
            background: var(--light);
            color: var(--primary);
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9rem;
            white-space: nowrap;
        }
        
        .pages-tag {
            background: var(--light);
            color: var(--gray);
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9rem;
            display: inline-block;
            white-space: nowrap;
        }
        
        .download-count-badge {
            background: #ff9800;
            color: white;
            padding: 3px 10px;
            border-radius: 20px;
            font-size: 0.7rem;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            white-space: nowrap;
        }
        
        .rental-info {
            background: rgba(108, 99, 255, 0.1);
            padding: 15px;
            border-radius: 10px;
            margin: 20px 0;
        }
        
        .rental-dates {
            display: flex;
            justify-content: space-between;
            font-size: 0.9rem;
            color: var(--dark);
            flex-wrap: wrap;
            gap: 10px;
        }
        
        .rental-progress {
            height: 6px;
            background: var(--light);
            border-radius: 3px;
            margin-top: 10px;
            overflow: hidden;
        }
        
        .rental-progress-bar {
            height: 100%;
            background: var(--primary);
            border-radius: 3px;
            transition: width 0.5s ease;
        }
        
        .book-actions {
            display: flex;
            gap: 10px;
            margin-top: 20px;
            margin-top: auto;
        }
        
        .book-actions .btn {
            flex: 1;
            min-width: 0;
        }
        
        .btn-download {
            background: #4CAF50;
            color: white;
            border: none;
            position: relative;
        }
        
        .btn-download:hover:not(:disabled) {
            background: #45a049;
            transform: translateY(-2px);
        }
        
        .btn-download:disabled {
            background: #cccccc;
            cursor: not-allowed;
            opacity: 0.6;
        }
        
        .download-counter {
            position: absolute;
            top: -8px;
            right: -8px;
            background: #ff9800;
            color: white;
            border-radius: 50%;
            width: 24px;
            height: 24px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.7rem;
            font-weight: bold;
            border: 2px solid white;
        }
        
        .download-info {
            font-size: 0.85rem;
            color: #666;
            margin-top: 5px;
            display: flex;
            align-items: center;
            gap: 5px;
            flex-wrap: wrap;
        }
        
        .download-info i {
            color: #4CAF50;
        }
        
        .no-pdf-warning {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            color: #856404;
            padding: 10px;
            border-radius: 5px;
            font-size: 0.85rem;
            margin-top: 10px;
        }
        
        .notification {
            position: fixed;
            top: 100px;
            right: 20px;
            padding: 15px 20px;
            border-radius: 5px;
            color: white;
            font-weight: 600;
            z-index: 1000;
            animation: slideIn 0.3s ease;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            max-width: 400px;
            word-wrap: break-word;
        }
        
        .notification.success {
            background: #4CAF50;
            border-left: 4px solid #388E3C;
        }
        
        .notification.error {
            background: #f44336;
            border-left: 4px solid #d32f2f;
        }
        
        .notification .close-btn {
            background: none;
            border: none;
            color: white;
            margin-left: 15px;
            cursor: pointer;
            font-size: 16px;
            opacity: 0.8;
        }
        
        .notification .close-btn:hover {
            opacity: 1;
        }
        
        @keyframes slideIn {
            from { transform: translateX(100%); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }
        
        .book-item.expired .book-badge {
            background: #FF9800;
        }
        
        .expired-warning {
            background: #ffebee;
            color: #c62828;
            padding: 8px;
            border-radius: 5px;
            margin-top: 10px;
            font-size: 0.85rem;
            display: flex;
            align-items: center;
            gap: 5px;
        }
        
        .badge-count {
            background: #4CAF50;
            color: white;
            padding: 2px 8px;
            border-radius: 10px;
            font-size: 0.7rem;
            margin-left: 5px;
        }
        
        .recent-downloads {
            background: #f8f9fa;
            border-radius: var(--border-radius);
            padding: 20px;
            margin-top: 40px;
            border: 1px solid #e9ecef;
        }
        
        .recent-downloads h3 {
            color: var(--dark);
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .downloads-list {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 15px;
        }
        
        .download-item {
            background: white;
            padding: 15px;
            border-radius: 8px;
            border: 1px solid #e9ecef;
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .download-item i {
            color: #4CAF50;
            font-size: 1.2rem;
        }
        
        .download-item-info h4 {
            margin: 0 0 5px 0;
            font-size: 0.9rem;
            color: var(--dark);
        }
        
        .download-item-info p {
            margin: 0;
            font-size: 0.8rem;
            color: var(--gray);
        }
        
        @media (max-width: 768px) {
            .library-grid {
                grid-template-columns: 1fr;
            }
            
            .library-tabs {
                flex-direction: row;
                overflow-x: auto;
                padding-bottom: 15px;
            }
            
            .library-tab {
                padding: 10px 20px;
                font-size: 0.9rem;
            }
            
            .book-actions {
                flex-direction: column;
            }
            
            .book-actions .btn {
                width: 100%;
            }
            
            .notification {
                left: 20px;
                right: 20px;
                max-width: none;
            }
            
            .download-stats {
                flex-direction: column;
                align-items: center;
            }
            
            .stat-item {
                min-width: 150px;
            }
        }
        
        @media (max-width: 480px) {
            .book-meta {
                flex-direction: column;
                align-items: flex-start;
            }
            
            .rental-dates {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <%@ include file="header.jsp" %>
    
    <div class="container library-container">
        <div class="library-header">
            <h1>My Library</h1>
            <p style="color: var(--gray); max-width: 600px; margin: 0 auto;">
                All your purchased and rented books in one place. Download purchased books or rented books within rental period.
            </p>
        </div>
        
        <!-- Download Statistics -->
        <div class="download-stats">
            <div class="stat-item">
                <div class="stat-number"><%= libraryItems.size() %></div>
                <div class="stat-label">Total Books</div>
            </div>
            <div class="stat-item">
                <div class="stat-number"><%= downloadableCount %></div>
                <div class="stat-label">Downloadable</div>
            </div>
            <div class="stat-item">
                <div class="stat-number"><%= totalDownloads %></div>
                <div class="stat-label">Total Downloads</div>
            </div>
        </div>
        
        <!-- Display messages -->
        <% 
        String error = (String) session.getAttribute("error");
        String success = (String) session.getAttribute("success");
        
        if(error != null) {
        %>
        <div class="notification error" id="errorMsg">
            <i class="fas fa-exclamation-circle"></i> <%= error %>
            <button class="close-btn" onclick="this.parentElement.style.display='none'">
                <i class="fas fa-times"></i>
            </button>
        </div>
        <%
            session.removeAttribute("error");
        }
        
        if(success != null) {
        %>
        <div class="notification success" id="successMsg">
            <i class="fas fa-check-circle"></i> <%= success %>
            <button class="close-btn" onclick="this.parentElement.style.display='none'">
                <i class="fas fa-times"></i>
            </button>
        </div>
        <%
            session.removeAttribute("success");
        }
        %>
        
        <div class="library-tabs">
            <button class="library-tab active" data-filter="all">All Books</button>
            <button class="library-tab" data-filter="purchase">Purchased</button>
            <button class="library-tab" data-filter="rental">Rented</button>
            <button class="library-tab" data-filter="downloadable" id="downloadableTab">
                Downloadable <% if(downloadableCount > 0) { %><span class="badge-count"><%= downloadableCount %></span><% } %>
            </button>
        </div>
        
        <div class="library-grid">
            <% 
            if(libraryItems.isEmpty()) { 
            %>
            <div class="library-empty">
                <div style="font-size: 5rem; color: var(--primary); margin-bottom: 20px;">
                    <i class="fas fa-book-open"></i>
                </div>
                <h3 style="color: var(--dark); margin-bottom: 15px;">Your library is empty</h3>
                <p style="color: var(--gray); margin-bottom: 30px; max-width: 500px; margin-left: auto; margin-right: auto;">
                    You haven't purchased or rented any books yet. Start building your collection today!
                </p>
                <div style="display: flex; gap: 15px; justify-content: center; flex-wrap: wrap;">
                    <a href="rental.jsp" class="btn btn-primary">
                        <i class="fas fa-calendar-alt"></i> Browse Rentals
                    </a>
                    <a href="purchase.jsp" class="btn btn-outline">
                        <i class="fas fa-shopping-bag"></i> Browse Purchases
                    </a>
                </div>
            </div>
            <% 
            } else {
                for(Map<String, Object> item : libraryItems) { 
                    String type = (String) item.get("type");
                    boolean isRental = "rental".equals(type);
                    boolean hasPDF = (Boolean) item.get("has_pdf");
                    boolean canDownload = (Boolean) item.get("can_download");
                    Integer bookId = (Integer) item.get("book_id");
                    Integer userDownloadCount = (Integer) item.get("user_download_count");
                    Integer bookTotalDownloads = (Integer) item.get("book_downloads");
                    
                    // Calculate rental progress if applicable
                    double rentalProgress = 0;
                    boolean isExpired = false;
                    
                    if(isRental && item.get("rental_start_date") != null && item.get("rental_end_date") != null) {
                        java.util.Date startDate = (java.util.Date) item.get("rental_start_date");
                        java.util.Date endDate = (java.util.Date) item.get("rental_end_date");
                        java.util.Date currentDate = new java.util.Date();
                        
                        long totalDuration = endDate.getTime() - startDate.getTime();
                        long elapsedDuration = currentDate.getTime() - startDate.getTime();
                        
                        if(totalDuration > 0) {
                            rentalProgress = (double) elapsedDuration / totalDuration * 100;
                            if(rentalProgress > 100) {
                                rentalProgress = 100;
                                isExpired = true;
                            }
                            if(rentalProgress < 0) rentalProgress = 0;
                        }
                        
                        // Check if expired
                        if(currentDate.after(endDate)) {
                            isExpired = true;
                        }
                    }
                    
                    Integer pages = (Integer) item.get("pages");
                    // Escape single quotes in title for JavaScript - CORRECTED LINE
                    String escapedTitle = ((String)item.get("title")).replace("'", "\\'");
            %>
            <div class="book-item <%= isExpired ? "expired" : "" %>" 
                 data-type="<%= type %>" 
                 data-haspdf="<%= hasPDF %>" 
                 data-candownload="<%= canDownload %>">
                
                <% if(hasPDF) { %>
                <span class="pdf-badge">
                    <i class="fas fa-file-pdf"></i> PDF
                </span>
                <% } %>
                
                <span class="book-badge <%= type %>">
                    <i class="fas fa-<%= isRental ? "clock" : "crown" %>"></i>
                    <%= isRental ? "RENTAL" : "PURCHASE" %>
                </span>
                
                <% if(bookTotalDownloads > 0) { %>
                <span class="download-count-badge" style="position: absolute; top: 45px; right: 15px;">
                    <i class="fas fa-download"></i> <%= bookTotalDownloads %> downloads
                </span>
                <% } %>
                
                <h3 class="book-title"><%= item.get("title") %></h3>
                <p class="book-author">by <%= item.get("author") %></p>
                
                <div class="book-meta">
                    <span class="book-category"><%= item.get("category") %></span>
                    <% if(pages != null && pages > 0) { %>
                    <span class="pages-tag">
                        <i class="fas fa-file-alt"></i> <%= pages %> pages
                    </span>
                    <% } %>
                </div>
                
                <% if(isRental) { %>
                <div class="rental-info">
                    <div class="rental-dates">
                        <div>
                            <div style="font-size: 0.8rem; color: var(--gray);">Start Date</div>
                            <div style="font-weight: 600;"><%= item.get("formatted_start_date") %></div>
                        </div>
                        <div>
                            <div style="font-size: 0.8rem; color: var(--gray);">End Date</div>
                            <div style="font-weight: 600;"><%= item.get("formatted_end_date") %></div>
                        </div>
                    </div>
                    
                    <div class="rental-progress">
                        <div class="rental-progress-bar" style="width: <%= rentalProgress %>%"></div>
                    </div>
                    
                    <div style="text-align: center; margin-top: 10px;">
                        <span style="font-size: 0.8rem; color: var(--gray);">
                            <%= (int)rentalProgress %>% complete • <%= item.get("rental_days") %> days
                        </span>
                    </div>
                    
                    <% if(isExpired || !canDownload) { %>
                    <div class="expired-warning">
                        <i class="fas fa-exclamation-triangle"></i> 
                        <%= isExpired ? "Rental period expired" : "Cannot download" %>
                    </div>
                    <% } %>
                </div>
                <% } %>
                
                <div style="color: var(--gray); font-size: 0.9rem; margin-top: 15px;">
                    <i class="fas fa-calendar"></i> Added on <%= item.get("formatted_order_date") %>
                </div>
                
                <% if(!hasPDF) { %>
                <div class="no-pdf-warning">
                    <i class="fas fa-exclamation-circle"></i> PDF not available for this book
                </div>
                <% } %>
                
                <div class="book-actions">
                    <button class="btn btn-primary" onclick="readBook(<%= bookId %>, '<%= escapedTitle %>')">
                        <i class="fas fa-book-open"></i> Read Now
                    </button>
                    
                    <% 
                    if(canDownload && hasPDF) { 
                    %>
                    <button class="btn btn-download" onclick="downloadBook(<%= bookId %>, '<%= escapedTitle %>', this)">
                        <i class="fas fa-download"></i> Download
                        <% if(userDownloadCount > 0) { %>
                        <span class="download-counter"><%= userDownloadCount %></span>
                        <% } %>
                    </button>
                    <% 
                    } else { 
                        String buttonText = !hasPDF ? "No PDF" : "Cannot Download";
                    %>
                    <button class="btn btn-download disabled" disabled>
                        <i class="fas fa-download"></i> <%= buttonText %>
                    </button>
                    <% } %>
                </div>
                
                <% if(hasPDF) { %>
                <div class="download-info">
                    <% if(isRental && canDownload) { %>
                    <i class="fas fa-info-circle"></i>
                    Download available until <%= item.get("formatted_end_date") %>
                    <% } else if(!isRental) { %>
                    <i class="fas fa-check-circle"></i>
                    Unlimited downloads for purchased book
                    <% } else { %>
                    <i class="fas fa-times-circle"></i>
                    Download not available
                    <% } %>
                </div>
                <% } %>
            </div>
            <% 
                }
            } 
            %>
        </div>
    </div>

    <script>
        // Library tab filtering
        document.querySelectorAll('.library-tab').forEach(tab => {
            tab.addEventListener('click', function() {
                // Remove active class from all tabs
                document.querySelectorAll('.library-tab').forEach(t => {
                    t.classList.remove('active');
                });
                
                // Add active class to clicked tab
                this.classList.add('active');
                
                // Filter books
                const filter = this.dataset.filter;
                document.querySelectorAll('.book-item').forEach(item => {
                    if(filter === 'all') {
                        item.style.display = 'flex';
                    } else if(filter === 'downloadable') {
                        const hasPDF = item.getAttribute('data-haspdf') === 'true';
                        const canDownload = item.getAttribute('data-candownload') === 'true';
                        if(hasPDF && canDownload) {
                            item.style.display = 'flex';
                        } else {
                            item.style.display = 'none';
                        }
                    } else {
                        if(item.dataset.type === filter) {
                            item.style.display = 'flex';
                        } else {
                            item.style.display = 'none';
                        }
                    }
                });
            });
        });
        
        // Download book functionality
        function downloadBook(bookId, title, button) {
            // Show loading state
            const downloadButton = button || (event.target.closest('.btn-download') || event.target);
            const originalHTML = downloadButton.innerHTML;
            
            downloadButton.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Preparing...';
            downloadButton.disabled = true;
            
            // Show download in progress notification
            showNotification('Starting download for "' + title + '"...', 'info');
            
            // Track download attempt
            trackDownloadAttempt(bookId, title);
            
            // Start download
            window.location.href = 'library.jsp?download=' + bookId;
            
            // Restore button after 5 seconds
            setTimeout(() => {
                downloadButton.innerHTML = originalHTML;
                downloadButton.disabled = false;
                
                // Update download counter if it exists
                const counter = downloadButton.querySelector('.download-counter');
                if(counter) {
                    const currentCount = parseInt(counter.textContent) || 0;
                    counter.textContent = currentCount + 1;
                } else if(downloadButton.querySelector('.fas.fa-download')) {
                    // Add counter if this is first download
                    downloadButton.style.position = 'relative';
                    const newCounter = document.createElement('span');
                    newCounter.className = 'download-counter';
                    newCounter.textContent = '1';
                    downloadButton.appendChild(newCounter);
                }
            }, 5000);
        }
        
        // Track download attempt (can be used for analytics)
        function trackDownloadAttempt(bookId, title) {
            // You can send an AJAX request here to track download attempts
            // For now, we'll just log to console
            console.log('Download attempt for book ID:', bookId, 'Title:', title);
            
            // Example AJAX implementation:
            /*
            fetch('/trackDownload', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    bookId: bookId,
                    title: title,
                    timestamp: new Date().toISOString()
                })
            })
            .then(response => response.json())
            .then(data => console.log('Download tracked:', data))
            .catch(error => console.error('Error tracking download:', error));
            */
        }
        
        // Read book functionality
        function readBook(bookId, title) {
            // In production, implement a proper reader
            showNotification('Opening "' + title + '" in reader...', 'info');
            
            // Track reading attempt
            console.log('Reading attempt for book ID:', bookId, 'Title:', title);
            
            // Simulate loading
            setTimeout(() => {
                // You would redirect to actual reader here
                // window.open('reader.jsp?book_id=' + bookId, '_blank');
                
                // For now, show a message about the reader
                showNotification('Online reader feature coming soon! For now, please download the PDF.', 'info');
            }, 500);
        }
        
        // Notification function
        function showNotification(message, type) {
            // Remove existing notifications
            const existingNotifications = document.querySelectorAll('.notification.temp');
            existingNotifications.forEach(n => n.remove());
            
            const notification = document.createElement('div');
            notification.className = 'notification ' + (type === 'error' ? 'error' : 'success') + ' temp';
            
            // Build HTML using string concatenation
            const iconClass = type === 'error' ? 'exclamation-circle' : 'info-circle';
            notification.innerHTML = 
                '<i class="fas fa-' + iconClass + '"></i> ' + 
                message +
                '<button class="close-btn" onclick="this.parentElement.remove()">' +
                    '<i class="fas fa-times"></i>' +
                '</button>';
            
            document.body.appendChild(notification);
            
            // Auto-remove after 5 seconds
            setTimeout(() => {
                if(notification.parentNode) {
                    notification.style.opacity = '0';
                    notification.style.transition = 'opacity 0.5s ease';
                    setTimeout(() => {
                        if(notification.parentNode) {
                            notification.remove();
                        }
                    }, 500);
                }
            }, 5000);
        }
        
        // Auto-hide notifications after 5 seconds
        document.addEventListener('DOMContentLoaded', function() {
            const notifications = document.querySelectorAll('.notification:not(.temp)');
            notifications.forEach(notification => {
                setTimeout(() => {
                    notification.style.opacity = '0';
                    notification.style.transition = 'opacity 0.5s ease';
                    setTimeout(() => {
                        if(notification.parentNode) {
                            notification.remove();
                        }
                    }, 500);
                }, 5000);
            });
            
            // Add click outside to close notifications
            document.addEventListener('click', function(event) {
                if(event.target.closest('.notification')) {
                    const closeBtn = event.target.closest('.close-btn');
                    if(closeBtn) {
                        closeBtn.parentElement.remove();
                    }
                }
            });
        });
    </script>
    
    <%@ include file="footer.jsp" %>
</body>
</html>