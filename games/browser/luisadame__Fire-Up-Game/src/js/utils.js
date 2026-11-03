export function rand(min, max) {
    return Math.floor(Math.random() * max) + min;
}

export function collides(a, b) {
    return a.x < b.x + b.w &&
        a.x + a.w > b.x &&
        a.y < b.y + b.h &&
        a.y + a.h > b.h;
}

export function escape(str) {
    str = str.replace(/&/g, "&amp;");
    str = str.replace(/</g, "&lt;");
    str = str.replace(/>/g, "&gt;");
    str = str.replace(/"/g, "&quto;");
    str = str.replace(/'/g, "&#39;");
    str = str.replace(/`/g, "&#96;");
    str = str.replace(/\//g, "&#x2F;");
    return str
}
