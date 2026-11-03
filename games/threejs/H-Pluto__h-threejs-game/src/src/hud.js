/**
 * hud.js — HUD管理器
 * 更新生命条、得分、连击显示
 */

export class HUD {
    constructor() {
        // 获取DOM元素
        this.healthFill = document.getElementById('health-bar-fill');
        this.healthText = document.getElementById('health-text');
        this.scoreValue = document.getElementById('score-value');
        this.comboCount = document.getElementById('combo-count');
        this.comboLabel = document.getElementById('combo-label');
        this.message = document.getElementById('message');

        /** 得分 */
        this.score = 0;

        /** 连击显示计时 */
        this.comboShowTimer = 0;
    }

    /**
     * 更新生命值显示
     * @param {number} hp
     * @param {number} maxHp
     */
    updateHealth(hp, maxHp) {
        const percent = Math.max(0, hp / maxHp * 100);
        this.healthFill.style.width = `${percent}%`;
        this.healthText.textContent = `${Math.ceil(hp)}/${maxHp}`;

        // 低生命时血条脉冲
        if (percent < 30) {
            this.healthFill.style.background =
                `linear-gradient(180deg, #ff2222 ${Math.sin(Date.now() / 200) * 20 + 40}%, #880000 100%)`;
        } else {
            this.healthFill.style.background = 'linear-gradient(180deg, #ff4444 0%, #aa1111 100%)';
        }
    }

    /**
     * 更新得分
     * @param {number} points - 增加的分值
     */
    addScore(points) {
        this.score += points;
        this.scoreValue.textContent = this.score;
        // 数字跳动效果
        this.scoreValue.style.transform = 'scale(1.2)';
        setTimeout(() => {
            this.scoreValue.style.transform = 'scale(1)';
        }, 100);
    }

    /**
     * 更新连击显示
     * @param {number} combo
     */
    updateCombo(combo) {
        if (combo > 1) {
            this.comboCount.textContent = `x${combo}`;
            this.comboCount.classList.add('active');
            this.comboLabel.classList.add('active');
            this.comboShowTimer = 1.5;

            // 高连击时颜色变化
            if (combo >= 10) {
                this.comboCount.style.color = '#ff0000';
                this.comboCount.style.fontSize = '60px';
                this.comboCount.style.textShadow = '0 0 30px rgba(255,0,0,0.9)';
            } else if (combo >= 5) {
                this.comboCount.style.color = '#ff4400';
                this.comboCount.style.fontSize = '52px';
            } else {
                this.comboCount.style.color = '#ff6600';
                this.comboCount.style.fontSize = '48px';
            }
        } else {
            this.comboShowTimer -= 0.016;
            if (this.comboShowTimer <= 0) {
                this.comboCount.classList.remove('active');
                this.comboLabel.classList.remove('active');
            }
        }
    }

    /**
     * 显示消息
     * @param {string} text
     * @param {number} duration - 显示秒数
     */
    showMessage(text, duration = 2.0) {
        this.message.textContent = text;
        this.message.classList.add('visible');
        clearTimeout(this._msgTimeout);
        this._msgTimeout = setTimeout(() => {
            this.message.classList.remove('visible');
        }, duration * 1000);
    }

    /**
     * 每帧更新
     */
    update(dt) {
        // 连击递减（在player中处理，这里只做显示平滑）
    }

    /**
     * 重置HUD
     */
    reset() {
        this.score = 0;
        this.scoreValue.textContent = '0';
        this.scoreValue.style.transform = 'scale(1)';
        this.updateHealth(100, 100);
        this.comboCount.classList.remove('active');
        this.comboLabel.classList.remove('active');
        this.comboCount.style.color = '#ff6600';
        this.comboCount.style.fontSize = '48px';
        this.message.classList.remove('visible');
    }
}
