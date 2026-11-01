/**
 * Adds a starfield background to the body element.
 * @param count - The number of stars to generate.
 */
export function addStars(count: number) {
  const gradients = Array.from({ length: count }, () => {
    const x = (Math.random() * 100).toFixed(1)
    const y = (Math.random() * 100).toFixed(1)
    const size = (Math.random() * 1 + 0.5).toFixed(1)
    const opacity = (Math.random() * 0.6 + 0.4).toFixed(2)
    return `radial-gradient(${size}px ${size}px at ${x}% ${y}%, rgba(210, 220, 255, ${opacity}) 0%, transparent 100%)`
  })

  document.body.style.backgroundImage = gradients.join(', ')
}
