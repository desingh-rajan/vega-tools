import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    interval: { type: Number, default: 5000 },
  };

  connect() {
    this.currentIndex = 0;
    this.slides = this.element.querySelectorAll(".carousel-slide");
    this.dots = this.element.querySelectorAll(".carousel-dot");
    this.autoPlayInterval = null;

    // Only run carousel if we have multiple slides
    if (this.slides.length <= 1) {
      // Hide navigation if only one slide
      const arrows = this.element.querySelectorAll(".carousel-arrow");
      const dots = this.element.querySelector(".carousel-dots");
      const progress = this.element.querySelector(".carousel-progress");
      arrows.forEach((arrow) => (arrow.style.display = "none"));
      if (dots) dots.style.display = "none";
      if (progress) progress.style.display = "none";
      return;
    }

    // Ensure first slide is active
    this.slides[0].classList.add("active");
    if (this.dots[0]) this.dots[0].classList.add("active");

    // Start auto-play
    this.startAutoPlay();

    // Pause on hover
    this.element.addEventListener("mouseenter", () => this.pauseAutoPlay());
    this.element.addEventListener("mouseleave", () => this.startAutoPlay());

    // Touch/swipe support
    this.setupTouchEvents();

    // Keyboard navigation
    this.boundHandleKeyboard = this.handleKeyboard.bind(this);
    document.addEventListener("keydown", this.boundHandleKeyboard);
  }

  disconnect() {
    this.pauseAutoPlay();
    if (this.boundHandleKeyboard) {
      document.removeEventListener("keydown", this.boundHandleKeyboard);
    }
  }

  next() {
    if (this.slides.length <= 1) return;
    this.goTo((this.currentIndex + 1) % this.slides.length);
    this.resetAutoPlay();
  }

  prev() {
    if (this.slides.length <= 1) return;
    this.goTo(
      (this.currentIndex - 1 + this.slides.length) % this.slides.length
    );
    this.resetAutoPlay();
  }

  goToSlide(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10);
    if (!isNaN(index)) {
      this.goTo(index);
      this.resetAutoPlay();
    }
  }

  goTo(index) {
    if (index < 0 || index >= this.slides.length) return;
    if (index === this.currentIndex) return;

    // Remove active class from current
    this.slides[this.currentIndex].classList.remove("active");
    if (this.dots[this.currentIndex]) {
      this.dots[this.currentIndex].classList.remove("active");
    }

    // Update index
    this.currentIndex = index;

    // Add active class to new
    this.slides[this.currentIndex].classList.add("active");
    if (this.dots[this.currentIndex]) {
      this.dots[this.currentIndex].classList.add("active");
    }

    // Reset progress animation
    this.resetProgressAnimation();
  }

  startAutoPlay() {
    this.pauseAutoPlay();
    this.autoPlayInterval = setInterval(() => this.next(), this.intervalValue);
    this.resetProgressAnimation();
  }

  pauseAutoPlay() {
    if (this.autoPlayInterval) {
      clearInterval(this.autoPlayInterval);
      this.autoPlayInterval = null;
    }
  }

  resetAutoPlay() {
    this.pauseAutoPlay();
    this.startAutoPlay();
  }

  resetProgressAnimation() {
    const progress = this.element.querySelector(".carousel-progress");
    if (progress) {
      progress.style.animation = "none";
      progress.offsetHeight; // Trigger reflow
      progress.style.animation = `carouselProgress ${this.intervalValue}ms linear infinite`;
    }
  }

  setupTouchEvents() {
    let touchStartX = 0;
    let touchEndX = 0;

    this.element.addEventListener(
      "touchstart",
      (e) => {
        touchStartX = e.changedTouches[0].screenX;
      },
      { passive: true }
    );

    this.element.addEventListener(
      "touchend",
      (e) => {
        touchEndX = e.changedTouches[0].screenX;
        this.handleSwipe(touchStartX, touchEndX);
      },
      { passive: true }
    );
  }

  handleSwipe(startX, endX) {
    const swipeThreshold = 50;
    const diff = startX - endX;

    if (Math.abs(diff) > swipeThreshold) {
      if (diff > 0) {
        // Swipe left - go to next
        this.next();
      } else {
        // Swipe right - go to prev
        this.prev();
      }
    }
  }

  handleKeyboard(event) {
    // Only handle if this carousel is visible in viewport
    const rect = this.element.getBoundingClientRect();
    const isVisible = rect.top < window.innerHeight && rect.bottom > 0;

    if (!isVisible) return;

    if (event.key === "ArrowLeft") {
      this.prev();
    } else if (event.key === "ArrowRight") {
      this.next();
    }
  }
}
