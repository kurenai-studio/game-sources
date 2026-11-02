(function () {
    "use strict";

    function escapeText(value) {
        return String(value == null ? "" : value).replace(/[&<>"']/g, function (char) {
            return {
                "&": "&amp;",
                "<": "&lt;",
                ">": "&gt;",
                "\"": "&quot;",
                "'": "&#39;"
            }[char];
        });
    }

    function scoreUrl(widget) {
        var url = widget.getAttribute("data-scores-url") || "scores.php";
        var limit = widget.getAttribute("data-limit") || "5";
        var separator = url.indexOf("?") === -1 ? "?" : "&";
        return url + separator + "limit=" + encodeURIComponent(limit);
    }

    function renderNotice(widget, message) {
        widget.innerHTML =
            '<section class="engagedsnake-score-widget">' +
            '<h2 class="engagedsnake-score-widget__title">' + escapeText(widget.getAttribute("data-title") || "Top Scores") + '</h2>' +
            '<p class="engagedsnake-score-widget__notice">' + escapeText(message) + '</p>' +
            '</section>';
    }

    function renderScores(widget, scores) {
        var title = widget.getAttribute("data-title") || "Top Scores";
        if (!scores.length) {
            renderNotice(widget, "No scores yet.");
            return;
        }

        var rows = scores.map(function (score, index) {
            return (
                '<li class="engagedsnake-score-widget__row">' +
                '<span class="engagedsnake-score-widget__rank">' + (index + 1) + '</span>' +
                '<span class="engagedsnake-score-widget__player">' + escapeText(score.player_name || "PLY") + '</span>' +
                '<span class="engagedsnake-score-widget__score">' + Number(score.score || 0).toLocaleString() + '</span>' +
                '<span class="engagedsnake-score-widget__victory">' + (score.victory ? "*" : "") + '</span>' +
                '</li>'
            );
        }).join("");

        widget.innerHTML =
            '<section class="engagedsnake-score-widget">' +
            '<h2 class="engagedsnake-score-widget__title">' + escapeText(title) + '</h2>' +
            '<ol class="engagedsnake-score-widget__list">' + rows + '</ol>' +
            '</section>';
    }

    function loadWidget(widget) {
        renderNotice(widget, "Loading scores...");
        fetch(scoreUrl(widget), { headers: { "Accept": "application/json" } })
            .then(function (response) {
                if (!response.ok) {
                    throw new Error("HTTP " + response.status);
                }
                return response.json();
            })
            .then(function (data) {
                if (!data || data.ok !== true || !Array.isArray(data.scores)) {
                    throw new Error("Invalid score response");
                }
                renderScores(widget, data.scores.slice(0, Number(widget.getAttribute("data-limit") || 5)));
            })
            .catch(function () {
                renderNotice(widget, "Scores are unavailable.");
            });
    }

    function init() {
        document.querySelectorAll("[data-engagedsnake-score-widget]").forEach(loadWidget);
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", init);
    } else {
        init();
    }
}());
