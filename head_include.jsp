<meta charset="ISO-8859-1">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&family=Playfair+Display:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
    * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
    }
    
    :root {
        --primary: #6C63FF;
        --primary-dark: #554FD8;
        --secondary: #FF6584;
        --accent: #36D1DC;
        --light: #F8F9FF;
        --dark: #2A265F;
        --gray: #8A8DB3;
        --gradient-primary: linear-gradient(135deg, var(--primary) 0%, var(--accent) 100%);
        --gradient-dark: linear-gradient(135deg, var(--dark) 0%, #1A1A3E 100%);
        --gradient-accent: linear-gradient(135deg, var(--secondary) 0%, #FF9A9E 100%);
        --shadow: 0 20px 40px rgba(108, 99, 255, 0.15);
        --shadow-light: 0 10px 30px rgba(108, 99, 255, 0.1);
        --transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        --border-radius: 16px;
    }
    
    body {
        font-family: 'Poppins', sans-serif;
        line-height: 1.7;
        color: var(--dark);
        background-color: var(--light);
        overflow-x: hidden;
    }
    
    h1, h2, h3, h4, h5 {
        font-family: 'Playfair Display', serif;
        font-weight: 700;
        line-height: 1.2;
    }
    
    .container {
        width: 100%;
        max-width: 1300px;
        margin: 0 auto;
        padding: 0 20px;
    }
    
    main {
        padding-top: 100px;
        min-height: calc(100vh - 300px);
    }
</style>