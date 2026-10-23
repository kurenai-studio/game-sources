
const themes = {
    fruits: {
        type: 'image',
        path: 'themes/fruits/',
        values: {
            2: 'cherry-256x256.png',
            4: 'strawberry-256x256.png',
            8: 'grape-256x256.png',
            16: 'lemon-256x256.png',
            32: 'orange-256x256.png',
            64: 'apple-256x256.png',
            128: 'pear-256x256.png',
            256: 'peach-256x256.png',
            512: 'melon-256x256.png',
            1024: 'watermelon-256x256.png',
            2048: 'watermelon-256x256.png'
        },
        background: '#f0fff0' // Light mint background for fruit tiles
    },
    numbers: {
        type: 'image',
        path: 'themes/numbers/', // Set the path for this theme's images
        values: {
            2: 'placeholder_2.png',
            4: 'placeholder_4.png',
            8: 'placeholder_8.png',
            16: 'placeholder_16.png',
            32: 'placeholder_32.png',
            64: 'placeholder_64.png',
            128: 'placeholder_128.png',
            256: 'placeholder_256.png',
            512: 'placeholder_512.png',
            1024: 'placeholder_1024.png',
            2048: 'placeholder_2048.png'
        },
        background: '#f5f5dc' //     Light beige background for all tiles
    },
    classic: {
        type: 'color',
        values: {
            2: '#eee4da', 4: '#ece0ca', 8: '#f4b17a', 16: '#f59575', 32: '#f57c5f', 64: '#f65d3b', 128: '#edce71', 256: '#edcc63', 512: '#edc651', 1024: '#eec744', 2048: '#ecc230'
        }
    },
    pastel: {
        type: 'color',
        values: {
            2: '#fce4ec', 4: '#f8bbd0', 8: '#e1bee7', 16: '#d1c4e9', 32: '#b3e5fc', 64: '#b2ebf2', 128: '#c8e6c9', 256: '#dcedc8', 512: '#fff9c4', 1024: '#ffe0b2', 2048: '#ffccbc'
        }
    },
    neon: {
        type: 'color',
        values: {
            2: '#39ff14', 4: '#faff00', 8: '#ff073a', 16: '#00f0ff', 32: '#ff00ea', 64: '#ff9000', 128: '#00ff90', 256: '#ff2a00', 512: '#00bfff', 1024: '#ff00c8', 2048: '#fffd37'
        }
    },
    ocean: {
        type: 'color',
        values: {
            2: '#a7ffeb', 4: '#64ffda', 8: '#1de9b6', 16: '#00bfae', 32: '#00b8d4', 64: '#0091ea', 128: '#00bcd4', 256: '#18ffff', 512: '#84ffff', 1024: '#b2ebf2', 2048: '#e0f7fa'
        }
    },
    dark: {
        type: 'color',
        values: {
            2: '#222831', 4: '#393e46', 8: '#00adb5', 16: '#007c7c', 32: '#393e46', 64: '#222831', 128: '#393e46', 256: '#00adb5', 512: '#007c7c', 1024: '#393e46', 2048: '#222831'
        }
    },
    fruits: {
        type: 'image',
        path: 'themes/fruits/',
        values: {
            2: 'cherry-256x256.png',
            4: 'strawberry-256x256.png',
            8: 'grape-256x256.png',
            16: 'lemon-256x256.png',
            32: 'orange-256x256.png',
            64: 'apple-256x256.png',
            128: 'pear-256x256.png',
            256: 'peach-256x256.png',
            512: 'melon-256x256.png',
            1024: 'watermelon-256x256.png',
            2048: 'watermelon-256x256.png'
        },
        background: '#f0fff0' // Light mint background for fruit tiles
    },
    numbers: {
        type: 'image',
        path: 'themes/numbers/', // Set the path for this theme's images
        values: {
            2: 'placeholder_2.png',
            4: 'placeholder_4.png',
            8: 'placeholder_8.png',
            16: 'placeholder_16.png',
            32: 'placeholder_32.png',
            64: 'placeholder_64.png',
            128: 'placeholder_128.png',
            256: 'placeholder_256.png',
            512: 'placeholder_512.png',
            1024: 'placeholder_1024.png',
            2048: 'placeholder_2048.png'
        },
        background: '#f5f5dc' // Light beige background for all tiles
    }
};

let currentTheme = 'fruits';

function renderThemeButtons() {
    const themesList = Object.keys(themes);
    const btnsDiv = document.getElementById('theme-buttons');
    btnsDiv.innerHTML = '';
    
    const currentThemeDisplay = document.getElementById('current-theme');
    if (currentThemeDisplay) {
        currentThemeDisplay.textContent = currentTheme.charAt(0).toUpperCase() + currentTheme.slice(1);
    }
    
    themesList.forEach(themeName => {
        const theme = themes[themeName];
        const btn = document.createElement('button');
        btn.className = 'theme-btn' + (currentTheme === themeName ? ' selected' : '');
        btn.type = 'button';
        btn.onclick = () => {
            currentTheme = themeName;
            renderThemeButtons();
            drawBoard();
        };
        btn.innerHTML = `<span>${themeName.charAt(0).toUpperCase() + themeName.slice(1)}</span>`;
        
        const swatches = document.createElement('span');
        swatches.className = 'theme-swatches';
        
        const sampleValues = [2, 8, 32, 128];
        
        if (theme.type === 'color') {
            sampleValues.forEach(val => {
                const swatch = document.createElement('span');
                swatch.className = 'theme-swatch';
                swatch.style.backgroundColor = theme.values[val];
                swatches.appendChild(swatch);
            });
        } else if (theme.type === 'image') {
            sampleValues.forEach(val => {
                if (!theme.values[val]) return;
                const swatch = document.createElement('span');
                swatch.className = 'theme-swatch';
                
                const img = document.createElement('img');
                img.className = 'theme-swatch-image';
                const imagePath = (theme.path || 'images/') + theme.values[val];
                img.src = imagePath;
                img.alt = val;

                swatch.appendChild(img);
                swatches.appendChild(swatch);
            });
        }
        
        btn.appendChild(swatches);
        btnsDiv.appendChild(btn);
    });
}

function createCustomTheme(name, type, values, background) {
    if (!name || !type || !values) {
        console.error('Missing required parameters for custom theme');
        return false;
    }
    
    if (themes[name]) {
        console.warn(`Theme '${name}' already exists and will be overwritten`);
    }
    
    themes[name] = {
        type: type,
        values: values
    };
    
    if (type === 'image' && background) {
        themes[name].background = background;
    }
    
    renderThemeButtons();
    
    currentTheme = name;
    drawBoard();
    
    return true;
}
