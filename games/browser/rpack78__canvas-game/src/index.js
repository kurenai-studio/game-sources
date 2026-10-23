const canvas = document.querySelector('canvas')
canvas.width = innerWidth
canvas.height = innerHeight

const c = canvas.getContext('2d')
const friction = 0.99

class Player {
    constructor(x, y, radius, color) {
        this.x = x
        this.y = y
        this.radius = radius
        this.color = color
    }

    draw() {
        c.beginPath()
        c.arc(this.x, this.y, this.radius, 0, Math.PI * 2, false)
        c.fillStyle = this.color
        c.fill()
    }
}

class Projectile {
    constructor(x, y, radius, color, velocity) {
        this.x = x
        this.y = y
        this.radius = radius
        this.color = color
        this.velocity = velocity
    }

    draw() {
        c.beginPath()
        c.arc(this.x, this.y, this.radius, 0, Math.PI * 2, false)
        c.fillStyle = this.color
        c.fill()
    }

    update() {
        this.draw()
        this.x = this.x + this.velocity.x
        this.y = this.y + this.velocity.y
    }
}

class Enemy {
    constructor(x, y, radius, color, velocity) {
        this.x = x
        this.y = y
        this.radius = radius
        this.color = color
        this.velocity = velocity
    }

    draw() {
        c.beginPath()
        c.arc(this.x, this.y, this.radius, 0, Math.PI * 2, false)
        c.fillStyle = this.color
        c.fill()
    }

    update() {
        this.draw()
        this.x = this.x + this.velocity.x
        this.y = this.y + this.velocity.y
    }
}

class Particle {
    constructor(x, y, radius, color, velocity) {
        this.x = x
        this.y = y
        this.radius = radius
        this.color = color
        this.velocity = velocity
        this.alpha = 1
    }

    draw() {
        c.save()
        c.globalAlpha = this.alpha
        c.beginPath()
        c.arc(this.x, this.y, this.radius, 0, Math.PI * 2, false)
        c.fillStyle = this.color
        c.fill()
        c.restore()
    }

    update() {
        this.draw()
        this.velocity.x *= friction
        this.velocity.y *= friction
        this.x += this.velocity.x
        this.y += this.velocity.y
        this.alpha -= .005
    }
}

const x = canvas.width / 2
const y = canvas.height / 2
const projectiles = []
const enemies = []
const particles = []
const player = new Player(x, y, 10, 'white')
const projectileSpeed = 6
const particleSpeed = 4

function spawnEnemies() {
    // Create an enemy every second, spawned from a random position outside of the canvas
    setInterval(() => {
        let x, y
        const radius = Math.random() * (30 - 6) + 6

        if (Math.random() < 0.5) {
            x = Math.random() < 0.5 ? 0 - radius : canvas.width + radius
            y = Math.random() * canvas.height
        } else {
            x = Math.random() * canvas.width
            y = Math.random() < 0.5 ? 0 - radius : canvas.height + radius
        }

        const angle = Math.atan2(player.y - y, player.x - x)
        enemies.push(new Enemy(x, y, radius, `hsl(${Math.random() * 359}, 50%, 50%)`, {
            x: Math.cos(angle),
            y: Math.sin(angle)
        }))
    }, 1000);
}

addEventListener('click', (event) => {
    // Create a projectile and send it on its way
    const angle = Math.atan2(event.clientY - player.y, event.clientX - player.x)
    projectiles.push(new Projectile(player.x, player.y, 4, 'white', {
        x: Math.cos(angle) * projectileSpeed,
        y: Math.sin(angle) * projectileSpeed
    }))
})

let animationID
function animate() {
    animationID = requestAnimationFrame(animate)
    c.fillStyle = 'rgba(0, 0, 0, 0.3'
    c.fillRect(0, 0, canvas.width, canvas.height)
    player.draw()
    projectiles.forEach((projectile, index) => {
        // Detect projectile leaving the canvas
        if (projectile.x < 0 - projectile.radius ||
            projectile.x > canvas.width + projectile.radius ||
            projectile.y < 0 - projectile.radius ||
            projectile.y > canvas.height + projectile.radius) {
            setTimeout(() => {
                projectiles.splice(index, 1)
            }, 0);
        }
        projectile.update()
    })

    enemies.forEach((enemy, enemyIndex) => {
        // Detect enemy leaving the canvas
        if (enemy.x < 0 - enemy.radius ||
            enemy.x > canvas.width + enemy.radius ||
            enemy.y < 0 - enemy.radius ||
            enemy.y > canvas.height + enemy.radius) {
            setTimeout(() => {
                enemies.splice(enemyIndex, 1)
            }, 0);
        }

        // Detect collision between player and enemy
        const dist = Math.hypot(player.x - enemy.x, player.y - enemy.y)
        if (dist - player.radius - enemy.radius < 1) {
            // cancelAnimationFrame(animationID)
        }
        // Detect collision between projectile and enemy
        projectiles.forEach((projectile, projectileIndex) => {
            const dist = Math.hypot(projectile.x - enemy.x, projectile.y - enemy.y)
            if (dist - projectile.radius - enemy.radius < 1) {

                // Spawn particles to create an explosion
                for (let i = 0; i < enemy.radius * 1.5; i++) {
                    particles.push(new Particle(enemy.x, enemy.y, Math.random() * 3, enemy.color, {
                        x: (Math.random() - 0.5) * particleSpeed,
                        y: (Math.random() - 0.5) * particleSpeed
                    }))
                }
                if (enemy.radius - 10 > 5) {
                    // Shrink large enemy
                    gsap.to(enemy, {
                        radius: enemy.radius - 10
                    })
                    setTimeout(() => {
                        projectiles.splice(projectileIndex, 1)
                    }, 0);
                } else {
                    // Destroy enemy
                    setTimeout(() => {
                        enemies.splice(enemyIndex, 1)
                        projectiles.splice(projectileIndex, 1)
                    }, 0);
                }
            }
        })
        enemy.update()
        particles.forEach((particle, index) => {
            if (particle.alpha <= 0) {
                particles.splice(index, 1)
            } else {
                particle.update()
            }
        })
    })
}
animate()
spawnEnemies()
