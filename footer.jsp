    </main>
    
    <!-- Footer -->
    <footer style="background: var(--dark); color: white; padding: 80px 0 30px;">
        <div class="container">
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 50px; margin-bottom: 50px;">
                <div>
                    <h3 style="font-size: 1.5rem; margin-bottom: 25px; color: white;">ReadVerse</h3>
                    <p style="color: rgba(255, 255, 255, 0.7); margin-bottom: 20px;">
                        Your gateway to limitless reading. Discover, rent, or purchase e-books from the world's largest digital library.
                    </p>
                    <div style="display: flex; gap: 15px; margin-top: 25px;">
                        <a href="#" style="display: inline-flex; align-items: center; justify-content: center; width: 45px; height: 45px; background: rgba(255, 255, 255, 0.1); border-radius: 50%; color: white; text-decoration: none; transition: var(--transition);">
                            <i class="fab fa-facebook-f"></i>
                        </a>
                        <a href="#" style="display: inline-flex; align-items: center; justify-content: center; width: 45px; height: 45px; background: rgba(255, 255, 255, 0.1); border-radius: 50%; color: white; text-decoration: none; transition: var(--transition);">
                            <i class="fab fa-twitter"></i>
                        </a>
                        <a href="#" style="display: inline-flex; align-items: center; justify-content: center; width: 45px; height: 45px; background: rgba(255, 255, 255, 0.1); border-radius: 50%; color: white; text-decoration: none; transition: var(--transition);">
                            <i class="fab fa-instagram"></i>
                        </a>
                        <a href="#" style="display: inline-flex; align-items: center; justify-content: center; width: 45px; height: 45px; background: rgba(255, 255, 255, 0.1); border-radius: 50%; color: white; text-decoration: none; transition: var(--transition);">
                            <i class="fab fa-youtube"></i>
                        </a>
                    </div>
                </div>
                
                <div>
                    <h3 style="font-size: 1.5rem; margin-bottom: 25px; color: white;">Quick Links</h3>
                    <ul style="list-style: none;">
                        <li style="margin-bottom: 12px;"><a href="index.jsp" style="color: rgba(255, 255, 255, 0.7); text-decoration: none; transition: var(--transition); display: flex; align-items: center; gap: 10px;"><i class="fas fa-chevron-right"></i> Home</a></li>
                        <li style="margin-bottom: 12px;"><a href="rental.jsp" style="color: rgba(255, 255, 255, 0.7); text-decoration: none; transition: var(--transition); display: flex; align-items: center; gap: 10px;"><i class="fas fa-chevron-right"></i> Rent Books</a></li>
                        <li style="margin-bottom: 12px;"><a href="purchase.jsp" style="color: rgba(255, 255, 255, 0.7); text-decoration: none; transition: var(--transition); display: flex; align-items: center; gap: 10px;"><i class="fas fa-chevron-right"></i> Buy Books</a></li>
                        <li style="margin-bottom: 12px;"><a href="cart.jsp" style="color: rgba(255, 255, 255, 0.7); text-decoration: none; transition: var(--transition); display: flex; align-items: center; gap: 10px;"><i class="fas fa-chevron-right"></i> Shopping Cart</a></li>
                    </ul>
                </div>
                
                <div>
                    <h3 style="font-size: 1.5rem; margin-bottom: 25px; color: white;">Contact Info</h3>
                    <ul style="list-style: none; color: rgba(255, 255, 255, 0.7);">
                        <li style="margin-bottom: 12px; display: flex; align-items: center; gap: 10px;">
                            <i class="fas fa-map-marker-alt"></i> 123 Book Street, Reading City
                        </li>
                        <li style="margin-bottom: 12px; display: flex; align-items: center; gap: 10px;">
                            <i class="fas fa-phone"></i> +1 (555) 123-4567
                        </li>
                        <li style="margin-bottom: 12px; display: flex; align-items: center; gap: 10px;">
                            <i class="fas fa-envelope"></i> support@readverse.com
                        </li>
                    </ul>
                </div>
            </div>
            
            <div style="text-align: center; padding-top: 30px; border-top: 1px solid rgba(255, 255, 255, 0.1); color: rgba(255, 255, 255, 0.5); font-size: 0.9rem;">
                <p>&copy; 2023 ReadVerse. All rights reserved. | Designed with <i class="fas fa-heart" style="color: #FF6584;"></i> for book lovers worldwide.</p>
            </div>
        </div>
    </footer>

    <script>
        // Header scroll effect
        window.addEventListener('scroll', function() {
            const header = document.getElementById('header');
            if (window.scrollY > 50) {
                header.classList.add('scrolled');
            } else {
                header.classList.remove('scrolled');
            }
        });
    </script>
</body>
</html>