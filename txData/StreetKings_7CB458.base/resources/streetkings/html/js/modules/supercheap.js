(function (window) {
  'use strict';

  var SK = window.StreetKings;

  function money(value) {
    return '$' + (Number(value || 0) || 0).toLocaleString('en-US');
  }

  var currentCategory = 'all';

  function renderSupercheap(data) {
    var content = document.getElementById('phoneSupercheapContent');
    if (!content) return;

    var catalog = data.catalog || {};
    var ownedTools = data.ownedTools || {};
    var consumables = data.consumables || {};
    var balance = data.balance || 0;
    var hasHouse = data.hasHouse === true;

    var css = [
      '<style>',
      '  .sc-container { display: flex; flex-direction: column; gap: 8px; font-family: "Inter", sans-serif; color: #fff; height: 100%; }',
      '  .sc-header-row { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid rgba(255,255,255,0.08); padding-bottom: 6px; }',
      '  .sc-balance { font-size: 14px; font-weight: bold; color: #ffd200; }',
      '  .sc-cats { display: flex; gap: 6px; overflow-x: auto; padding-bottom: 6px; border-bottom: 1px solid rgba(255,255,255,0.05); }',
      '  .sc-cat { cursor: pointer; padding: 4px 10px; border-radius: 4px; font-size: 11px; font-weight: bold; background: rgba(255,255,255,0.05); color: rgba(255,255,255,0.7); border: 1px solid rgba(255,255,255,0.05); white-space: nowrap; transition: all 0.2s; }',
      '  .sc-cat:hover { background: rgba(255,255,255,0.1); color: #fff; }',
      '  .sc-cat.active { background: #ffd200; color: #000; border-color: #ffd200; }',
      '  .sc-items { display: flex; flex-direction: column; gap: 8px; overflow-y: auto; max-height: calc(100vh - 200px); padding-bottom: 20px; }',
      '  .sc-item-card { background: rgba(255,255,255,0.02); border: 1px solid rgba(255,255,255,0.05); border-radius: 6px; padding: 8px 10px; display: flex; justify-content: space-between; align-items: center; gap: 8px; }',
      '  .sc-item-info { display: flex; flex-direction: column; gap: 2px; }',
      '  .sc-item-name { font-size: 13px; font-weight: bold; }',
      '  .sc-item-meta { font-size: 11px; color: rgba(255,255,255,0.5); }',
      '  .sc-item-price { font-size: 12px; font-weight: bold; color: #34c759; }',
      '  .sc-buy-btn { cursor: pointer; padding: 4px 8px; font-size: 11px; font-weight: bold; border-radius: 4px; border: none; background: #ffd200; color: #000; transition: filter 0.2s; }',
      '  .sc-buy-btn:hover { filter: brightness(1.1); }',
      '  .sc-buy-btn:disabled { opacity: 0.4; cursor: not-allowed; }',
      '</style>'
    ].join('\n');

    var categories = ['all', 'engine', 'turbo', 'suspension', 'tools', 'consumables'];
    var catHtml = categories.map(function (cat) {
      var act = currentCategory === cat ? 'active' : '';
      var label = cat.charAt(0).toUpperCase() + cat.slice(1);
      return '<div class="sc-cat ' + act + '" data-cat="' + cat + '">' + label + '</div>';
    }).join('');

    var itemsHtml = [];
    for (var cat in catalog) {
      if (currentCategory !== 'all' && currentCategory !== cat) continue;
      
      var list = catalog[cat] || [];
      list.forEach(function (item) {
        var isTool = item.type === 'tool';
        var owned = isTool && ownedTools[item.id] === true;
        var btnText = owned ? 'Owned' : 'Buy';
        var disabled = false;

        if (owned) {
          disabled = true;
        } else if (isTool && !hasHouse) {
          disabled = true;
          btnText = 'House Required';
        } else if (balance < item.price) {
          disabled = true;
          btnText = 'No Cash';
        }

        var metaText = '';
        if (isTool) {
          metaText = 'Workshop Equipment';
        } else if (item.type === 'consumable') {
          var qty = consumables[item.id] || 0;
          metaText = 'Qty in stock: ' + qty;
        } else {
          metaText = 'Installable Tuning Part';
        }

        itemsHtml.push([
          '<div class="sc-item-card">',
          '  <div class="sc-item-info">',
          '    <span class="sc-item-name">' + item.name + '</span>',
          '    <span class="sc-item-meta">' + metaText + '</span>',
          '    <span class="sc-item-price">' + money(item.price) + '</span>',
          '  </div>',
          '  <button class="sc-buy-btn" data-cat="' + cat + '" data-id="' + item.id + '" ' + (disabled ? 'disabled' : '') + '>' + btnText + '</button>',
          '</div>'
        ].join(''));
      });
    }

    var html = [
      '<div class="sc-container">',
      '  <div class="sc-header-row">',
      '    <span style="font-size:12px;color:rgba(255,255,255,0.6);">Available Cash:</span>',
      '    <span class="sc-balance">' + money(balance) + '</span>',
      '  </div>',
      '  <div class="sc-cats">' + catHtml + '</div>',
      '  <div class="sc-items">' + (itemsHtml.join('\n') || '<div style="text-align:center;padding:20px;color:rgba(255,255,255,0.4);font-size:12px;">No items found</div>') + '</div>',
      '</div>'
    ].join('\n');

    content.innerHTML = css + html;

    // Category click listeners
    var cats = document.querySelectorAll('.sc-cat');
    cats.forEach(function (el) {
      el.addEventListener('click', function () {
        currentCategory = el.getAttribute('data-cat');
        renderSupercheap(data);
      });
    });

    // Buy button listeners
    var buyBtns = document.querySelectorAll('.sc-buy-btn');
    buyBtns.forEach(function (el) {
      el.addEventListener('click', function () {
        var cat = el.getAttribute('data-cat');
        var itemId = el.getAttribute('data-id');

        SK.nui.post('phone:supercheap:buyItem', { category: cat, itemId: itemId }).done(function (result) {
          if (result && result.ok) {
            SK.nui.post('phone:supercheap:getState').done(function (updatedData) {
              renderSupercheap(updatedData);
            });
          }
        });
      });
    });
  }

  // Inject place/edit buttons inside Mechanic App for house owners
  function injectMechanicToolControls(data) {
    var content = document.getElementById('phoneMechanicContent');
    if (!content || !data || !data.hasHouse) return;

    var tools = data.placedTools || [];
    var ownedTools = data.ownedTools || {};

    // Get list of tools that are owned but not currently placed
    var toolsHtml = [];
    var toolCatalog = [
      { id: 'mech_tool_workbench', name: 'Backyard Workbench', label: 'workbench' },
      { id: 'mech_tool_lift', name: 'Hydraulic Car Lift', label: 'lift' },
      { id: 'mech_tool_dyno', name: 'Compact Dyno Roller', label: 'dyno' },
      { id: 'mech_tool_psi_station', name: 'PSI Calibration Panel', label: 'psi' },
      { id: 'mech_tool_alignment', name: 'Wheel Alignment Rig', label: 'alignment' },
      { id: 'mech_tool_turbo_bay', name: 'Turbo Calibration Desk', label: 'turbo' },
      { id: 'mech_tool_service_bay', name: 'Mechanic Service Lift', label: 'service' }
    ];

    toolCatalog.forEach(function (tc) {
      if (ownedTools[tc.id]) {
        // Check if placed
        var placement = tools.find(function (t) { return t.type === tc.label; });
        var placeBtn = '';
        var status = 'Stored';

        if (placement) {
          status = 'Placed (Moves: ' + (placement.moveCount || 0) + '/2)';
          placeBtn = [
            '<div style="display:flex;gap:4px;margin-top:4px;">',
            '  <button class="phone-event-action sc-tool-move" data-tool="' + tc.label + '" style="flex:1;font-size:10px;padding:4px;">Move</button>',
            '  <button class="phone-event-action phone-event-action-danger sc-tool-remove" data-tool="' + tc.label + '" style="flex:1;font-size:10px;padding:4px;background:#ff3b30;">Remove</button>',
            '</div>'
          ].join('');
        } else {
          placeBtn = '<button class="phone-event-action sc-tool-place" data-tool="' + tc.label + '" style="font-size:10px;padding:4px;width:100%;margin-top:4px;">Place Tool</button>';
        }

        toolsHtml.push([
          '<div style="background:rgba(255,255,255,0.02);border:1px solid rgba(255,255,255,0.06);border-radius:4px;padding:6px;margin-bottom:6px;font-size:11px;">',
          '  <div style="display:flex;justify-content:space-between;font-weight:bold;">',
          '    <span>' + tc.name + '</span>',
          '    <span style="color:#ffd200;">' + status + '</span>',
          '  </div>',
          '  ' + placeBtn,
          '</div>'
        ].join(''));
      }
    });

    var titleHtml = '<div class="phone-event-card" style="margin-top:10px;"><div class="phone-event-label">Workshop Equipment</div><div style="display:flex;flex-direction:column;gap:4px;margin-top:6px;">' + (toolsHtml.join('\n') || '<div style="color:rgba(255,255,255,0.3);text-align:center;">You do not own any workshop tools. Buy them at Supercheap Auto!</div>') + '</div></div>';
    
    // Append to Mechanic app content
    var div = document.createElement('div');
    div.innerHTML = titleHtml;
    content.appendChild(div);

    // Register placing event listeners
    document.querySelectorAll('.sc-tool-place').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var tool = btn.getAttribute('data-tool');
        SK.nui.post('phone:workshop:startPlacing', { tool: tool });
      });
    });

    document.querySelectorAll('.sc-tool-move').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var tool = btn.getAttribute('data-tool');
        SK.nui.post('phone:workshop:startPlacing', { tool: tool, move: true });
      });
    });

    document.querySelectorAll('.sc-tool-remove').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var tool = btn.getAttribute('data-tool');
        SK.nui.post('phone:workshop:removeTool', { tool: tool }).done(function (result) {
          if (result && result.ok) {
            // refresh
            SK.nui.post('phone:mechanic:getState').done(function (mechanicData) {
              renderMechanic(mechanicData);
              SK.nui.post('phone:supercheap:getState').done(function (scData) {
                injectMechanicToolControls(scData);
              });
            });
          }
        });
      });
    });
  }

  function injectMechanicPerks(data) {
    var content = document.getElementById('phoneMechanicContent');
    if (!content || !data) return;

    var perks = data.perks || {};
    var perkPoints = data.perkPoints || 0;
    
    var perkCatalog = [
      { id: 'instantFasten', name: 'Instant Fasten', desc: 'Install performance parts in 1 second instead of 8 seconds.' },
      { id: 'fineTune', name: 'Fine Tune', desc: 'Allows wider stance, camber, and turbo PSI tuning sliders.' },
      { id: 'cashedUp', name: 'Cashed Up', desc: '15% discount on performance parts and Supercheap Auto items.' },
      { id: 'seatTime', name: 'Seat Time', desc: 'Earn mechanic XP and cash automatically while driving vehicles.' }
    ];

    var perksHtml = perkCatalog.map(function (p) {
      var owned = perks[p.id] === true;
      var btnText = owned ? 'Unlocked' : 'Unlock (1 Pt)';
      var disabled = owned || perkPoints < 1;
      
      return [
        '<div style="background:rgba(255,255,255,0.02);border:1px solid rgba(255,255,255,0.06);border-radius:4px;padding:8px;margin-bottom:6px;font-size:11px;display:flex;justify-content:space-between;align-items:center;">',
        '  <div style="display:flex;flex-direction:column;gap:2px;max-width:70%;">',
        '    <span style="font-weight:bold;font-size:12px;color:#ffd200;">' + p.name + '</span>',
        '    <span style="color:rgba(255,255,255,0.5);font-size:10px;">' + p.desc + '</span>',
        '  </div>',
        '  <button class="phone-event-action sc-perk-unlock" data-perk="' + p.id + '" ' + (disabled ? 'disabled' : '') + ' style="font-size:10px;padding:4px 8px;">' + btnText + '</button>',
        '</div>'
      ].join('\n');
    }).join('\n');

    var perksPanelHtml = [
      '<div class="phone-event-card" style="margin-top:10px;">',
      '  <div class="phone-event-label" style="display:flex;justify-content:space-between;align-items:center;width:100%;">',
      '    <span>Mechanic Skill Tree</span>',
      '    <span style="color:#ffd200;font-weight:bold;">Points: ' + perkPoints + '</span>',
      '  </div>',
      '  <div style="display:flex;flex-direction:column;gap:4px;margin-top:6px;">' + perksHtml + '</div>',
      '</div>'
    ].join('\n');

    var div = document.createElement('div');
    div.innerHTML = perksPanelHtml;
    content.appendChild(div);

    document.querySelectorAll('.sc-perk-unlock').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var perk = btn.getAttribute('data-perk');
        SK.nui.post('phone:mechanic:unlockPerk', { perk: perk }).done(function (result) {
          if (result && result.ok) {
            SK.nui.post('phone:mechanic:getState').done(function (updatedData) {
              renderMechanic(updatedData);
            });
          }
        });
      });
    });
  }

  function injectMechanicEscrow(data) {
    var content = document.getElementById('phoneMechanicContent');
    if (!content || !data) return;

    SK.nui.post('phone:mechanic:getEscrowJobs').done(function (res) {
      if (!res || !res.ok) return;

      var onlinePlayers = res.players || [];
      var jobs = res.jobs || [];
      var myId = res.myId;

      var playerOptions = onlinePlayers.map(function (p) {
        return '<option value="' + p.id + '">[' + p.id + '] ' + p.name + '</option>';
      }).join('');

      var jobsHtml = jobs.map(function (j) {
        var isMechanic = j.mechanicId === myId;
        var roleLabel = isMechanic ? 'MECHANIC' : 'CUSTOMER';
        var statusLabel = j.status.toUpperCase();
        var actionBtn = '';

        if (j.status === 'pending') {
          if (isMechanic) {
            actionBtn = '<button class="phone-event-action sc-escrow-accept" data-id="' + j.id + '" style="font-size:10px;padding:2px 6px;">Accept</button>';
          } else {
            actionBtn = '<span style="color:rgba(255,255,255,0.4);font-size:10px;">Waiting for accept...</span>';
          }
        } else if (j.status === 'active') {
          if (isMechanic) {
            actionBtn = '<button class="phone-event-action sc-escrow-complete" data-id="' + j.id + '" style="font-size:10px;padding:2px 6px;background:#34c759;">Complete</button>';
          } else {
            actionBtn = '<span style="color:#ffd200;font-size:10px;">In Progress...</span>';
          }
        } else if (j.status === 'completed') {
          if (isMechanic) {
            actionBtn = '<span style="color:#34c759;font-size:10px;">Awaiting confirmation...</span>';
          } else {
            actionBtn = '<button class="phone-event-action sc-escrow-confirm" data-id="' + j.id + '" style="font-size:10px;padding:2px 6px;background:#34c759;">Confirm & Release</button>';
          }
        }

        var otherParty = isMechanic ? 'Client: [' + j.customerId + ']' : 'Mechanic: [' + j.mechanicId + ']';

        return [
          '<div style="background:rgba(255,255,255,0.02);border:1px solid rgba(255,255,255,0.06);border-radius:4px;padding:6px;margin-bottom:6px;font-size:11px;">',
          '  <div style="display:flex;justify-content:space-between;font-weight:bold;margin-bottom:4px;">',
          '    <span>' + j.description + '</span>',
          '    <span style="color:#34c759;">' + money(j.amount) + '</span>',
          '  </div>',
          '  <div style="display:flex;justify-content:space-between;color:rgba(255,255,255,0.5);font-size:10px;align-items:center;">',
          '    <span>' + otherParty + ' • ' + roleLabel + '</span>',
          '    <span>' + actionBtn + '</span>',
          '  </div>',
          '</div>'
        ].join('\n');
      }).join('\n') || '<div style="color:rgba(255,255,255,0.3);text-align:center;font-size:11px;">No active service escrow jobs</div>';

      var hireFormHtml = [
        '<div class="phone-event-card" style="margin-top:10px;">',
        '  <div class="phone-event-label">Hire a Mechanic (Escrow)</div>',
        '  <div style="display:flex;flex-direction:column;gap:6px;margin-top:6px;">',
        '    <div style="display:flex;flex-direction:column;gap:2px;">',
        '      <span style="font-size:10px;color:rgba(255,255,255,0.5);">Select Mechanic</span>',
        '      <select class="wh-input" id="scEscrowMechSelect">' + playerOptions + '</select>',
        '    </div>',
        '    <div style="display:flex;flex-direction:column;gap:2px;">',
        '      <span style="font-size:10px;color:rgba(255,255,255,0.5);">Job Details</span>',
        '      <input type="text" class="wh-input" id="scEscrowDesc" placeholder="e.g. Install Camber Kit" />',
        '    </div>',
        '    <div style="display:flex;flex-direction:column;gap:2px;">',
        '      <span style="font-size:10px;color:rgba(255,255,255,0.5);">Escrow Offer ($)</span>',
        '      <input type="number" class="wh-input" id="scEscrowAmount" placeholder="Amount" />',
        '    </div>',
        '    <button class="phone-event-action" id="scEscrowSendOffer" style="margin-top:4px;font-size:11px;padding:6px;">Send Escrow Offer</button>',
        '  </div>',
        '</div>',
        '<div class="phone-event-card" style="margin-top:10px;">',
        '  <div class="phone-event-label">Active Escrow Contracts</div>',
        '  <div style="display:flex;flex-direction:column;gap:4px;margin-top:6px;">' + jobsHtml + '</div>',
        '</div>'
      ].join('\n');

      var div = document.createElement('div');
      div.innerHTML = hireFormHtml;
      content.appendChild(div);

      // Hire Button Click
      document.getElementById('scEscrowSendOffer').addEventListener('click', function () {
        var mechId = parseInt(document.getElementById('scEscrowMechSelect').value);
        var desc = document.getElementById('scEscrowDesc').value;
        var amount = parseInt(document.getElementById('scEscrowAmount').value);

        if (!mechId || !desc || !amount) {
          alert('Please fill out all fields!');
          return;
        }

        SK.nui.post('phone:mechanic:createEscrowJob', {
          mechanicId: mechId,
          description: desc,
          amount: amount
        }).done(function (result) {
          if (result && result.ok) {
            SK.nui.post('phone:mechanic:getState').done(function (updatedData) {
              renderMechanic(updatedData);
            });
          } else {
            alert(result.reason || 'Failed to send escrow offer');
          }
        });
      });

      // Accept Click
      document.querySelectorAll('.sc-escrow-accept').forEach(function (btn) {
        btn.addEventListener('click', function () {
          var id = btn.getAttribute('data-id');
          SK.nui.post('phone:mechanic:acceptEscrowJob', { jobId: id }).done(function () {
            SK.nui.post('phone:mechanic:getState').done(function (updatedData) {
              renderMechanic(updatedData);
            });
          });
        });
      });

      // Complete Click
      document.querySelectorAll('.sc-escrow-complete').forEach(function (btn) {
        btn.addEventListener('click', function () {
          var id = btn.getAttribute('data-id');
          SK.nui.post('phone:mechanic:completeEscrowJob', { jobId: id }).done(function () {
            SK.nui.post('phone:mechanic:getState').done(function (updatedData) {
              renderMechanic(updatedData);
            });
          });
        });
      });

      // Confirm & Release Click
      document.querySelectorAll('.sc-escrow-confirm').forEach(function (btn) {
        btn.addEventListener('click', function () {
          var id = btn.getAttribute('data-id');
          SK.nui.post('phone:mechanic:confirmEscrowJob', { jobId: id }).done(function () {
            SK.nui.post('phone:mechanic:getState').done(function (updatedData) {
              renderMechanic(updatedData);
            });
          });
        });
      });
    });
  }

  // Intercept Mechanic state refresh to inject tool controls
  var origRenderMechanic = renderMechanic;
  renderMechanic = function (data) {
    origRenderMechanic(data);
    if (data && data.hasHouse) {
      SK.nui.post('phone:supercheap:getState').done(function (scData) {
        injectMechanicToolControls(scData);
      });
      injectMechanicPerks(data);
      injectMechanicEscrow(data);
    }
  };

  window.SKPhone.registerApp('Supercheap', function () {
    SK.nui.post('phone:supercheap:getState').done(function (data) {
      renderSupercheap(data);
    });
  });
})(window);
