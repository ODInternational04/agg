// Depot Workflow App - Supabase Version
// Connected to high_aggregator_* tables

(function() {
  // Initialize Supabase client
  let supabase = null;
  
  // Constants
  const USER = { id: 'USER-DEPOT-MANAGER-001', name: 'Depot Manager' };
  const DEPOT = { id: 'DEPOT-A', name: 'Depot A' };

  const STATUSES = {
    IN_FIELD: 'IN_FIELD',
    IN_TRANSIT: 'IN_TRANSIT',
    RECEIVED_AT_DEPOT: 'RECEIVED_AT_DEPOT',
    STORED: 'STORED',
    DISPATCHED: 'DISPATCHED',
    CLOSED: 'CLOSED',
  };

  // Initialize Supabase
  function initSupabase() {
    if (!window.supabase || !SUPABASE_CONFIG) {
      console.error('Supabase library or config not loaded');
      return false;
    }
    
    if (SUPABASE_CONFIG.url === 'YOUR_SUPABASE_URL_HERE') {
      alert('⚠️ Please configure your Supabase credentials in supabase-config.js');
      return false;
    }

    supabase = window.supabase.createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.anonKey);
    console.log('✅ Supabase initialized');
    return true;
  }

  // Helper functions
  function nowTs() { return new Date().toISOString(); }
  
  function setMessage(el, text, type) {
    if (!el) return;
    el.className = 'message' + (type ? ' ' + type : '');
    el.textContent = text || '';
  }

  function renderKV(el, obj) {
    if (!el) return;
    if (!obj) { el.innerHTML = ''; return; }
    const rows = Object.entries(obj).map(([k,v]) => `
      <div class="kv">
        <div><strong>${k}</strong></div>
        <div>${v == null ? '' : v}</div>
      </div>`).join('');
    el.innerHTML = rows;
  }

  // Navigation
  function showTab(id) {
    const tabs = document.querySelectorAll('.tab');
    tabs.forEach(t => t.classList.toggle('active', t.id === id));
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  // ----- Database Functions -----
  
  async function getBin(binId) {
    try {
      const { data, error } = await supabase
        .from('high_aggregator_bins')
        .select('*, aggregator:high_aggregator_branches(name)')
        .eq('id', binId)
        .single();
      
      if (error && error.code !== 'PGRST116') throw error;
      return data;
    } catch (e) {
      console.error('Error fetching bin:', e);
      return null;
    }
  }

  async function createBin(binId) {
    try {
      const { data, error } = await supabase
        .from('high_aggregator_bins')
        .insert([{
          id: binId,
          aggregator_id: null,
          status: STATUSES.IN_FIELD
        }])
        .select('*, aggregator:high_aggregator_branches(name)')
        .single();
      
      if (error) throw error;
      return data;
    } catch (e) {
      console.error('Error creating bin:', e);
      return null;
    }
  }

  async function updateBinStatus(binId, status, storedAt = null) {
    try {
      const updateData = { 
        status, 
        last_event_ts: nowTs()
      };
      if (storedAt !== null) {
        updateData.stored_at = storedAt;
      }

      const { error } = await supabase
        .from('high_aggregator_bins')
        .update(updateData)
        .eq('id', binId);
      
      if (error) throw error;
      return true;
    } catch (e) {
      console.error('Error updating bin status:', e);
      return false;
    }
  }

  async function createEvent(eventData) {
    try {
      const { data, error } = await supabase
        .from('high_aggregator_events')
        .insert([eventData])
        .select()
        .single();
      
      if (error) throw error;
      return data;
    } catch (e) {
      console.error('Error creating event:', e);
      return null;
    }
  }

  async function getBinsReadyForStorage() {
    try {
      const { data, error } = await supabase
        .from('high_aggregator_bins')
        .select(`
          id,
          aggregator_id,
          status,
          aggregator:high_aggregator_branches(name)
        `)
        .eq('status', STATUSES.RECEIVED_AT_DEPOT)
        .order('last_event_ts', { ascending: true, nullsFirst: false });
      
      if (error) throw error;
      return data || [];
    } catch (e) {
      console.error('Error fetching bins:', e);
      return [];
    }
  }

  async function getLatestReceiptEvent(binId) {
    try {
      const { data, error } = await supabase
        .from('high_aggregator_events')
        .select('inbound_litres, oil_type, notes, drainage_litres')
        .eq('bin_id', binId)
        .eq('event_type', 'RECEIVED')
        .order('timestamp', { ascending: false })
        .limit(1)
        .single();
      
      if (error && error.code !== 'PGRST116') throw error;
      return data;
    } catch (e) {
      console.error('Error fetching receipt event:', e);
      return null;
    }
  }

  // ----- QR Scanner (html5-qrcode) -----
  let qrInstance = null;
  let scannerOpen = false;
  let scannerOnScan = null;
  let camerasCache = [];

  async function startCamera(cameraId) {
    const readerEl = document.getElementById('qrReader');
    const msgEl = document.getElementById('scannerMessage');
    if (!window.Html5Qrcode) { setMessage(msgEl, 'QR library not loaded', 'error'); return; }
    if (!qrInstance) qrInstance = new Html5Qrcode('qrReader');
    
    let cameraConfig = cameraId;
    if (!cameraConfig || cameraConfig === 'environment') {
      cameraConfig = { facingMode: 'environment' };
    }

    try {
      await qrInstance.start(
        cameraConfig,
        { fps: 10, qrbox: { width: 250, height: 250 } },
        (decodedText) => {
          if (scannerOnScan) {
            try { scannerOnScan(decodedText); } catch {}
          }
          closeScanner();
        },
        (errorMessage) => {}
      );
      setMessage(msgEl, 'Camera ready - scan QR code', 'success');
    } catch (err) {
      setMessage(msgEl, 'Camera error: ' + (err?.message || err), 'error');
    }
  }

  function openScanner(onScan) {
    const modal = document.getElementById('scannerModal');
    const msgEl = document.getElementById('scannerMessage');
    scannerOnScan = onScan;
    scannerOpen = true;
    modal.classList.add('show');
    setMessage(msgEl, 'Initializing camera...', '');

    try {
      if (!window.Html5Qrcode) { setMessage(msgEl, 'QR library not loaded', 'error'); return; }
      
      Html5Qrcode.getCameras().then(cameras => {
        camerasCache = cameras;
        const cameraSelect = document.getElementById('cameraSelect');
        if (cameras && cameras.length > 0) {
          cameraSelect.innerHTML = cameras.map((cam, idx) => 
            `<option value="${cam.id}">${cam.label || 'Camera ' + (idx+1)}</option>`
          ).join('');
          startCamera(cameras[cameras.length - 1].id);
        } else {
          cameraSelect.innerHTML = '<option value="environment">Default Camera</option>';
          setMessage(msgEl, 'No cameras found. Trying default...', '');
          startCamera('environment');
        }
      }).catch(err => {
        const cameraSelect = document.getElementById('cameraSelect');
        if (cameraSelect) {
          cameraSelect.innerHTML = '<option value="environment">Default Camera (rear-facing)</option>';
        }
        setMessage(msgEl, 'Trying default camera...', '');
        startCamera('environment');
      });
    } catch (e) {
      setMessage(msgEl, 'Scanner init error: ' + (e?.message || e), 'error');
    }
  }

  function closeScanner() {
    const modal = document.getElementById('scannerModal');
    const msgEl = document.getElementById('scannerMessage');
    scannerOpen = false;
    if (qrInstance) {
      try { 
        qrInstance.stop().then(() => {
          if (qrInstance && qrInstance.clear) {
            qrInstance.clear();
          }
        }).catch(() => {}); 
      } catch {}
      qrInstance = null;
    }
    modal.classList.remove('show');
    setMessage(msgEl, '', '');
  }

  // ----- Receive Screen -----
  function setupReceive() {
    const receiveBinQr = document.getElementById('receiveBinQr');
    const receiveOpenScannerBtn = document.getElementById('receiveOpenScannerBtn');
    const receiveBinInfo = document.getElementById('receiveBinInfo');
    const litresEl = document.getElementById('receiveLitres');
    const oilTypeEl = document.getElementById('receiveOilType');
    const notesEl = document.getElementById('receiveNotes');
    const photoEl = document.getElementById('receivePhoto');
    const confirmBtn = document.getElementById('receiveConfirmBtn');
    const goToStoreBtn = document.getElementById('goToStoreBtn');
    const msgEl = document.getElementById('receiveMessage');

    let resolvedBin = null;

    async function resolveBin(qr) {
      if (!qr || !qr.trim()) { 
        setMessage(msgEl, 'Invalid Bin QR', 'error'); 
        resolvedBin = null; 
        return false; 
      }

      setMessage(msgEl, 'Looking up bin...', '');
      let bin = await getBin(qr.trim());
      
      if (!bin) {
        setMessage(msgEl, 'Creating new bin...', '');
        bin = await createBin(qr.trim());
        if (!bin) {
          setMessage(msgEl, 'Error creating bin', 'error');
          resolvedBin = null;
          return false;
        }
        setMessage(msgEl, `✨ New bin ${qr.trim()} created and ready for receipt`, 'success');
      } else if (bin.status === STATUSES.RECEIVED_AT_DEPOT || bin.status === STATUSES.STORED) {
        setMessage(msgEl, 'Bin already received or stored', 'error');
        renderKV(receiveBinInfo, {
          'Bin ID': bin.id,
          'Current Status': bin.status,
          'Aggregator': bin.aggregator?.name || 'Unassigned',
        });
        resolvedBin = bin;
        return false;
      } else {
        setMessage(msgEl, 'Bin ready for receipt', 'success');
      }
      
      resolvedBin = bin;
      renderKV(receiveBinInfo, {
        'Bin ID': bin.id,
        'Current Status': bin.status,
        'Aggregator': bin.aggregator?.name || 'Unassigned',
      });
      return true;
    }

    if (receiveOpenScannerBtn) {
      receiveOpenScannerBtn.addEventListener('click', () => {
        openScanner((decodedText) => {
          receiveBinQr.value = decodedText;
          resolveBin(decodedText);
        });
      });
    }

    if (confirmBtn) {
      confirmBtn.addEventListener('click', async () => {
        const qr = (receiveBinQr.value || '').trim();
        if (!qr) { setMessage(msgEl, 'Please enter or scan a Bin QR', 'error'); return; }
        
        if (!resolvedBin || resolvedBin.id !== qr) {
          const resolved = await resolveBin(qr);
          if (!resolved) return;
        }
        
        if (!resolvedBin) { setMessage(msgEl, 'Please resolve a bin first', 'error'); return; }
        
        // Allow bins to be received multiple times (no status check)

        let photoName = '';
        if (photoEl && photoEl.files && photoEl.files[0]) {
          photoName = photoEl.files[0].name;
        }

        setMessage(msgEl, 'Saving receipt...', '');

        const eventData = {
          event_type: 'RECEIVED',
          bin_id: resolvedBin.id,
          depot_id: DEPOT.id,
          aggregator_id: resolvedBin.aggregator_id,
          user_id: USER.id,
          inbound_litres: litresEl && litresEl.value ? Number(litresEl.value) : null,
          oil_type: oilTypeEl && oilTypeEl.value ? oilTypeEl.value : null,
          notes: notesEl && (notesEl.value || '').trim() ? (notesEl.value || '').trim() : null,
          photo_url: photoName || null
        };

        const event = await createEvent(eventData);
        if (!event) {
          setMessage(msgEl, 'Error saving receipt', 'error');
          return;
        }

        const updated = await updateBinStatus(resolvedBin.id, STATUSES.RECEIVED_AT_DEPOT);
        if (!updated) {
          setMessage(msgEl, 'Error updating bin status', 'error');
          return;
        }

        setMessage(msgEl, `✅ Receipt confirmed! Bin ${resolvedBin.id} received at ${DEPOT.name}`, 'success');
        renderKV(receiveBinInfo, {
          'Bin ID': resolvedBin.id,
          'New Status': STATUSES.RECEIVED_AT_DEPOT,
          'Aggregator': resolvedBin.aggregator?.name || 'Unassigned',
          'Litres': eventData.inbound_litres ?? '—',
          'Oil Type': eventData.oil_type ?? '—',
          'Notes': eventData.notes ?? '—',
          'Photo': eventData.photo_url ?? '—',
        });
        
        if (goToStoreBtn) goToStoreBtn.style.display = 'block';
        
        setTimeout(() => {
          if (receiveBinQr) receiveBinQr.value = '';
          if (litresEl) litresEl.value = '';
          if (notesEl) notesEl.value = '';
          if (photoEl) photoEl.value = '';
          resolvedBin = null;
          renderKV(receiveBinInfo, null);
        }, 2000);
      });
    }
  }

  // ----- Store Screen -----
  let storeBinListEl = null;
  let storeMsgEl = null;
  
  async function renderBinList() {
    if (!storeBinListEl) return;
    
    setMessage(storeMsgEl, 'Loading bins...', '');
    const receivedBins = await getBinsReadyForStorage();
    
    if (receivedBins.length === 0) {
      storeBinListEl.innerHTML = '<p style="color: #666; text-align: center; padding: 20px;">No bins ready for storage. Receive bins first.</p>';
      setMessage(storeMsgEl, '', '');
      return;
    }

    // Get receipt events for each bin
    const binsWithEvents = await Promise.all(receivedBins.map(async (bin) => {
      const receiptEvent = await getLatestReceiptEvent(bin.id);
      return { ...bin, receiptEvent };
    }));

    storeBinListEl.innerHTML = binsWithEvents.map(bin => {
      const litres = bin.receiptEvent?.inbound_litres ?? '—';
      const oilType = bin.receiptEvent?.oil_type ?? '—';
      
      return `
        <div class="bin-item">
          <div class="bin-item-header">
            <h4>${bin.id}</h4>
          </div>
          <div class="bin-item-details">
            <div><strong>Branch:</strong> ${bin.aggregator?.name || 'Unassigned'}</div>
            <div><strong>Inbound Litres:</strong> ${litres}</div>
            <div><strong>Oil Type:</strong> ${oilType}</div>
          </div>
          <div style="margin-top: 10px;">
            <label style="display: block; margin-bottom: 5px; font-weight: 500;">Amount after drainage (litres)</label>
            <input 
              type="number" 
              id="drainage-${bin.id}" 
              data-bin-id="${bin.id}"
              data-inbound-litres="${bin.receiptEvent?.inbound_litres || ''}"
              data-oil-type="${bin.receiptEvent?.oil_type || ''}"
              placeholder="Enter litres after drainage" 
              min="0" 
              step="0.1"
              style="width: 100%; padding: 8px; font-size: 14px; border: 1px solid #ccc; border-radius: 4px;"
            />
          </div>
          <div style="margin-top: 10px;">
            <button class="primary" data-bin-id="${bin.id}" style="width: 100%;">Store</button>
          </div>
        </div>
      `;
    }).join('');

    setMessage(storeMsgEl, '', '');

    // Wire up Store buttons
    storeBinListEl.querySelectorAll('button[data-bin-id]').forEach(btn => {
      btn.addEventListener('click', async () => {
        const binId = btn.getAttribute('data-bin-id');
        
        const drainageInput = document.getElementById(`drainage-${binId}`);
        const drainageAmount = drainageInput ? drainageInput.value : '';
        
        if (!drainageAmount || drainageAmount.trim() === '') {
          setMessage(storeMsgEl, 'Please enter amount after drainage', 'error');
          if (drainageInput) drainageInput.focus();
          return;
        }
        
        const drainageLitres = Number(drainageAmount);
        if (isNaN(drainageLitres) || drainageLitres < 0) {
          setMessage(storeMsgEl, 'Please enter a valid amount', 'error');
          if (drainageInput) drainageInput.focus();
          return;
        }
        
        setMessage(storeMsgEl, 'Scan storage location QR...', '');
        openScanner(async (decodedText) => {
          if (!decodedText || !decodedText.trim()) {
            setMessage(storeMsgEl, 'Invalid storage location QR', 'error');
            return;
          }

          const locationQR = decodedText.trim();
          setMessage(storeMsgEl, 'Storing bin...', '');

          const bin = receivedBins.find(b => b.id === binId);
          if (!bin) {
            setMessage(storeMsgEl, 'Bin not found', 'error');
            return;
          }

          // Get inbound_litres and oil_type from the drainage input data attributes
          const inboundLitres = drainageInput.getAttribute('data-inbound-litres');
          const oilType = drainageInput.getAttribute('data-oil-type');

          const eventData = {
            event_type: 'STORED',
            bin_id: binId,
            depot_id: DEPOT.id,
            aggregator_id: bin.aggregator_id,
            location_id: locationQR,
            user_id: USER.id,
            drainage_litres: drainageLitres,
            inbound_litres: inboundLitres ? Number(inboundLitres) : null,
            oil_type: oilType || null
          };

          const event = await createEvent(eventData);
          if (!event) {
            setMessage(storeMsgEl, 'Error saving storage event', 'error');
            return;
          }

          const updated = await updateBinStatus(binId, STATUSES.STORED, locationQR);
          if (!updated) {
            setMessage(storeMsgEl, 'Error updating bin status', 'error');
            return;
          }

          setMessage(storeMsgEl, `✅ Oil has been stored successfully`, 'success');
          renderBinList();
        });
      });
    });
  }
  
  function setupStore() {
    storeBinListEl = document.getElementById('storeBinList');
    storeMsgEl = document.getElementById('storeMessage');
    renderBinList();
  }

  // ----- Bootstrap -----
  function bootstrap() {
    // Initialize Supabase
    if (!initSupabase()) {
      document.body.innerHTML = `
        <div style="padding: 40px; text-align: center; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #b00020;">⚠️ Configuration Required</h1>
          <p style="font-size: 16px; line-height: 1.6; color: #555;">
            Please configure your Supabase credentials in <code>supabase-config.js</code>
          </p>
          <ol style="text-align: left; margin: 20px 0;">
            <li>Create a Supabase project at <a href="https://supabase.com" target="_blank">supabase.com</a></li>
            <li>Run the <code>supabase-schema.sql</code> in the SQL Editor</li>
            <li>Copy your Project URL and anon key to <code>supabase-config.js</code></li>
            <li>Refresh this page</li>
          </ol>
        </div>
      `;
      return;
    }
    
    // Home navigation
    const goReceive = document.getElementById('goReceive');
    const goStore = document.getElementById('goStore');
    const goToStoreBtn = document.getElementById('goToStoreBtn');
    const backHome1 = document.getElementById('backHome1');
    const backHome2 = document.getElementById('backHome2');
    if (goReceive) goReceive.addEventListener('click', () => showTab('receive'));
    if (goStore) goStore.addEventListener('click', () => {
      showTab('store');
      renderBinList();
    });
    if (goToStoreBtn) goToStoreBtn.addEventListener('click', () => {
      showTab('store');
      renderBinList();
    });
    if (backHome1) backHome1.addEventListener('click', () => showTab('home'));
    if (backHome2) backHome2.addEventListener('click', () => showTab('home'));

    const scannerClose = document.getElementById('scannerClose');
    if (scannerClose) scannerClose.addEventListener('click', closeScanner);

    // Image scan fallback
    const scanImageBtn = document.getElementById('scanImageBtn');
    const qrImageFile = document.getElementById('qrImageFile');
    const scannerMsg = document.getElementById('scannerMessage');
    if (scanImageBtn) {
      scanImageBtn.addEventListener('click', async () => {
        if (!window.Html5Qrcode) { setMessage(scannerMsg, 'QR library not loaded', 'error'); return; }
        const file = qrImageFile && qrImageFile.files && qrImageFile.files[0];
        if (!file) { setMessage(scannerMsg, 'Select an image containing a QR code', 'error'); return; }
        try {
          if (!qrInstance) qrInstance = new Html5Qrcode('qrReader');
          const decodedText = await qrInstance.scanFile(file, true);
          if (scannerOnScan) {
            try { scannerOnScan(decodedText); } catch {}
          }
          closeScanner();
        } catch (err) {
          setMessage(scannerMsg, 'Could not scan image: ' + (err?.message || err), 'error');
        }
      });
    }

    // Camera selector apply
    const cameraApplyBtn = document.getElementById('cameraApplyBtn');
    const cameraSelect = document.getElementById('cameraSelect');
    if (cameraApplyBtn && cameraSelect) {
      cameraApplyBtn.addEventListener('click', () => {
        const selectedId = cameraSelect.value;
        if (selectedId) startCamera(selectedId);
      });
    }

    setupReceive();
    setupStore();
  }

  document.addEventListener('DOMContentLoaded', bootstrap);
})();
