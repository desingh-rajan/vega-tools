import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["slide", "dot", "progress"];

  connect() {
    this.currentIndex = 0;
    this.slides = this.element.querySelectorAll(".carousel-slide");
    this.dots = this.element.querySelectorAll(".carousel-dot");
    this.autoPlayInterval = null;
    this.progressAnimation = null;

    // Start auto-play
    this.startAutoPlay();

    // Pause on hover
    this.element.addEventListener("mouseenter", () => this.pauseAutoPlay());
    this.element.addEventListener("mouseleave", () => this.startAutoPlay());

    // Keyboard navigation
    document.addEventListener("keydown", (e) => this.handleKeyboard(e));
  }

  disconnect() {
    this.pauseAutoPlay();
    document.removeEventListener("keydown", this.handleKeyboard);
  }

  next() {
    this.goTo((this.currentIndex + 1) % this.slides.length);
    this.resetAutoPlay();
  }

  prev() {
    this.goTo(
      (this.currentIndex - 1 + this.slides.length) % this.slides.length
    );
    this.resetAutoPlay();
  }

  goToSlide(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10);
    this.goTo(index);
    this.resetAutoPlay();
  }

  goTo(index) {
    // Remove active class from current
    this.slides[this.currentIndex].classList.remove("active");
    this.dots[this.currentIndex].classList.remove("active");

    // Update index
    this.currentIndex = index;

    // Add active class to new
    this.slides[this.currentIndex].classList.add("active");
    this.dots[this.currentIndex].classList.add("active");
  }

  startAutoPlay() {
    this.pauseAutoPlay();
    this.autoPlayInterval = setInterval(() => this.next(), 5000);
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
      progress.style.animation = "carouselProgress 5s linear infinite";
    }
  }

  handleKeyboard(event) {
    if (event.key === "ArrowLeft") {
      this.prev();
    } else if (event.key === "ArrowRight") {
      this.next();
    }
  }
}
