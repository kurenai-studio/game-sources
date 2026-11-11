// MC.about: in-game About screen (uses the How-To doc renderer).
(function initAboutModule() {
  var A = MC.about;

  A.ctrl = MC.controls.newState();
  A.st = {
    pageI: 0,
    scrollByPage: [],
    layoutByPage: null,
    layoutForN: 0
  };

  A.tick = function (raw) {
    return MC.howto.tickDocScreen(raw, {
      content: A.CONTENT,
      st: A.st,
      ctrl: A.ctrl,
      headerTitle: "About",
      showPageCount: false,
      allowPaging: false,
      intentBack: { kind: "backToTitle" }
    });
  };
})();

