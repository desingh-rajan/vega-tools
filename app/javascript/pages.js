// ============================================
// VEGA TOOLS AND HARDWARES - LANDING PAGE SCRIPTS
// Smooth scroll animations and interactions
// ============================================

document.addEventListener("DOMContentLoaded", () => {
  // ============================================
  // NAVBAR SCROLL EFFECT
  // ============================================
  const navbar = document.getElementById("navbar");
  let lastScroll = 0;

  window.addEventListener("scroll", () => {
    const currentScroll = window.pageYOffset;

    // Add/remove scrolled class
    if (currentScroll > 50) {
      navbar.classList.add("scrolled");
    } else {
      navbar.classList.remove("scrolled");
    }

    lastScroll = currentScroll;
  });

  // ============================================
  // MOBILE MENU TOGGLE
  // ============================================
  const hamburger = document.getElementById("hamburger");
  const navMenu = document.getElementById("navMenu");

  if (hamburger && navMenu) {
    hamburger.addEventListener("click", () => {
      navMenu.classList.toggle("active");
      hamburger.classList.toggle("active");
    });

    // Close menu when clicking on a link
    const navLinks = document.querySelectorAll(".nav-link");
    navLinks.forEach((link) => {
      link.addEventListener("click", () => {
        navMenu.classList.remove("active");
        hamburger.classList.remove("active");
      });
    });
  }

  // ============================================
  // SMOOTH SCROLL FOR ANCHOR LINKS
  // ============================================
  document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
    anchor.addEventListener("click", function (e) {
      e.preventDefault();
      const target = document.querySelector(this.getAttribute("href"));

      if (target) {
        const offsetTop = target.offsetTop - 80; // Account for fixed navbar
        window.scrollTo({
          top: offsetTop,
          behavior: "smooth",
        });
      }
    });
  });

  // ============================================
  // INTERSECTION OBSERVER FOR SCROLL ANIMATIONS
  // ============================================
  const observerOptions = {
    threshold: 0.1,
    rootMargin: "0px 0px -100px 0px",
  };

  const animateOnScroll = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.style.opacity = "1";
        entry.target.style.transform = "translateY(0) translateX(0)";

        // Trigger animation for product cards
        if (entry.target.classList.contains("product-card")) {
          const cards = document.querySelectorAll(".product-card");
          cards.forEach((card, index) => {
            setTimeout(() => {
              card.style.opacity = "1";
              card.style.transform = "translateY(0) translateX(0)";
            }, index * 100);
          });
        }
      }
    });
  }, observerOptions);

  // Observe all animated elements
  const animatedElements = document.querySelectorAll(
    ".fade-in-up, .slide-in-left, .slide-in-right, .slide-in-up, .fade-in-left, .fade-in-right, .product-card"
  );

  animatedElements.forEach((el) => {
    animateOnScroll.observe(el);
  });

  // ============================================
  // PARALLAX EFFECT FOR HERO SECTIONS
  // ============================================
  const heroSections = document.querySelectorAll(".hero");

  window.addEventListener("scroll", () => {
    heroSections.forEach((hero) => {
      const scrolled = window.pageYOffset;
      const heroTop = hero.offsetTop;
      const heroHeight = hero.offsetHeight;

      // Apply parallax only when hero is in viewport
      if (
        scrolled + window.innerHeight > heroTop &&
        scrolled < heroTop + heroHeight
      ) {
        const speed = 0.5;
        const yPos = -(scrolled - heroTop) * speed;
        const background = hero.querySelector(".hero-background");

        if (background) {
          background.style.transform = `translateY(${yPos}px)`;
        }
      }
    });
  });

  // ============================================
  // STATS COUNTER ANIMATION
  // ============================================
  const stats = document.querySelectorAll(".stat-number");
  let statsAnimated = false;

  const animateStats = () => {
    stats.forEach((stat) => {
      const target = parseFloat(stat.textContent);
      const isDecimal = stat.textContent.includes(".");
      const increment = target / 50;
      let current = 0;

      const updateCount = () => {
        if (current < target) {
          current += increment;
          if (isDecimal) {
            stat.textContent = current.toFixed(1);
          } else {
            stat.textContent = Math.ceil(current) + "+";
          }
          requestAnimationFrame(updateCount);
        } else {
          if (isDecimal) {
            stat.textContent = target.toFixed(1);
          } else {
            stat.textContent = target + "+";
          }
        }
      };

      updateCount();
    });
  };

  // Trigger stats animation when hero section is in view
  const heroObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting && !statsAnimated) {
          animateStats();
          statsAnimated = true;
        }
      });
    },
    { threshold: 0.5 }
  );

  const hero1 = document.querySelector(".hero-1");
  if (hero1) {
    heroObserver.observe(hero1);
  }

  // ============================================
  // DYNAMIC GRID ANIMATION
  // ============================================
  const animatedGrid = document.querySelector(".animated-grid");

  if (animatedGrid) {
    let hue = 120;

    setInterval(() => {
      hue = (hue + 1) % 360;
      const color = `hsl(${hue}, 70%, 50%)`;
      animatedGrid.style.backgroundImage = `
        linear-gradient(rgba(${hexToRgb(color)}, 0.1) 1px, transparent 1px),
        linear-gradient(90deg, rgba(${hexToRgb(
          color
        )}, 0.1) 1px, transparent 1px)
      `;
    }, 100);
  }

  function hexToRgb(color) {
    // Simple HSL to RGB approximation
    return "108, 194, 74";
  }

  // ============================================
  // PRODUCT CARD TILT EFFECT
  // ============================================
  const productCards = document.querySelectorAll(".product-card");

  productCards.forEach((card) => {
    card.addEventListener("mousemove", (e) => {
      const rect = card.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;

      const centerX = rect.width / 2;
      const centerY = rect.height / 2;

      const rotateX = (y - centerY) / 20;
      const rotateY = (centerX - x) / 20;

      card.style.transform = `translateY(-10px) perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) scale(1.05)`;
    });

    card.addEventListener("mouseleave", () => {
      card.style.transform =
        "translateY(0) perspective(1000px) rotateX(0) rotateY(0) scale(1)";
    });
  });

  // ============================================
  // ADD ACTIVE STATE TO NAVIGATION LINKS
  // ============================================
  const sections = document.querySelectorAll("section[id]");

  window.addEventListener("scroll", () => {
    let current = "";

    sections.forEach((section) => {
      const sectionTop = section.offsetTop;
      const sectionHeight = section.clientHeight;

      if (window.pageYOffset >= sectionTop - 100) {
        current = section.getAttribute("id");
      }
    });

    document.querySelectorAll(".nav-link").forEach((link) => {
      link.classList.remove("active");
      if (link.getAttribute("href") === `#${current}`) {
        link.classList.add("active");
      }
    });
  });

  // ============================================
  // LOADING ANIMATION
  // ============================================
  window.addEventListener("load", () => {
    document.body.style.opacity = "0";
    setTimeout(() => {
      document.body.style.transition = "opacity 0.5s ease";
      document.body.style.opacity = "1";
    }, 100);
  });

  // ============================================
  // ANIMATED PARTICLES IN HERO SECTION
  // ============================================
  const particlesContainer = document.querySelector(".particles");

  if (particlesContainer) {
    // Create multiple particles
    for (let i = 0; i < 30; i++) {
      const particle = document.createElement("div");
      particle.className = "particle";

      const size = Math.random() * 4 + 2;
      const leftPosition = Math.random() * 100;
      const animationDuration = Math.random() * 8 + 6;
      const animationDelay = Math.random() * 5;

      particle.style.cssText = `
        position: absolute;
        width: ${size}px;
        height: ${size}px;
        background: var(--primary-color);
        border-radius: 50%;
        left: ${leftPosition}%;
        bottom: -10px;
        opacity: 0;
        animation: particleRise ${animationDuration}s ${animationDelay}s infinite ease-in-out;
        box-shadow: 0 0 10px rgba(108, 194, 74, 0.5);
      `;

      particlesContainer.appendChild(particle);
    }

    // Add particle rise animation
    const style = document.createElement("style");
    style.textContent = `
      @keyframes particleRise {
        0% {
          transform: translateY(0) translateX(0) scale(0);
          opacity: 0;
        }
        10% {
          opacity: 0.6;
        }
        90% {
          opacity: 0.3;
        }
        100% {
          transform: translateY(-100vh) translateX(${
            Math.random() * 100 - 50
          }px) scale(1.5);
          opacity: 0;
        }
      }
    `;
    document.head.appendChild(style);
  }

  // ============================================
  // TOOL ICONS INTERACTIVE MOVEMENT
  // ============================================
  const toolIcons = document.querySelectorAll(".tool-icon");

  window.addEventListener("mousemove", (e) => {
    const mouseX = e.clientX / window.innerWidth;
    const mouseY = e.clientY / window.innerHeight;

    toolIcons.forEach((tool, index) => {
      const speed = (index + 1) * 5;
      const x = (mouseX - 0.5) * speed;
      const y = (mouseY - 0.5) * speed;

      tool.style.transform = `translate(${x}px, ${y}px) rotate(${x * 2}deg)`;
    });
  });

  // ============================================
  // HERO CONTENT BOX - CURSOR TRACKING EFFECT
  // ============================================
  const heroContent = document.querySelector(".hero-content");

  if (heroContent) {
    heroContent.addEventListener("mousemove", (e) => {
      const rect = heroContent.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;

      const centerX = rect.width / 2;
      const centerY = rect.height / 2;

      const rotateX = (y - centerY) / 30;
      const rotateY = (centerX - x) / 30;

      heroContent.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) scale(1.02)`;
    });

    heroContent.addEventListener("mouseleave", () => {
      heroContent.style.transform =
        "perspective(1000px) rotateX(0) rotateY(0) scale(1)";
    });
  }

  console.log(
    "🔨 Vega Tools and Hardwares - Landing page loaded successfully!"
  );
});
