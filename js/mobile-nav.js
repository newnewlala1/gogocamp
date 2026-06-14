(function () {
  var headerInner = document.querySelector('.header-inner');
  if (!headerInner) return;
  var nav = headerInner.querySelector('nav');
  if (!nav) return;

  // 햄버거 버튼 동적 삽입 (CSS가 표시 여부 제어)
  var button = document.createElement('button');
  button.className = 'mobile-menu-toggle';
  button.setAttribute('aria-label', '메뉴 열기');
  button.setAttribute('aria-expanded', 'false');
  button.innerHTML = '<span></span><span></span><span></span>';

  headerInner.insertBefore(button, nav);

  // 초기 상태: 모바일에서 접혀있음
  nav.classList.add('mobile-collapsed');

  function toggle() {
    var collapsed = nav.classList.toggle('mobile-collapsed');
    button.classList.toggle('active', !collapsed);
    button.setAttribute('aria-expanded', String(!collapsed));
    button.setAttribute('aria-label', collapsed ? '메뉴 열기' : '메뉴 닫기');
  }

  button.addEventListener('click', toggle);

  // 메뉴 항목 클릭 시 자동 닫기 (모바일)
  nav.querySelectorAll('a').forEach(function (a) {
    a.addEventListener('click', function () {
      if (window.innerWidth <= 768 && !nav.classList.contains('mobile-collapsed')) {
        nav.classList.add('mobile-collapsed');
        button.classList.remove('active');
        button.setAttribute('aria-expanded', 'false');
        button.setAttribute('aria-label', '메뉴 열기');
      }
    });
  });

  // 화면 리사이즈 시 데스크탑으로 전환되면 상태 초기화
  window.addEventListener('resize', function () {
    if (window.innerWidth > 768) {
      nav.classList.remove('mobile-collapsed');
      button.classList.remove('active');
    } else if (!nav.classList.contains('mobile-collapsed') && !button.classList.contains('active')) {
      nav.classList.add('mobile-collapsed');
    }
  });
})();
