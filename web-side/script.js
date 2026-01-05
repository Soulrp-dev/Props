(() => {
  function getResourceName() {
    try {
      return GetParentResourceName ? GetParentResourceName() : 'dn_collections';
    } catch (e) {
      return 'dn_collections';
    }
  }

  function fetchNui(event, data) {
    return fetch(`https://${getResourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data || {})
    }).catch(err => {
      console.error('[NUI] Fetch error:', err);
      return { ok: false };
    });
  }

  async function fetchNuiCb(event, data) {
    try {
      const res = await fetchNui(event, data);
      return await res.json();
    } catch {
      return {};
    }
  }

  document.addEventListener('DOMContentLoaded', () => {
    console.log('[NUI] DOM Ready');
    fetchNui('nui_ready');
  });

  const CLOSE_ON_HOLD = true;
  const CLOSE_ON_UNHOLD = true;
  
  function closeNuiNow() { 
    setTimeout(() => fetchNui('close'), 0); 
  }

  let inviteTimer = null;
  let inviteTicker = null;

  function hideTradeInvite() {
    console.log('[NUI] Hiding trade invite');
    const el = document.getElementById('dncTradeInvite');
    if (el) {
      el.classList.remove('show');
      setTimeout(() => el.remove(), 300); // Aguarda animação
    }
    if (inviteTimer) { 
      clearTimeout(inviteTimer); 
      inviteTimer = null; 
    }
    if (inviteTicker) { 
      clearInterval(inviteTicker); 
      inviteTicker = null; 
    }
  }

  function showTradeInvite(data) {
    console.log('[NUI] Showing trade invite with data:', data);
    
    // Remove convite anterior se existir
    hideTradeInvite();

    if (!data) {
      console.error('[NUI] No data provided to showTradeInvite');
      return;
    }

    const tradeId = data.tradeId || 0;
    const fromName = data.fromName || 'Jogador';
    const fromSid = data.fromSid || data.fromId || 0;
    const timeoutMs = Number(data.timeoutMs || 5000);
    const expiresAt = Date.now() + timeoutMs;

    console.log('[NUI] Creating invite element:', {
      tradeId,
      fromName,
      fromSid,
      timeoutMs
    });

    let el = document.createElement('div');
    el.id = 'dncTradeInvite';
    el.className = 'trade-invite';
    el.style.setProperty('--dncInviteMs', String(timeoutMs));

    el.innerHTML = `
      <div class="ti-box">
        <div class="ti-title">Pedido de troca</div>
        <div class="ti-msg"><b>${fromName}</b> quer iniciar uma troca com você.</div>
        <div class="ti-actions">
          <button class="ti-accept">Aceitar (Y)</button>
          <button class="ti-decline">Recusar (N)</button>
        </div>
        <div class="ti-count">10s</div>
        <div class="ti-progress"><span></span></div>
      </div>
    `;
    
    // Adiciona ao body
    document.body.appendChild(el);
    
    // IMPORTANTE: Força reflow antes de adicionar classe 'show'
    el.offsetHeight; 
    
    // Adiciona classe 'show' para animação
    setTimeout(() => {
      el.classList.add('show');
      console.log('[NUI] Trade invite shown');
    }, 10);

    // Atualiza contador
    const countEl = el.querySelector('.ti-count');
    const tick = () => {
      const remain = Math.max(0, expiresAt - Date.now());
      const s = Math.ceil(remain / 1000);
      if (countEl) countEl.textContent = s + 's';
    };
    tick();
    inviteTicker = setInterval(tick, 200);

    // Timer de expiração
    inviteTimer = setTimeout(() => {
      console.log('[NUI] Trade invite expired');
      fetchNui('trade:inviteReply', { 
        from: tradeId,
        accept: false, 
        reason: 'timeout' 
      });
      hideTradeInvite();
    }, timeoutMs);

    // Botão Aceitar
    const acceptBtn = el.querySelector('.ti-accept');
    if (acceptBtn) {
      acceptBtn.onclick = () => {
        console.log('[NUI] Trade invite accepted');
        hideTradeInvite();
        fetchNui('trade:inviteReply', { 
          from: tradeId,
          accept: true 
        });
      };
    }

    // Botão Recusar
    const declineBtn = el.querySelector('.ti-decline');
    if (declineBtn) {
      declineBtn.onclick = () => {
        console.log('[NUI] Trade invite declined');
        hideTradeInvite();
        fetchNui('trade:inviteReply', { 
          from: tradeId,
          accept: false, 
          reason: 'decline' 
        });
      };
    }
  }

  const state = {
    open: false,
    tab: 'collections',
    catalog: {},
    owned: [],
    featured: null
  };

  const trade = {
    id: null,
    side: 'a',
    selfSide: 'a',
    aOffer: [],
    bOffer: [],
    aReady: false,
    bReady: false,
    targetId: ''
  };

  let qtyPick = { open: false, key: null, name: '', max: 0 };
  let qtyOnConfirm = null;
  let rarityInit = false;

  const refs = {
    app: null,
    grid: null,
    closeBtn: null,
    rarityFilter: null,
    seriesFilter: null,
    search: null,
    dupesOnly: null,
    qtyModal: null,
    qtyTitle: null,
    qtyInput: null,
    qtyMaxHint: null,
    qtyConfirm: null,
    qtyCancel: null
  };

  function iconUrl(icon) {
    if (!icon) return null;
    if (icon.startsWith('nui://') || icon.startsWith('http')) return icon;
    const res = getResourceName();
    return `nui://${res}/shared/img/${icon}`;
  }

  function resetTradeUI(msg) {
    trade.id = null;
    trade.selfSide = 'a';
    trade.aOffer = [];
    trade.bOffer = [];
    trade.aReady = false;
    trade.bReady = false;
    trade.targetId = '';
    const st = document.getElementById('tradeStatus');
    if (st) st.textContent = msg || '—';
    const their = document.getElementById('theirItems');
    if (their) their.innerHTML = '';
    const my = document.getElementById('myItems');
    if (my) my.querySelectorAll('.card').forEach(c => c.classList.remove('selected'));
  }
  window.resetTradeUI = resetTradeUI;

  function paintTheirItems() {
    const their = document.getElementById('theirItems');
    if (!their) return;
    const mySide = trade.selfSide || 'a';
    const theirOffer = (mySide === 'a') ? (trade.bOffer || []) : (trade.aOffer || []);
    const catalog = window.__CATALOG__ || {};

    their.innerHTML = '';
    their.classList.add('trade-items-grid');

    theirOffer.forEach(o => {
      const def = catalog[o.item_key];
      if (!def) return;
      const url = iconUrl(def.icon);
      const card = document.createElement('div');
      card.className = 'card';
      card.setAttribute('data-rarity', def.rarity || '');
      card.innerHTML = `
        <div class="badgeTag"></div>
        <div class="qty">x${o.qty}</div>
        <div class="icon-wrap">
          ${url ? `<img class="icon" src="${url}" alt="${def.name}">` : ''}
        </div>
        <div class="name">${def.name}</div>
      `;
      their.appendChild(card);
    });
  }

  window.addEventListener('message', (e) => {
    const d = e.data || {};
    console.log('[NUI] Message received:', d.action, d);

    if (d.action === 'toggle') {
      state.open = !!d.state;
      const app = document.getElementById('app');
      
      if (state.open) {
        console.log('[NUI] Opening UI');
        app.classList.add('show');
        boot();
      } else {
        console.log('[NUI] Closing UI');
        app.classList.remove('show');
      }
      return;
    }

    if (d.action === 'set_tab') {
      state.tab = d.tab || 'collections';
      document.querySelector('.tabs button.active')?.classList.remove('active');
      document.querySelector(`.tabs button[data-tab="${state.tab}"]`)?.classList.add('active');
      render();
      return;
    }

    if (d.action === 'trade_request') {
      console.log('[NUI] trade_request received:', d);
      if (d.show) {
        showTradeInvite(d);
      } else {
        hideTradeInvite();
      }
      return;
    }

    // Alias para compatibilidade
    if (d.action === 'trade_invite') {
      console.log('[NUI] trade_invite received (alias):', d);
      showTradeInvite(d);
      return;
    }

    if (d.action === 'trade_invite_hide') {
      hideTradeInvite();
      return;
    }

    if (d.action === 'trade_opened') {
      trade.id = d.tradeId;
      document.getElementById('tradeStatus')?.replaceChildren(document.createTextNode(`Trade #${d.tradeId} ativo`));
      return;
    }

    if (d.action === 'trade_sync') {
      trade.id = d.tradeId;
      trade.aOffer = d.aOffer || [];
      trade.bOffer = d.bOffer || [];
      trade.aReady = !!d.aReady;
      trade.bReady = !!d.bReady;
      trade.selfSide = d.selfSide || trade.selfSide || 'a';
      render();
      const st = document.getElementById('tradeStatus');
      if (st) st.textContent = `A:${trade.aReady ? 'Pronto' : 'Editando'} | B:${trade.bReady ? 'Pronto' : 'Editando'}`;
      paintTheirItems();
      return;
    }

    if (d.action === 'trade_error') {
      fetchNui('notify', { color: 'negado', message: 'Trade falhou: ' + (d.err || 'erro') });
      window.resetTradeUI?.('Erro no trade');
      if (state.tab === 'trade') render();
      return;
    }

    if (d.action === 'trade_finished') {
      const msg = d.success ? 'Troca concluída!' : 'Troca cancelada.';
      fetchNui('notify', { color: d.success ? 'sucesso' : 'importante', message: msg });
      window.resetTradeUI?.(d.success ? 'Concluída' : 'Cancelada');
      setTimeout(() => fetchNui('close'), 2000);
      return;
    }

    if (d.action === 'force_close') {
      const app = document.getElementById('app');
      app.classList.remove('show');
      const modal = document.getElementById('qtyModal');
      if (modal) modal.classList.remove('show');
      window.resetTradeUI?.('—');
      hideTradeInvite();
      return;
    }
  });

  async function boot() {
    console.log('[NUI] Booting...');
    
    if (!rarityInit && refs.rarityFilter) {
      refs.rarityFilter.innerHTML = '';
      ['', 'Comum', 'Rara', 'Épica', 'Lendária', 'NFT'].forEach(r => {
        const o = document.createElement('option');
        o.value = r;
        o.textContent = r || 'Raridade';
        refs.rarityFilter.appendChild(o);
      });
      rarityInit = true;
    }

    const data = await fetchNuiCb('dnc:collections:getData');
    console.log('[NUI] Data received:', data);
    window.__CATALOG__ = data.catalog || {};
    state.owned = data.items || [];
    state.featured = data.featured || null;
    render();
  }

  function render() {
    if (!refs.grid) return;
    refs.grid.innerHTML = '';

    const tab = state.tab || 'collections';
    const catalog = window.__CATALOG__ || {};

    const index = {};
    (state.owned || []).forEach(it => index[it.item_key] = it.qty);
    
    if (tab === 'trade') {
      refs.grid.classList.add('trade-mode');
    } else {
      refs.grid.classList.remove('trade-mode');
    }

    if (tab === 'collections' || tab === 'badges') {
      const showType = tab === 'collections' ? 'collection' : 'badge';
      const fR = refs.rarityFilter ? (refs.rarityFilter.value || '') : '';
      const fS = refs.seriesFilter ? (refs.seriesFilter.value || '').toLowerCase() : '';
      const fQ = refs.search ? (refs.search.value || '').toLowerCase() : '';
      const onlyDupes = refs.dupesOnly ? !!refs.dupesOnly.checked : false;

      const entries = Object.entries(catalog).filter(([k, def]) => {
        if (!def || def.type !== showType) return false;
        const qty = index[k] || 0;
        if (qty <= 0) return false;
        if (onlyDupes && qty < 2) return false;
        if (fR && def.rarity !== fR) return false;
        if (fS && !(def.series || '').toLowerCase().includes(fS)) return false;
        if (fQ && !(def.name || '').toLowerCase().includes(fQ)) return false;
        return true;
      });

      for (const [key, def] of entries) {
        const qty = index[key] || 0;
        const url = iconUrl(def.icon);
        const card = document.createElement('div');
        card.className = 'card';
        card.title = `${def.name} • ${def.series} • ${def.rarity} • x${qty}`;
        card.setAttribute('data-rarity', def.rarity || '');
        card.innerHTML = `
          <div class="badgeTag">${def.rarity}</div>
          <div class="qty">x${qty}</div>
          <div class="icon-wrap">
            ${url ? `<img class="icon" src="${url}" alt="${def.name}">` : ''}
          </div>
          <div class="name">${def.name}</div>
          ${def.prop ? `
            <div class="actions">
              <button class="mini" data-act="hold" data-key="${key}">Segurar</button>
            </div>` : ``}
        `;
        refs.grid.appendChild(card);
      }

      if (!refs.grid._holdBound) {
        refs.grid.addEventListener('click', (e) => {
          const btnHold = e.target.closest('button[data-act="hold"]');
          if (btnHold) {
            const key = btnHold.dataset.key;
            fetchNui('hold:start', { itemKey: key });
            if (CLOSE_ON_HOLD) closeNuiNow();
            return;
          }
          const btnUnhold = e.target.closest('button[data-act="unhold"]');
          if (btnUnhold) {
            fetchNui('hold:stop');
            if (CLOSE_ON_UNHOLD) closeNuiNow();
          }
        });
        refs.grid._holdBound = true;
      }
      return;
    }

    if (tab === 'trade') {
    refs.grid.innerHTML = `
      <div class="trade-container">
        <div class="trade-controls">
          <div class="trade-controls-row">
            <input id="tradeTarget" placeholder="ID do jogador..." />
            <button id="tradeStart">Iniciar Troca</button>
            <button id="nearbyBtn">Ver Próximos</button>
          </div>
          <select id="nearbySelect">
            <option value="">Selecionar jogador próximo…</option>
          </select>
          <div id="tradeStatus" class="trade-status">Aguardando iniciar troca...</div>
        </div>

        <div class="trade-offers">
          <div class="trade-side">
            <div class="trade-header">
              <h3>Minha Oferta</h3>
              <button id="readyBtn" class="btn-ready">✓ Confirmar</button>
            </div>
            <div id="myItems" class="trade-items-grid"></div>
          </div>

          <div class="trade-divider"></div>

          <div class="trade-side">
            <div class="trade-header">
              <h3>Oferta do Outro</h3>
              <button id="cancelBtn" class="btn-cancel">✕ Cancelar</button>
            </div>
            <div id="theirItems" class="trade-items-grid"></div>
          </div>
        </div>
      </div>
    `;

      const tradeStart = document.getElementById('tradeStart');
      const readyBtn = document.getElementById('readyBtn');
      const cancelBtn = document.getElementById('cancelBtn');
      const tradeTarget = document.getElementById('tradeTarget');
      const nearbyBtn = document.getElementById('nearbyBtn');
      const nearbySelect = document.getElementById('nearbySelect');

      if (nearbyBtn) nearbyBtn.onclick = async () => {
        const list = await fetchNuiCb('trade:getNearby', { max: 50.0 }) || [];
        nearbySelect.innerHTML = '<option value="">Selecionar jogador próximo…</option>';
        list.forEach(p => {
          const opt = document.createElement('option');
          opt.value = String(p.id);
          opt.textContent = `[#${p.id}] ${p.name} — ${p.dist.toFixed(1)}m`;
          nearbySelect.appendChild(opt);
        });
        if (list.length === 1) {
          nearbySelect.value = String(list[0].id);
          tradeTarget.value = String(list[0].id);
        }
      };

      if (nearbySelect) nearbySelect.onchange = () => {
        const v = nearbySelect.value;
        if (v) tradeTarget.value = v;
      };

      if (tradeStart) tradeStart.onclick = async () => {
        const id = parseInt(tradeTarget.value || '0', 10);
        if (!id) {
          window.resetTradeUI('ID inválido');
          return;
        }
        const res = await fetchNuiCb('trade:start', { targetId: id });
        const st = document.getElementById('tradeStatus');
        if (!res || !res.ok) {
          const map = {
            jogador_invalido: 'Jogador inválido/offline',
            mesmo_jogador: 'Você não pode trocar consigo mesmo',
            alvo_longe: 'Jogador muito longe',
            instancia_diferente: 'Jogadores em instâncias diferentes',
            ped_invalido: 'Não foi possível localizar o jogador'
          };
          st.textContent = `Erro: ${map[res?.err] || (res?.err || 'falha')}`;
          window.resetTradeUI(st.textContent);
          return;
        }
        trade.id = res.trade_id;
        trade.selfSide = 'a';
        st.textContent = `Trade #${res.trade_id} criado — aguarde confirmação`;
      };

      if (readyBtn) readyBtn.onclick = () => {
        if (!trade.id) return;
        const mySide = trade.selfSide || 'a';
        fetchNui('trade:setReady', { tradeId: trade.id, side: mySide, ready: true });
      };

      if (cancelBtn) cancelBtn.onclick = () => {
        if (trade.id) fetchNui('trade:cancel', { tradeId: trade.id });
        window.resetTradeUI('Trade cancelado');
      };

      const myEl = document.getElementById('myItems');
      if (myEl) {
        const mine = Object.entries(catalog).filter(([k, def]) => def?.type === 'collection' && (index[k] || 0) > 0);

        const mySide = trade.selfSide || 'a';
        const myOffer = (mySide === 'a') ? trade.aOffer : trade.bOffer;

        mine.forEach(([key, def]) => {
          const qty = index[key];
          const offered = (myOffer.find(o => o.item_key === key)?.qty) || 0;
          const url = iconUrl(def.icon);

          const card = document.createElement('div');
          card.className = 'card' + (offered > 0 ? ' selected' : '');
          card.setAttribute('data-rarity', def.rarity || '');
          card.dataset.key = key;
          card.dataset.name = def.name;
          card.dataset.owned = qty;

          card.innerHTML = `
            <div class="badgeTag"></div>
            <div class="qty">x${qty}</div>
            <div class="icon-wrap">
              ${url ? `<img class="icon" src="${url}" alt="${def.name}">` : ''}
            </div>
            ${offered > 0 ? `<div class="offered">oferecido: ${offered}</div>` : ``}
            <div class="name">${def.name}</div>
          `;
          myEl.appendChild(card);
        });

        myEl.onclick = (e) => {
          const card = e.target.closest('.card');
          if (!card) return;
          if (!trade.id) {
            const st = document.getElementById('tradeStatus');
            if (st) st.textContent = 'Inicie um trade primeiro.';
            return;
          }

          const key = card.dataset.key;
          const name = card.dataset.name;
          const owned = parseInt(card.dataset.owned, 10);

          const mySide = trade.selfSide || 'a';
          const myOffer = (mySide === 'a') ? trade.aOffer : trade.bOffer;

          const already = (myOffer.find(o => o.item_key === key)?.qty) || 0;
          const max = Math.max(owned, 0);

          const applyQty = (q) => {
            const existing = myOffer.find(o => o.item_key === key);
            if (existing) {
              existing.qty = q;
            } else {
              myOffer.push({ item_key: key, qty: q });
            }
            fetchNui('trade:updateOffer', { tradeId: trade.id, side: mySide, offer: myOffer });
            render();
          };

          if (refs.qtyModal) {
            openQtyModal(key, name, max, already);
            qtyOnConfirm = (q) => applyQty(q);
          } else {
            const q = parseInt(prompt(`Quantidade de "${name}" (máx ${max})`, already || 1) || '0', 10);
            if (!q || q < 1) return;
            applyQty(q);
          }
        };
      }
    }
  }

  function openQtyModal(key, name, max, current) {
    if (!refs.qtyModal) return;
    qtyPick = { open: true, key, name, max };
    refs.qtyTitle.textContent = `Selecionar quantidade — ${name}`;
    refs.qtyInput.min = 1;
    refs.qtyInput.max = Math.max(max, 1);
    refs.qtyInput.value = Math.min(Math.max(current || 1, 1), refs.qtyInput.max);
    refs.qtyMaxHint.textContent = `(máx ${refs.qtyInput.max})`;
    refs.qtyModal.classList.add('show');
    refs.qtyInput.focus();
  }

  function closeQtyModal() {
    if (!refs.qtyModal) return;
    qtyPick = { open: false, key: null, name: '', max: 0 };
    refs.qtyModal.classList.remove('show');
  }

  (() => {
    refs.app = document.getElementById('app');
    refs.grid = document.getElementById('grid');
    refs.closeBtn = document.getElementById('close');
    refs.rarityFilter = document.getElementById('rarityFilter');
    refs.seriesFilter = document.getElementById('seriesFilter');
    refs.search = document.getElementById('search');
    refs.dupesOnly = document.getElementById('dupesOnly');

    if (refs.dupesOnly && !document.getElementById('btnUnhold')) {
      const unholdBtn = document.createElement('button');
      unholdBtn.id = 'btnUnhold';
      unholdBtn.className = 'mini';
      unholdBtn.type = 'button';
      unholdBtn.textContent = 'Guardar';
      unholdBtn.addEventListener('click', () => {
        fetchNui('hold:stop');
        if (CLOSE_ON_UNHOLD) closeNuiNow();
      });

      const wrap = refs.dupesOnly.closest('.filters') || refs.dupesOnly.parentElement || document.body;
      let node = refs.dupesOnly.nextSibling, anchor = null;
      while (node) {
        if (node.nodeType === 3 && /repetidos/i.test((node.nodeValue || '').trim())) {
          anchor = node;
          break;
        }
        if (node.nodeType === 1 && /repetidos/i.test((node.textContent || '').trim())) {
          anchor = node;
          break;
        }
        node = node.nextSibling;
      }
      if (anchor && anchor.parentNode) anchor.parentNode.insertBefore(unholdBtn, anchor.nextSibling);
      else wrap.appendChild(unholdBtn);
    }

    refs.qtyModal = document.getElementById('qtyModal');
    refs.qtyTitle = document.getElementById('qtyTitle');
    refs.qtyInput = document.getElementById('qtyInput');
    refs.qtyMaxHint = document.getElementById('qtyMaxHint');
    refs.qtyConfirm = document.getElementById('qtyConfirm');
    refs.qtyCancel = document.getElementById('qtyCancel');

    if (refs.qtyModal && (!refs.qtyTitle || !refs.qtyInput || !refs.qtyMaxHint || !refs.qtyConfirm || !refs.qtyCancel)) {
      console.warn('[NUI] Modal incompleto, usando fallback por prompt()');
      refs.qtyModal = null;
    }

    if (refs.closeBtn) refs.closeBtn.onclick = () => fetchNui('close');

    document.querySelectorAll('.tabs button').forEach(b => {
      b.onclick = () => {
        let tabName = b.dataset.tab;
        if (!tabName) {
          const t = (b.textContent || '').trim().toLowerCase();
          if (t.includes('insig')) tabName = 'badges';
          else if (t.includes('troca')) tabName = 'trade';
          else tabName = 'collections';
        }
        if (tabName !== 'trade') window.resetTradeUI('—');
        document.querySelector('.tabs button.active')?.classList.remove('active');
        b.classList.add('active');
        state.tab = tabName;
        render();
      };
    });

    window.addEventListener('keydown', (ev) => {
      if (ev.key === 'Escape') {
        const app = document.getElementById('app');
        if (app && app.classList.contains('show')) {
          fetchNui('close');
        }
      }
    });

    ['input', 'change'].forEach(ev => {
      refs.rarityFilter && refs.rarityFilter.addEventListener(ev, render);
      refs.seriesFilter && refs.seriesFilter.addEventListener(ev, render);
      refs.search && refs.search.addEventListener(ev, render);
      refs.dupesOnly && refs.dupesOnly.addEventListener(ev, render);
    });

    if (refs.qtyModal) {
      refs.qtyConfirm.onclick = () => {
        const q = parseInt(refs.qtyInput.value || '0', 10);
        if (!qtyPick.key || !q || q < 1) {
          qtyOnConfirm = null;
          closeQtyModal();
          return;
        }
        const fn = qtyOnConfirm;
        qtyOnConfirm = null;
        closeQtyModal();
        if (typeof fn === 'function') fn(q);
      };
      refs.qtyCancel.onclick = () => {
        qtyOnConfirm = null;
        closeQtyModal();
      };
      refs.qtyModal.addEventListener('click', (e) => {
            if (e.target === refs.qtyModal) {
              qtyOnConfirm = null;
              closeQtyModal();
            }
          });
        }

        console.log('[NUI] Script initialized');
      })();
    })();