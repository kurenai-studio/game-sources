(function () {
  "use strict";

  var saveDirs = [
    "/home/web_user/love/divadelni-utopie",
    "/home/web_user/.local/share/love/divadelni-utopie",
    "/home/web_user/love",
  ];
  var outboxName = "online_score_outbox.json";
  var statusName = "online_score_status.json";
  var active = {};
  var timer = null;

  function textDecoder() {
    return new TextDecoder("utf-8");
  }

  function textEncoder() {
    return new TextEncoder();
  }

  function hasFs(module) {
    return module && module.FS_readFile && module.FS_writeFile && module.FS_analyzePath;
  }

  function pathJoin(dir, name) {
    return dir.replace(/\/$/, "") + "/" + name;
  }

  function existingPath(module, path) {
    try {
      return module.FS_analyzePath(path).exists;
    } catch (error) {
      return false;
    }
  }

  function readJson(module, path) {
    try {
      var bytes = module.FS_readFile(path);
      return JSON.parse(textDecoder().decode(bytes));
    } catch (error) {
      return null;
    }
  }

  function writeJson(module, path, value) {
    try {
      module.FS_writeFile(path, textEncoder().encode(JSON.stringify(value)));
      if (module.FS_syncfs) {
        module.FS_syncfs(false, function () {});
      }
    } catch (error) {
      console.error("score bridge write failed", error);
    }
  }

  function removeFile(module, path) {
    try {
      module.FS_unlink(path);
    } catch (error) {
      // File may already be gone; that is fine.
    }
  }

  function bodyFromRequest(request) {
    var body = new URLSearchParams();
    body.set("password", request.password || "");
    body.set("player_name", request.fields && request.fields.player_name || "PLY");
    body.set("score", request.fields && request.fields.score || 0);
    body.set("level_ended", request.fields && request.fields.level_ended || 1);
    body.set("victory", request.fields && request.fields.victory ? 1 : 0);
    return body;
  }

  function submit(module, request, outboxPath, statusPath) {
    if (!request || !request.id || !request.endpoint || active[request.id]) {
      return;
    }

    active[request.id] = true;
    fetch(request.endpoint, {
      method: "POST",
      mode: "cors",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
      },
      body: bodyFromRequest(request),
    }).then(function (response) {
      return response.text().then(function (text) {
        var json = {};
        try {
          json = text ? JSON.parse(text) : {};
        } catch (error) {
          json = {};
        }
        if (!response.ok || json.ok !== true) {
          throw new Error(json.error || ("http_" + response.status));
        }
        writeJson(module, statusPath, { id: request.id, ok: true });
        removeFile(module, outboxPath);
      });
    }).catch(function (error) {
      writeJson(module, statusPath, {
        id: request.id,
        ok: false,
        error: error && error.message ? error.message : "web_upload_failed",
      });
    }).finally(function () {
      delete active[request.id];
    });
  }

  function poll(module) {
    if (!hasFs(module)) {
      return;
    }

    for (var index = 0; index < saveDirs.length; index += 1) {
      var outboxPath = pathJoin(saveDirs[index], outboxName);
      if (existingPath(module, outboxPath)) {
        submit(module, readJson(module, outboxPath), outboxPath, pathJoin(saveDirs[index], statusName));
      }
    }
  }

  window.DivadelniScoreBridge = {
    start: function (module) {
      if (timer) {
        return;
      }
      timer = window.setInterval(function () {
        poll(module);
      }, 750);
      poll(module);
    },
  };
}());
