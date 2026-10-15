// 캠핑장 비교함 공통 로직
// localStorage 키: gogocamp_compare

(function(){
    'use strict';
    const STORAGE_KEY = 'gogocamp_compare';
    const MAX_COMPARE = 3;
    let dataCache = null;

    // ========= 공용 함수 =========
    function getList(){
        try {
            const raw = localStorage.getItem(STORAGE_KEY);
            return raw ? JSON.parse(raw) : [];
        } catch(e){ return []; }
    }
    function saveList(list){
        try {
            localStorage.setItem(STORAGE_KEY, JSON.stringify(list));
        } catch(e){}
    }
    window.gogoCompare = {
        add: function(id, name, sido, sigungu){
            const list = getList();
            if(list.find(x => x.id === id)) return {ok:false, reason:'already'};
            if(list.length >= MAX_COMPARE) return {ok:false, reason:'full'};
            list.push({id: id, name: name, sido: sido || '', sigungu: sigungu || ''});
            saveList(list);
            renderFloatBar();
            return {ok:true};
        },
        remove: function(id){
            let list = getList().filter(x => x.id !== id);
            saveList(list);
            renderFloatBar();
            if(window.renderCompareTable) window.renderCompareTable();
        },
        has: function(id){ return !!getList().find(x => x.id === id); },
        clear: function(){
            saveList([]);
            renderFloatBar();
            if(window.renderCompareTable) window.renderCompareTable();
        },
        list: getList,
        max: MAX_COMPARE
    };

    // ========= 플로팅 바 =========
    function renderFloatBar(){
        const list = getList();
        let bar = document.getElementById('cmpFloatBar');
        if(list.length === 0){
            if(bar) bar.remove();
            return;
        }
        if(!bar){
            bar = document.createElement('div');
            bar.id = 'cmpFloatBar';
            bar.style.cssText = 'position:fixed;bottom:0;left:0;right:0;background:#059669;color:#fff;padding:12px 16px;display:flex;align-items:center;justify-content:space-between;gap:12px;z-index:9999;box-shadow:0 -4px 12px rgba(0,0,0,0.1);font-size:0.9rem';
            document.body.appendChild(bar);
        }
        const names = list.map(x => x.name).slice(0,3).join(' · ');
        bar.innerHTML = '<div style="flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">📋 비교함 <strong>' + list.length + '</strong>곳: ' + escapeHtml(names) + '</div>' +
            '<div style="display:flex;gap:8px;flex-shrink:0">' +
            '<button onclick="gogoCompare.clear()" style="background:transparent;border:1px solid #fff;color:#fff;padding:6px 10px;border-radius:6px;cursor:pointer;font-size:0.85rem">비우기</button>' +
            '<a href="compare.html" style="background:#fff;color:#059669;padding:6px 14px;border-radius:6px;text-decoration:none;font-weight:700;font-size:0.9rem">비교하기 →</a>' +
            '</div>';
    }
    function escapeHtml(s){
        return (s||'').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'})[c]);
    }

    // ========= 캠핑장 상세 페이지 — 비교함 담기 버튼 =========
    function initDetailButton(){
        const btn = document.getElementById('cmpAddBtn');
        if(!btn) return;
        const id = btn.dataset.cid;
        const name = btn.dataset.name;
        const sido = btn.dataset.sido;
        const sigungu = btn.dataset.sigungu;
        function updateBtn(){
            if(window.gogoCompare.has(id)){
                btn.textContent = '✓ 비교함에 담김';
                btn.style.background = '#065f46';
            } else {
                btn.textContent = '📋 비교함에 담기';
                btn.style.background = '#059669';
            }
        }
        btn.addEventListener('click', function(e){
            e.preventDefault();
            if(window.gogoCompare.has(id)){
                window.gogoCompare.remove(id);
            } else {
                const r = window.gogoCompare.add(id, name, sido, sigungu);
                if(!r.ok && r.reason === 'full'){
                    alert('비교함은 최대 ' + window.gogoCompare.max + '곳까지 담을 수 있습니다. 비교함 페이지에서 확인하세요.');
                }
            }
            updateBtn();
        });
        updateBtn();
    }

    // ========= 비교 테이블 페이지 =========
    const COMPARE_ROWS = [
        {cat:'기본 정보', rows:[
            {label:'유형', key:'induty'},
            {label:'입지', key:'lctCl'},
            {label:'테마', key:'theme'},
            {label:'주소', key:'address'},
            {label:'운영 기간', key:'_operation'},
            {label:'연락처', key:'tel'},
            {label:'공식 홈페이지', key:'_homepage'},
        ]},
        {cat:'사이트 규모', rows:[
            {label:'일반 야영 사이트', key:'gnrlSiteCo', num:true, better:'high'},
            {label:'오토 사이트', key:'autoSiteCo', num:true, better:'high'},
            {label:'글램핑', key:'glampSiteCo', num:true, better:'high'},
            {label:'카라반', key:'caravSiteCo', num:true, better:'high'},
            {label:'개인 카라반 사이트', key:'indvdlCaravSiteCo', num:true, better:'high'},
        ]},
        {cat:'편의 시설', rows:[
            {label:'화장실 수', key:'toiletCo', num:true, better:'high'},
            {label:'샤워실 수', key:'swrmCo', num:true, better:'high'},
            {label:'개수대 수', key:'wtrplCo', num:true, better:'high'},
            {label:'부대시설', key:'sbrsCl'},
            {label:'대여 장비', key:'eqpmnLendCl'},
        ]},
        {cat:'동반·허용', rows:[
            {label:'반려동물', key:'animalCmgCl', better:'yes'},
            {label:'카라반 동반', key:'caravAcmpnyAt', better:'y'},
            {label:'외부 텐트 반입', key:'extshrAcmpnyAt', better:'y'},
            {label:'화로/모닥불', key:'brazierCl'},
        ]},
        {cat:'활동', rows:[
            {label:'체험 프로그램', key:'exprnProgrm'},
            {label:'문화 행사', key:'clturEventAt', better:'y'},
            {label:'관광 테마', key:'tourEraCl'},
        ]},
    ];

    function fmtVal(it, row){
        if(row.key === '_operation'){
            if(it.hvofBgnde && it.hvofEnddle){
                return it.hvofBgnde + '~' + it.hvofEnddle;
            }
            return '연중 (혹은 미표기)';
        }
        if(row.key === '_homepage'){
            const h = it.homepage || '';
            if(h.startsWith('http')){
                return '<a href="' + escapeHtml(h) + '" target="_blank" rel="noopener" style="color:#059669">사이트 →</a>';
            }
            return '—';
        }
        const v = it[row.key];
        if(v === undefined || v === null || v === '') return '—';
        if(row.num){
            const n = parseInt(v, 10);
            if(isNaN(n) || n === 0) return '—';
            return n + '개';
        }
        if(row.better === 'y'){
            if(v === 'Y') return '✓ 가능';
            if(v === 'N') return '✗ 불가';
            return v;
        }
        if(row.better === 'yes'){
            const s = (v || '').toString();
            if(s.indexOf('가능') >= 0) return '✓ ' + s;
            if(s.indexOf('불가') >= 0) return '✗ ' + s;
            return s;
        }
        return escapeHtml((v || '').toString());
    }

    function isBest(items, row){
        // 각 항목에서 best index 결정
        if(row.num){
            let bestIdx = -1, bestVal = -1;
            items.forEach((it, i) => {
                const n = parseInt(it[row.key], 10);
                if(!isNaN(n) && n > bestVal){ bestVal = n; bestIdx = i; }
            });
            if(bestVal <= 0) return -1;
            // 최고가 여러 개면 best 없음
            const count = items.filter(it => parseInt(it[row.key], 10) === bestVal).length;
            return count === 1 ? bestIdx : -1;
        }
        if(row.better === 'y'){
            const yes = items.map(it => it[row.key] === 'Y');
            const yesCount = yes.filter(x => x).length;
            if(yesCount === 1) return yes.indexOf(true);
            return -1;
        }
        if(row.better === 'yes'){
            const yes = items.map(it => (it[row.key] || '').indexOf('가능') >= 0);
            const yesCount = yes.filter(x => x).length;
            if(yesCount === 1) return yes.indexOf(true);
            return -1;
        }
        return -1;
    }

    async function loadData(){
        if(dataCache) return dataCache;
        try {
            const res = await fetch('data/compare-data.json');
            dataCache = await res.json();
            return dataCache;
        } catch(e){
            console.error('data load failed', e);
            return null;
        }
    }

    window.renderCompareTable = async function(){
        const container = document.getElementById('cmpContent');
        if(!container) return;
        const list = getList();

        if(list.length === 0){
            container.innerHTML =
                '<div class="cmp-empty">' +
                '<h3>비교함이 비어있습니다</h3>' +
                '<p>관심 캠핑장을 담아보세요. 최대 ' + MAX_COMPARE + '곳까지 선택할 수 있습니다.</p>' +
                '<div class="step"><div class="step-num">1</div><div><strong>캠핑장 찾기</strong><br><span style="color:#6b7280;font-size:0.9rem">지역·유형별로 캠핑장을 찾아보세요</span></div></div>' +
                '<div class="step"><div class="step-num">2</div><div><strong>비교함 담기</strong><br><span style="color:#6b7280;font-size:0.9rem">각 캠핑장 페이지에서 "비교함 담기" 버튼 클릭</span></div></div>' +
                '<div class="step"><div class="step-num">3</div><div><strong>조건 비교</strong><br><span style="color:#6b7280;font-size:0.9rem">이 페이지에서 사이트 수·시설·동반 조건 등 자동 비교</span></div></div>' +
                '<a href="camp/" class="btn-go">캠핑장 찾기 →</a>' +
                '</div>';
            return;
        }

        container.innerHTML = '<p style="text-align:center;color:#6b7280;padding:20px">데이터 불러오는 중...</p>';
        const data = await loadData();
        if(!data){
            container.innerHTML = '<p style="color:#dc2626">데이터를 불러올 수 없습니다. 잠시 후 다시 시도하세요.</p>';
            return;
        }

        // 각 ID로 item 매칭
        const items = list.map(entry => {
            const found = data.items.find(x => x.contentId === entry.id);
            return found || {contentId: entry.id, name: entry.name, _notfound: true};
        }).filter(x => !x._notfound);

        if(items.length === 0){
            container.innerHTML = '<p style="color:#dc2626">비교할 캠핑장 데이터를 찾을 수 없습니다. 비교함을 비워주세요.</p>';
            return;
        }

        // Build HTML
        let html = '<div class="cmp-controls">' +
            '<div class="cmp-counter">현재 ' + items.length + '곳 비교 중 (최대 ' + MAX_COMPARE + '곳)</div>' +
            '<div><button class="cmp-clear" onclick="if(confirm(\'비교함을 비우시겠습니까?\'))gogoCompare.clear()">비교함 비우기</button> <a class="cmp-add" href="camp/">+ 캠핑장 추가</a></div>' +
            '</div>';

        html += '<div class="cmp-table-wrap"><table class="cmp-table"><thead><tr><th>항목</th>';
        items.forEach(it => {
            html += '<th><div class="camp-name"><a href="camp/camp-' + it.contentId + '.html" style="color:#fff;text-decoration:underline">' + escapeHtml(it.name) + '</a><button class="cmp-remove" onclick="gogoCompare.remove(\'' + it.contentId + '\')">×</button></div>' +
                '<span class="camp-loc">' + escapeHtml(it.sido || '') + ' ' + escapeHtml(it.sigungu || '') + '</span></th>';
        });
        html += '</tr></thead><tbody>';

        COMPARE_ROWS.forEach(cat => {
            html += '<tr><td class="cat-header" colspan="' + (items.length + 1) + '">▸ ' + cat.cat + '</td></tr>';
            cat.rows.forEach(row => {
                const bestIdx = isBest(items, row);
                html += '<tr><td>' + row.label + '</td>';
                items.forEach((it, i) => {
                    const cls = (i === bestIdx) ? 'best' : '';
                    html += '<td class="' + cls + '">' + fmtVal(it, row) + '</td>';
                });
                html += '</tr>';
            });
        });

        html += '</tbody></table></div>';
        container.innerHTML = html;
    };

    // ========= 초기화 =========
    document.addEventListener('DOMContentLoaded', function(){
        renderFloatBar();
        initDetailButton();
        if(document.getElementById('cmpContent')){
            window.renderCompareTable();
        }
    });
})();
